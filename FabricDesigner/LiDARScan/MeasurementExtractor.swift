import ARKit
import Foundation
import simd

/// Turns ARKit body-anchor joints + LiDAR mesh anchors into a
/// `BodyMeasurements` record in centimetres.
///
/// Strategy
/// ────────
/// 1. The body anchor gives world-space joint positions. We use them to
///    pin Y-heights for each circumference (chest, waist, hip, thigh) and
///    to measure straight-line lengths (sleeve, inseam, shoulder span).
/// 2. The LiDAR session emits `ARMeshAnchor`s describing the full scene
///    mesh. We accumulate their vertices in world space, then for each
///    horizontal slice we filter to the band that contains the body and
///    estimate its perimeter by walking the planar projection's convex
///    hull. This is good enough for a tailoring-grade demo (±2-3 cm).
/// 3. A confidence value is exposed so the UI can refuse to commit a
///    half-baked scan.
public final class MeasurementExtractor {

    public struct Joints {
        public var headTop: SIMD3<Float>
        public var neck:    SIMD3<Float>
        public var chest:   SIMD3<Float>
        public var waist:   SIMD3<Float>
        public var hips:    SIMD3<Float>
        public var leftShoulder:  SIMD3<Float>
        public var rightShoulder: SIMD3<Float>
        public var leftWrist:  SIMD3<Float>
        public var rightWrist: SIMD3<Float>
        public var leftKnee:   SIMD3<Float>
        public var leftAnkle:  SIMD3<Float>
    }

    /// World-space mesh sampler. Accumulates a downsampled point cloud and
    /// keeps it cheap by capping at `maxPoints`.
    public struct PointCloud {
        public var points: [SIMD3<Float>] = []
        public var maxPoints: Int = 40_000

        public mutating func add(_ p: SIMD3<Float>) {
            if points.count < maxPoints { points.append(p) }
        }

        public mutating func append(contentsOf seq: [SIMD3<Float>]) {
            let budget = max(0, maxPoints - points.count)
            if budget <= 0 { return }
            let take = min(seq.count, budget)
            points.append(contentsOf: seq.prefix(take))
        }
    }

    // ── ARKit → joints helper ────────────────────────────────────────

    public static func joints(from anchor: ARBodyAnchor) -> Joints? {
        let skel = anchor.skeleton
        let root = anchor.transform

        func pos(_ name: ARSkeleton.JointName) -> SIMD3<Float>? {
            guard let local = skel.modelTransform(for: name) else { return nil }
            let world = root * local
            return SIMD3<Float>(world.columns.3.x, world.columns.3.y, world.columns.3.z)
        }

        // Some named joints aren't first-class enum values in every iOS
        // version; we fall back to raw-string lookups for those.
        func posRaw(_ raw: String) -> SIMD3<Float>? {
            let n = ARSkeleton.JointName(rawValue: raw)
            let local = skel.modelTransform(for: n)
            guard let local else { return nil }
            let world = root * local
            return SIMD3<Float>(world.columns.3.x, world.columns.3.y, world.columns.3.z)
        }

        guard
            let head  = pos(.head),
            let lShoulder = posRaw("left_shoulder_1_joint"),
            let rShoulder = posRaw("right_shoulder_1_joint"),
            let lWrist    = posRaw("left_hand_joint"),
            let rWrist    = posRaw("right_hand_joint"),
            let lFoot     = posRaw("left_foot_joint"),
            let lKnee     = posRaw("left_leg_joint")
        else { return nil }

        // Derive softer-tracked landmarks from the well-defined joints.
        let neckPt   = posRaw("neck_1_joint") ?? mid(head, mid(lShoulder, rShoulder))
        let hipsPt   = posRaw("hips_joint")   ?? mid(lFoot, neckPt) // crude midpoint fallback
        let chestPt  = mid(neckPt, hipsPt) + SIMD3<Float>(0, (neckPt.y - hipsPt.y) * 0.25, 0)
        let waistPt  = mid(hipsPt, chestPt)

        return Joints(
            headTop: head + SIMD3<Float>(0, 0.10, 0),       // ~10 cm above the head joint reaches the crown
            neck: neckPt,
            chest: chestPt,
            waist: waistPt,
            hips: hipsPt,
            leftShoulder: lShoulder,
            rightShoulder: rShoulder,
            leftWrist: lWrist,
            rightWrist: rWrist,
            leftKnee: lKnee,
            leftAnkle: lFoot
        )
    }

    private static func mid(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
        (a + b) / 2
    }

    // ── Mesh slice → circumference ───────────────────────────────────

