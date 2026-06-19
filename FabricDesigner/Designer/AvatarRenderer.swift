import SceneKit
import SwiftUI

/// SwiftUI wrapper around `SCNView` that renders an `AvatarScene` and
/// supports pinch + drag camera control.
public struct AvatarRenderer: UIViewRepresentable {
    public let scene: AvatarScene

    public func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene.scene
        view.pointOfView = scene.cameraNode
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.target = SCNVector3(0, 1.0, 0)
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isJitteringEnabled = true
        view.autoenablesDefaultLighting = false
        view.rendersContinuously = true
        return view
    }

    public func updateUIView(_ uiView: SCNView, context: Context) {
        // No-op — scene mutations happen via AvatarScene methods called
        // from the SwiftUI layer.
    }
}
