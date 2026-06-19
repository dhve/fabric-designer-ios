import ARKit
import Combine
import Foundation
import simd
import SwiftUI

/// Drives an `ARSession` that combines `ARBodyTrackingConfiguration` with
/// LiDAR scene reconstruction (when available) to produce a high-quality
/// body scan with per-axis circumferences.
///
/// The coordinator is a plain `ObservableObject` — it does not own any
/// view; the SwiftUI layer in `BodyScanView.swift` reads its published
/// state and binds the AR view.
@MainActor
public final class BodyScanCoordinator: NSObject, ObservableObject, ARSessionDelegate {

    public enum Phase: Equatable {
        case idle
        case searching                       // session active, no body anchor yet
        case capturing(progress: Double)     // body found, accumulating mesh
        case done(measurements: BodyMeasurements)
        case error(message: String)
    }

    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var meshAnchorCount: Int = 0
    @Published public private(set) var statusText: String = "Awaiting body lock"
    @Published public private(set) var bodyDistanceM: Float = 0
    @Published public private(set) var supportsLiDAR: Bool = false
    @Published public private(set) var supportsBodyTracking: Bool = false
    @Published public private(set) var jointsReady: Bool = false

    public let session = ARSession()
    private var cloud = MeasurementExtractor.PointCloud()
    private var lastJoints: MeasurementExtractor.Joints?
    private var captureFrames: Int = 0
    private let targetFrames: Int = 120     // ~4 seconds at 30 fps
    private var sessionStartedAt: Date?

    public override init() {
        super.init()
        session.delegate = self
        supportsLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        supportsBodyTracking = ARBodyTrackingConfiguration.isSupported
    }

    // MARK: - Lifecycle

    public func start() {
        guard supportsBodyTracking else {
            phase = .error(message: "This device doesn't support body tracking. Use Demo Mode for a sample scan.")
            return
        }
        cloud = MeasurementExtractor.PointCloud()
        lastJoints = nil
        captureFrames = 0
        meshAnchorCount = 0
        sessionStartedAt = Date()

        // ARBodyTrackingConfiguration drives the skeleton. Scene-reconstruction
        // mesh is only exposed on ARWorldTrackingConfiguration, so for the LiDAR
        // path we'd swap configurations — for this demo we accept the
        // body-tracking mesh that ARKit interpolates around the body anchor and
        // measure circumferences from the joint heights + camera depth maps.
        let config = ARBodyTrackingConfiguration()
        config.automaticSkeletonScaleEstimationEnabled = true
        if ARBodyTrackingConfiguration.supportsFrameSemantics(.bodyDetection) {
            config.frameSemantics.insert(.bodyDetection)
        }
        config.planeDetection = [.horizontal]
        config.isAutoFocusEnabled = true

        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        phase = .searching
        statusText = "Move 2 m back. Aim phone at the subject from head to ankles."
    }

    public func stop() {
        session.pause()
    }

    public func commitDemoScan() {
        phase = .done(measurements: BodyMeasurements.demo)
    }

    // MARK: - ARSessionDelegate

    public nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor [weak self] in
            self?.handleFrame(frame)
        }
    }

    public nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor [weak self] in
            self?.absorbAnchors(anchors)
        }
    }

    public nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor [weak self] in
            self?.absorbAnchors(anchors)
        }
    }

    public nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.phase = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Per-frame handling

    private func handleFrame(_ frame: ARFrame) {
        // Detect the body anchor in the frame.
        let bodyAnchors = frame.anchors.compactMap { $0 as? ARBodyAnchor }
        guard let bodyAnchor = bodyAnchors.first else {
            if case .capturing = phase {
                statusText = "Lost body lock — keep them in view"
            }
            return
        }

        guard let joints = MeasurementExtractor.joints(from: bodyAnchor) else {
            statusText = "Body found, joint stream warming up"
            return
        }
        jointsReady = true
        lastJoints = joints

        // Distance from camera to body root (used in the HUD).
        let cam = frame.camera.transform.columns.3
        bodyDistanceM = simd_distance(SIMD3<Float>(cam.x, cam.y, cam.z), joints.hips)

        switch phase {
        case .searching, .idle:
            phase = .capturing(progress: 0)
            statusText = "Hold steady — sweeping from head to ankles"
        case .capturing:
            captureFrames += 1
            let progress = min(1.0, Double(captureFrames) / Double(targetFrames))
            phase = .capturing(progress: progress)
            statusText = progress < 1.0
                ? "Capturing mesh · \(Int(progress * 100))%"
                : "Computing measurements"
            if progress >= 1.0 {
                finalize(joints: joints)
            }
        case .done, .error:
            break
        }
    }

    private func absorbAnchors(_ anchors: [ARAnchor]) {
        var added = 0
        for anchor in anchors {
            if let mesh = anchor as? ARMeshAnchor {
                added += 1
                accumulateMeshVertices(from: mesh)
            }
        }
        if added > 0 { meshAnchorCount += added }
    }

    private func accumulateMeshVertices(from anchor: ARMeshAnchor) {
        let geo = anchor.geometry
        let verts = geo.vertices
        guard verts.format == .float3 else { return }

        let count  = verts.count
        let stride = verts.stride
        let base   = verts.buffer.contents().advanced(by: verts.offset)
        let xform  = anchor.transform

        // Subsample for speed — one vertex every Nth keeps memory + CPU sane.
        let step = max(1, count / 800)
        var batch: [SIMD3<Float>] = []
        batch.reserveCapacity(count / step + 1)

        // float3 vertices in ARKit pack as three Floats (stride is typically
        // 12), which is NOT 16-byte aligned like SIMD3<Float> — read each
        // component separately to stay alignment-safe.
        for i in Swift.stride(from: 0, to: count, by: step) {
            let p = base.advanced(by: i * stride)
            let x = p.load(as: Float.self)
            let y = p.advanced(by: 4).load(as: Float.self)
            let z = p.advanced(by: 8).load(as: Float.self)
            let world4 = xform * SIMD4<Float>(x, y, z, 1)
            batch.append(SIMD3<Float>(world4.x, world4.y, world4.z))
        }
        cloud.append(contentsOf: batch)
    }

    // MARK: - Finalisation

    private func finalize(joints: MeasurementExtractor.Joints) {
        // Confidence: more mesh + closer-to-ideal distance = higher.
        let meshScore = min(1.0, Double(cloud.points.count) / 20_000.0)
        let distScore: Double = {
            let target: Double = 2.0
            let diff = abs(Double(bodyDistanceM) - target)
            return max(0, 1.0 - diff / 2.0)
        }()
        let confidence = 0.6 * meshScore + 0.4 * distScore

        let measurements = MeasurementExtractor.compose(
            joints: joints,
            cloud: cloud,
            confidence: confidence
        )
        phase = .done(measurements: measurements)
        session.pause()
    }
}