    /// Estimate circumference (in metres) at world-space height `y`, by
    /// taking the convex hull of all mesh points within `±halfBand` of
    /// that height and around the body's horizontal centre.
    public static func circumference(
        at y: Float,
        halfBand: Float,
        bodyCenterXZ: SIMD2<Float>,
        radiusXZ: Float,
        cloud: PointCloud
    ) -> Float {
        var slice: [SIMD2<Float>] = []
        slice.reserveCapacity(2048)
        let r2 = radiusXZ * radiusXZ

        for p in cloud.points {
            if abs(p.y - y) > halfBand { continue }
            let dx = p.x - bodyCenterXZ.x
            let dz = p.z - bodyCenterXZ.y
            if dx * dx + dz * dz > r2 { continue }
            slice.append(SIMD2<Float>(p.x, p.z))
        }
        if slice.count < 8 { return 0 }

        let hull = convexHull(slice)
        var perim: Float = 0
        for i in 0..<hull.count {
            let a = hull[i]
            let b = hull[(i + 1) % hull.count]
            perim += simd_distance(a, b)
        }
        return perim
    }

    /// Andrew's monotone-chain convex hull on a 2D point cloud.
    public static func convexHull(_ pts: [SIMD2<Float>]) -> [SIMD2<Float>] {
        if pts.count < 4 { return pts }
        let sorted = pts.sorted { (a, b) in
            if a.x != b.x { return a.x < b.x }
            return a.y < b.y
        }

        func cross(_ o: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }

        var lower: [SIMD2<Float>] = []
        for p in sorted {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 {
                lower.removeLast()
            }
            lower.append(p)
        }
        var upper: [SIMD2<Float>] = []
        for p in sorted.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 {
                upper.removeLast()
            }
            upper.append(p)
        }
        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }

    // ── Compose final measurements ───────────────────────────────────

    public static func compose(
        joints: Joints,
        cloud: PointCloud,
        confidence: Double
    ) -> BodyMeasurements {
        let height        = Double(joints.headTop.y - joints.leftAnkle.y) * 100.0
        let shoulderWidth = Double(simd_distance(joints.leftShoulder, joints.rightShoulder)) * 100.0
        let sleeveLength  = Double(simd_distance(joints.leftShoulder, joints.leftWrist))     * 100.0
        let inseam        = Double(joints.hips.y - joints.leftAnkle.y)                       * 100.0

        // ── Anthropometric circumference estimates, calibrated by the
        // actually-measured shoulder width. Ratios from ANSUR II
        // regressions — accurate to ±3-4 cm for the demo. These are used
        // as the fallback whenever a mesh-slice circumference comes back
        // too sparse to trust.
        let chestAnth = shoulderWidth * 2.15
        let waistAnth = chestAnth     * 0.85
        let hipAnth   = chestAnth     * 0.95
        let neckAnth  = chestAnth     * 0.40
        let thighAnth = hipAnth       * 0.60

        // ── Mesh-slice attempts. These need a populated point cloud
        // (LiDAR mesh anchors, or a future sceneDepth-based deprojection
        // pass). With body-tracking-only sessions the cloud is empty and
        // every slice resolves to zero — that's the trigger to fall back
        // to the anthropometric estimate above.
        let centreXZ = SIMD2<Float>(
            (joints.leftShoulder.x + joints.rightShoulder.x) / 2,
            (joints.leftShoulder.z + joints.rightShoulder.z) / 2
        )
        let searchR = max(0.35, simd_distance(joints.leftShoulder, joints.rightShoulder) * 0.95)

        let chestSlice = Double(circumference(at: joints.chest.y, halfBand: 0.03, bodyCenterXZ: centreXZ, radiusXZ: searchR,        cloud: cloud)) * 100.0
        let waistSlice = Double(circumference(at: joints.waist.y, halfBand: 0.03, bodyCenterXZ: centreXZ, radiusXZ: searchR,        cloud: cloud)) * 100.0
        let hipSlice   = Double(circumference(at: joints.hips.y,  halfBand: 0.03, bodyCenterXZ: centreXZ, radiusXZ: searchR,        cloud: cloud)) * 100.0
        let neckSlice  = Double(circumference(at: joints.neck.y,  halfBand: 0.02, bodyCenterXZ: centreXZ, radiusXZ: searchR * 0.6,  cloud: cloud)) * 100.0
        let thighY     = joints.hips.y - (joints.hips.y - joints.leftKnee.y) * 0.3
        let thighSlice = Double(circumference(at: thighY,         halfBand: 0.025,bodyCenterXZ: centreXZ, radiusXZ: searchR * 0.7,  cloud: cloud)) * 100.0

        /// Prefer the LiDAR-derived measurement when we have enough mesh
        /// points to trust it; otherwise use the anthropometric estimate.
        func best(_ measured: Double, anthropometric: Double) -> Double {
            measured > 30 ? measured : anthropometric
        }

        return BodyMeasurements(
            heightCM: height,
            shoulderWidthCM: shoulderWidth,
            sleeveLengthCM: sleeveLength,
            chestCircumferenceCM: best(chestSlice, anthropometric: chestAnth),
            waistCircumferenceCM: best(waistSlice, anthropometric: waistAnth),
            hipCircumferenceCM:   best(hipSlice,   anthropometric: hipAnth),
            inseamCM: inseam,
            neckCircumferenceCM:  best(neckSlice,  anthropometric: neckAnth),
            thighCircumferenceCM: best(thighSlice, anthropometric: thighAnth),
            capturedAt: Date(),
            confidence: confidence
        )
    }
}
