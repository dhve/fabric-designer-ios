import SwiftUI

/// Side-by-side comparison of two outfits on the same body. Mirrors the
/// React `BeforeAfterSlider` — a draggable handle reveals the right outfit
/// over the left.
public struct BeforeAfterView: View {
    public let before: Outfit
    public let after:  Outfit
    public let measurements: BodyMeasurements?
    @State private var splitFraction: Double = 0.5
    @StateObject private var beforeScene: SceneHolder
    @StateObject private var afterScene:  SceneHolder

    public init(before: Outfit, after: Outfit, measurements: BodyMeasurements?) {
        self.before = before
        self.after  = after
        self.measurements = measurements
        _beforeScene = StateObject(wrappedValue: SceneHolder(measurements: measurements))
        _afterScene  = StateObject(wrappedValue: SceneHolder(measurements: measurements))
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                AvatarRenderer(scene: afterScene.scene)
                AvatarRenderer(scene: beforeScene.scene)
                    .frame(width: geo.size.width * splitFraction)
                    .clipped()
                divider(in: geo)
                labels(in: geo)
            }
            .onAppear {
                beforeScene.scene.update(outfit: before)
                afterScene.scene.update(outfit: after)
            }
        }
        .background(Theme.void)
    }

    @ViewBuilder
    private func divider(in geo: GeometryProxy) -> some View {
        let x = geo.size.width * splitFraction
        ZStack {
            Rectangle()
                .fill(Theme.violetGlow)
                .frame(width: 1)
                .position(x: x, y: geo.size.height / 2)
            Circle()
                .fill(Theme.bone)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.onyx)
                )
                .position(x: x, y: geo.size.height / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let f = Double(value.location.x / geo.size.width)
                            splitFraction = min(max(f, 0.05), 0.95)
                        }
                )
        }
    }

    private func labels(in geo: GeometryProxy) -> some View {
        HStack {
            StatusPill("BEFORE", color: Theme.bone, icon: "clock.arrow.circlepath")
            Spacer()
            StatusPill("AFTER",  color: Theme.violetGlow, icon: "sparkles")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(width: geo.size.width, alignment: .top)
    }

    @MainActor
    final class SceneHolder: ObservableObject {
        let scene: AvatarScene
        init(measurements: BodyMeasurements?) {
            self.scene = AvatarScene(measurements: measurements)
        }
    }
}
