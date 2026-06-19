import Foundation
import SceneKit
import UIKit

/// Procedural humanoid built from primitives so the demo doesn't need to
/// bundle a heavyweight GLB. Each body region is exposed as a named node so
/// `GarmentMesh` can build inflated overlays around it.
public final class AvatarMesh {
    public let root: SCNNode
    public let head:     SCNNode
    public let neck:     SCNNode
    public let torso:    SCNNode
    public let hipNode:  SCNNode
    public let leftLeg:  SCNNode
    public let rightLeg: SCNNode
    public let leftArm:  SCNNode
    public let rightArm: SCNNode
    public let leftFoot: SCNNode
    public let rightFoot: SCNNode

    public init(measurements: BodyMeasurements? = nil) {
        let m = measurements ?? BodyMeasurements.demo

        // Scale: 1 SceneKit unit == 1 metre.
        let totalHeight: Float = Float(m.heightCM / 100.0)
        let shoulderW:   Float = Float(m.shoulderWidthCM / 100.0)
        let chestC:      Float = Float(m.chestCircumferenceCM / 100.0)
        let waistC:      Float = Float(m.waistCircumferenceCM / 100.0)
        let hipC:        Float = Float(m.hipCircumferenceCM / 100.0)
        let inseam:      Float = Float(m.inseamCM / 100.0)
        let sleeve:      Float = Float(m.sleeveLengthCM / 100.0)

        let twoPi: Float = 2 * Float.pi
        let chestRadius: Float = max(0.13, chestC / twoPi)
        let waistRadius: Float = max(0.11, waistC / twoPi)
        let hipRadius:   Float = max(0.13, hipC   / twoPi)
        let limbRadius:  Float = max(0.05, chestRadius * 0.30)
        let footHeight:  Float = 0.05

        root = SCNNode()
        root.name = "avatarRoot"

        // ── Torso (chest → waist) ────────────────────────────────────
        let torsoHeight: Float = totalHeight - inseam - footHeight - 0.25  // 0.25 ≈ head + neck
        let torsoCylinder = SCNCapsule(capRadius: CGFloat(chestRadius), height: CGFloat(torsoHeight))
        torsoCylinder.radialSegmentCount = 32
        torso = SCNNode(geometry: torsoCylinder)
        torso.name = "torso"
        // Place torso so its midpoint sits between hips and shoulders.
        let torsoBottomY: Float = footHeight + inseam
        torso.position = SCNVector3(0, torsoBottomY + torsoHeight / 2, 0)
        root.addChildNode(torso)

        // ── Hips (slightly wider band) ───────────────────────────────
        hipNode = SCNNode(geometry: SCNSphere(radius: CGFloat(hipRadius)))
        hipNode.name = "hips"
        (hipNode.geometry as? SCNSphere)?.segmentCount = 32
        hipNode.scale = SCNVector3(1.0, 0.6, 0.85)
        hipNode.position = SCNVector3(0, torsoBottomY + 0.04, 0)
        root.addChildNode(hipNode)

        // ── Waist accent (used for outerwear overlap) ────────────────
        let waistAccent = SCNNode(geometry: SCNTorus(ringRadius: CGFloat(waistRadius), pipeRadius: 0.005))
        waistAccent.name = "waistAccent"
        waistAccent.position = SCNVector3(0, torsoBottomY + torsoHeight * 0.45, 0)
        waistAccent.opacity = 0
        root.addChildNode(waistAccent)

        // ── Head + neck ──────────────────────────────────────────────
        let headRadius: Float = 0.10
        head = SCNNode(geometry: SCNSphere(radius: CGFloat(headRadius)))
        head.name = "head"
        (head.geometry as? SCNSphere)?.segmentCount = 32
        let topOfTorso: Float = torsoBottomY + torsoHeight
        head.position = SCNVector3(0, topOfTorso + 0.18, 0)
        root.addChildNode(head)

        neck = SCNNode(geometry: SCNCylinder(radius: 0.04, height: 0.07))
        neck.name = "neck"
        neck.position = SCNVector3(0, topOfTorso + 0.04, 0)
        root.addChildNode(neck)

        // ── Arms ─────────────────────────────────────────────────────
        let armLength: Float = max(0.50, sleeve)
        leftArm  = AvatarMesh.makeLimb(radius: limbRadius, length: armLength)
        leftArm.name = "leftArm"
        leftArm.position = SCNVector3(-(shoulderW / 2 + limbRadius * 0.8),
                                      topOfTorso - armLength / 2 - 0.02, 0)
        leftArm.eulerAngles = SCNVector3(0, 0, 0.18)
        root.addChildNode(leftArm)

        rightArm = AvatarMesh.makeLimb(radius: limbRadius, length: armLength)
        rightArm.name = "rightArm"
        rightArm.position = SCNVector3( (shoulderW / 2 + limbRadius * 0.8),
                                       topOfTorso - armLength / 2 - 0.02, 0)
        rightArm.eulerAngles = SCNVector3(0, 0, -0.18)
        root.addChildNode(rightArm)

        // ── Legs ─────────────────────────────────────────────────────
        let legRadius: Float = limbRadius * 1.4
        leftLeg  = AvatarMesh.makeLimb(radius: legRadius, length: inseam)
        leftLeg.name = "leftLeg"
        leftLeg.position = SCNVector3(-0.10, footHeight + inseam / 2, 0)
        root.addChildNode(leftLeg)

        rightLeg = AvatarMesh.makeLimb(radius: legRadius, length: inseam)
        rightLeg.name = "rightLeg"
        rightLeg.position = SCNVector3( 0.10, footHeight + inseam / 2, 0)
        root.addChildNode(rightLeg)

        // ── Feet ─────────────────────────────────────────────────────
        leftFoot  = SCNNode(geometry: SCNBox(width: 0.10, height: CGFloat(footHeight), length: 0.22, chamferRadius: 0.02))
        leftFoot.name = "leftFoot"
        leftFoot.position = SCNVector3(-0.10, footHeight / 2, 0.04)
        root.addChildNode(leftFoot)

        rightFoot = SCNNode(geometry: SCNBox(width: 0.10, height: CGFloat(footHeight), length: 0.22, chamferRadius: 0.02))
        rightFoot.name = "rightFoot"
        rightFoot.position = SCNVector3( 0.10, footHeight / 2, 0.04)
        root.addChildNode(rightFoot)

        // ── Skin material on every primitive ─────────────────────────
        let skin = AvatarMesh.skinMaterial()
        root.childNodes.forEach { $0.geometry?.firstMaterial = skin }
        _ = waistRadius
    }

    private static func makeLimb(radius: Float, length: Float) -> SCNNode {
        let geo = SCNCapsule(capRadius: CGFloat(radius), height: CGFloat(length))
        geo.radialSegmentCount = 24
        return SCNNode(geometry: geo)
    }

    private static func skinMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents  = UIColor(red: 0.90, green: 0.88, blue: 0.86, alpha: 1.0)
        m.roughness.contents = 0.85
        m.metalness.contents = 0.0
        m.locksAmbientWithDiffuse = true
        return m
    }
}

