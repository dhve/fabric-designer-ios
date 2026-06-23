import ARKit
import SceneKit
import SwiftUI
import UIKit

/// SwiftUI host for the LiDAR body scan. Owns the `BodyScanCoordinator`
/// and overlays the cyberpunk capture HUD on top of the ARView.
public struct BodyScanView: View {
    @StateObject private var coordinator = BodyScanCoordinator()
    public var onComplete: (BodyMeasurements) -> Void
    public var onCancel:   () -> Void
    @State private var unit: LengthUnit = .cm
    @State private var manualPrefill: BodyMeasurements?
    @State private var showManualMeasurements = false

    public init(
        onComplete: @escaping (BodyMeasurements) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            BodyScanARRepresentable(session: coordinator.session)
                .ignoresSafeArea()
                .background(Color.black)

            // Bracket framing + scanlines over the AR feed.
            VStack {
                topHUD
                Spacer()
                bottomHUD
            }
            .padding()

            if case .done(let measurements) = coordinator.phase {
                ScanResultsView(
                    measurements: measurements,
                    unit: $unit,
                    onAccept: { onComplete(scanAccepted(measurements)) },
                    onManual: {
                        manualPrefill = measurements
                        showManualMeasurements = true
                    },
                    onRescan: { coordinator.start() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if case .error(let message) = coordinator.phase {
                errorOverlay(message: message)
            }
        }
        .onAppear { coordinator.start() }
        .onDisappear { coordinator.stop() }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showManualMeasurements) {
            ManualMeasurementView(prefill: manualPrefill) { measurements in
                showManualMeasurements = false
                onComplete(measurements)
            } onCancel: {
                showManualMeasurements = false
            }
        }
    }

    // MARK: - HUD pieces

    private var topHUD: some View {
        HStack(alignment: .top) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .padding(10)
                    .foregroundStyle(Theme.bone)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusPill("LiDAR \(coordinator.supportsLiDAR ? "OK" : "OFF")",
                           color: coordinator.supportsLiDAR ? Theme.emerald : Theme.warning,
                           icon: "dot.radiowaves.left.and.right")
                StatusPill("BODY \(coordinator.jointsReady ? "LOCKED" : "SEEK")",
                           color: coordinator.jointsReady ? Theme.violetGlow : Theme.warning,
                           icon: "figure.stand")
                StatusPill("RANGE \(String(format: "%.1fm", coordinator.bodyDistanceM))",
                           color: Theme.bone,
                           icon: "arrow.left.and.right")
                StatusPill("MESH \(coordinator.meshAnchorCount)",
                           color: Theme.bone,
                           icon: "grid")
            }
        }
    }

    private var bottomHUD: some View {
        VStack(spacing: 16) {
            // Status line.
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(coordinator.statusText.uppercased())
                    .font(HUDFont.mono)
                    .tracking(1.4)
                    .foregroundStyle(Theme.bone)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .stroke(Theme.violetGlow.opacity(0.6), lineWidth: 0.5)
            )

            // Progress meter + actions.
            HStack(spacing: 10) {
                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)
                    .tint(Theme.violetGlow)
                    .frame(maxWidth: .infinity)
                HUDButton("Demo Scan", icon: "wand.and.stars", style: .ghost) {
                    coordinator.commitDemoScan()
                }
                .frame(width: 130)
            }
        }
    }

    private var statusColor: Color {
        switch coordinator.phase {
        case .idle, .searching: return Theme.warning
        case .capturing:        return Theme.violetGlow
        case .done:             return Theme.emerald
        case .error:            return Theme.danger
        }
    }

    private var progressValue: Double {
        switch coordinator.phase {
        case .capturing(let p): return p
        case .done:             return 1
        default:                return 0
        }
    }

    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Text("SCAN FAILED")
                .font(HUDFont.displayCondensed)
                .foregroundStyle(Theme.bone)
            Text(message)
                .font(HUDFont.body)
                .foregroundStyle(Theme.bone.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            HStack(spacing: 12) {
                HUDButton("Cancel", style: .ghost, action: onCancel)
                    .foregroundStyle(Theme.bone)
                HUDButton("Enter Manually", icon: "ruler", style: .secondary) {
                    manualPrefill = nil
                    showManualMeasurements = true
                }
                HUDButton("Demo Scan", icon: "wand.and.stars", style: .primary) {
                    coordinator.commitDemoScan()
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func scanAccepted(_ measurements: BodyMeasurements) -> BodyMeasurements {
        let source: MeasurementSource = coordinator.supportsLiDAR ? .lidarEnhanced : .cameraEstimate
        return measurements.withSource(source)
    }
}

// MARK: - ARView UIKit bridge

public struct BodyScanARRepresentable: UIViewRepresentable {
    public let session: ARSession

    public func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.automaticallyUpdatesLighting = true
        view.preferredFramesPerSecond = 30
        view.backgroundColor = .black
        view.debugOptions = []
        view.rendersContinuously = true
        return view
    }

    public func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
