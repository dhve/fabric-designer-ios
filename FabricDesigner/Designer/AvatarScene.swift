import SceneKit
import UIKit

/// Composes a complete `SCNScene` for the outfit designer: lighting,
/// background, the procedural avatar, and per-category garment overlays
/// that swap their material whenever the outfit changes.
@MainActor
public final class AvatarScene {
    public let scene = SCNScene()
    public let avatar: AvatarMesh
    public let cameraNode = SCNNode()

    /// Map each category to its overlay node so we can toggle visibility and
    /// swap materials without rebuilding the geometry.
    private var overlays: [GarmentCategory: SCNNode] = [:]
    private var currentOutfit = Outfit()

    public init(measurements: BodyMeasurements? = nil) {
        self.avatar = AvatarMesh(measurements: measurements)
        scene.rootNode.addChildNode(avatar.root)
        configureCamera()
        configureLighting()
        configureBackground()
        buildOverlays()
    }

    // MARK: - Camera

    private func configureCamera() {
        let cam = SCNCamera()
        cam.fieldOfView = 35
        cam.zNear = 0.05
        cam.zFar  = 30
        cameraNode.camera = cam
        cameraNode.position = SCNVector3(0, 1.0, 3.0)
        cameraNode.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(cameraNode)
    }

    // MARK: - Lighting (3-point + rim)

    private func configureLighting() {
        // Key
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.light?.color = UIColor(white: 1.0, alpha: 1.0)
        key.eulerAngles = SCNVector3(-Float.pi / 5, Float.pi / 6, 0)
        scene.rootNode.addChildNode(key)

        // Fill
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 350
        fill.light?.color = UIColor(red: 0.85, green: 0.85, blue: 1.0, alpha: 1.0)
        fill.eulerAngles = SCNVector3(-Float.pi / 8, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fill)

        // Rim — violet streetwear-combat highlight from behind.
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 600
        rim.light?.color = UIColor(red: 0.65, green: 0.45, blue: 1.0, alpha: 1.0)
        rim.eulerAngles = SCNVector3(0, Float.pi, 0)
        scene.rootNode.addChildNode(rim)

        // Ambient — keep shadows from going pitch black.
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 280
        ambient.light?.color = UIColor(white: 1.0, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)
    }

    // MARK: - Background

    private func configureBackground() {
        // Studio gradient — sterile white floor under a deep onyx upper.
        let grad = CAGradientLayer()
        grad.frame = CGRect(x: 0, y: 0, width: 512, height: 512)
        grad.colors = [
            UIColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1.0).cgColor,
            UIColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0).cgColor,
            UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0).cgColor,
        ]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        UIGraphicsBeginImageContext(grad.frame.size)
        if let ctx = UIGraphicsGetCurrentContext() {
            grad.render(in: ctx)
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        scene.background.contents = img

        // Studio environment so PBR materials get plausible reflections.
        scene.lightingEnvironment.contents = img
        scene.lightingEnvironment.intensity = 1.0
    }

    // MARK: - Overlays

    /// Build a hollow overlay per category that wraps the relevant body
    /// region. Hidden until a garment is applied; their material is what
    /// actually carries the fabric appearance.
    private func buildOverlays() {
        let m = avatar.head // any node works as a sizing reference
        _ = m

        // Top — torso overlay (slightly inflated capsule).
        let topGeo = SCNCapsule(capRadius: 0.21, height: 0.55)
        topGeo.radialSegmentCount = 32
        let topNode = SCNNode(geometry: topGeo)
        topNode.name = "overlay.top"
        topNode.position = avatar.torso.presentation.position + SCNVector3(0, 0.12, 0)
        topNode.scale = SCNVector3(1.06, 1.0, 0.95)
        topNode.isHidden = true
        scene.rootNode.addChildNode(topNode)
        overlays[.top] = topNode

        // Bottom — two stacked capsules around the legs.
        let bottomNode = SCNNode()
        bottomNode.name = "overlay.bottom"
        for (i, leg) in [avatar.leftLeg, avatar.rightLeg].enumerated() {
            let geo = SCNCapsule(capRadius: 0.12, height: 0.85)
            geo.radialSegmentCount = 24
            let n = SCNNode(geometry: geo)
            n.position = SCNVector3(i == 0 ? -0.10 : 0.10, leg.presentation.position.y, 0)
            bottomNode.addChildNode(n)
        }
        bottomNode.isHidden = true
        scene.rootNode.addChildNode(bottomNode)
        overlays[.bottom] = bottomNode

        // Shoes — two foot-shaped boxes.
        let shoesNode = SCNNode()
        shoesNode.name = "overlay.shoes"
        for foot in [avatar.leftFoot, avatar.rightFoot] {
            let geo = SCNBox(width: 0.13, height: 0.08, length: 0.27, chamferRadius: 0.03)
            let n = SCNNode(geometry: geo)
            n.position = foot.presentation.position
            n.position.y = 0.04
            shoesNode.addChildNode(n)
        }
        shoesNode.isHidden = true
        scene.rootNode.addChildNode(shoesNode)
        overlays[.shoes] = shoesNode

        // Outerwear — larger torso overlay reaching to mid-thigh.
        let outerGeo = SCNCapsule(capRadius: 0.27, height: 1.0)
        outerGeo.radialSegmentCount = 36
        let outerNode = SCNNode(geometry: outerGeo)
        outerNode.name = "overlay.outerwear"
        outerNode.position = avatar.torso.presentation.position + SCNVector3(0, -0.08, 0)
        outerNode.scale = SCNVector3(1.0, 1.0, 0.9)
        outerNode.opacity = 0.95
        outerNode.isHidden = true
        scene.rootNode.addChildNode(outerNode)
        overlays[.outerwear] = outerNode
    }

    // MARK: - Public API

    public func update(outfit: Outfit) {
        currentOutfit = outfit
        for cat in GarmentCategory.allCases {
            guard let node = overlays[cat] else { continue }
            if let item = outfit.item(in: cat) {
                node.isHidden = false
                let material = FabricMaterial.make(for: item.fabricType, colorHex: item.colorHex)
                applyMaterial(material, to: node)
            } else {
                node.isHidden = true
            }
        }
    }

    public func setPose(_ pose: AvatarPose) {
        // Soft idle bob/walk via SCNActions on the root node.
        avatar.root.removeAllActions()
        switch pose {
        case .standing:
            let breathe = SCNAction.sequence([
                .moveBy(x: 0, y: 0.005, z: 0, duration: 1.6),
                .moveBy(x: 0, y: -0.005, z: 0, duration: 1.6),
            ])
            avatar.root.runAction(.repeatForever(breathe))
        case .walking:
            let bob = SCNAction.sequence([
                .moveBy(x: 0, y: 0.02, z: 0, duration: 0.35),
                .moveBy(x: 0, y: -0.02, z: 0, duration: 0.35),
            ])
            let arms = SCNAction.sequence([
                .rotateBy(x: 0.20, y: 0, z: 0, duration: 0.35),
                .rotateBy(x: -0.20, y: 0, z: 0, duration: 0.35),
            ])
            avatar.root.runAction(.repeatForever(bob))
            avatar.leftArm.runAction(.repeatForever(arms))
            avatar.rightArm.runAction(.repeatForever(.sequence([
                .rotateBy(x: -0.20, y: 0, z: 0, duration: 0.35),
                .rotateBy(x:  0.20, y: 0, z: 0, duration: 0.35),
            ])))
        case .relaxed:
            avatar.root.eulerAngles.y = -0.18
            avatar.root.runAction(.repeatForever(.sequence([
                .moveBy(x: 0, y: 0.003, z: 0, duration: 2.4),
                .moveBy(x: 0, y: -0.003, z: 0, duration: 2.4),
            ])))
        }
    }

    private func applyMaterial(_ material: SCNMaterial, to node: SCNNode) {
        if let geo = node.geometry {
            geo.firstMaterial = material
        }
        for child in node.childNodes {
            child.geometry?.firstMaterial = material
        }
    }
}

public enum AvatarPose: String, CaseIterable, Sendable {
    case standing, walking, relaxed

    public var displayName: String {
        switch self {
        case .standing: return "Standing"
        case .walking: return "Walking"
        case .relaxed: return "Relaxed"
        }
    }
}

// SCNVector3 + Math helpers
public func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}
