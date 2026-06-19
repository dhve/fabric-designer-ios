import SwiftUI

/// Pre-scan briefing — explains what's about to happen, requests the
/// camera permission gate, and lets the user bail out into Demo Mode if
/// LiDAR isn't available on their device.
public struct ScanIntroView: View {
    public var onBeginScan: () -> Void
    public var onUseDemo:   () -> Void

    public init(onBeginScan: @escaping () -> Void, onUseDemo: @escaping () -> Void) {
        self.onBeginScan = onBeginScan
        self.onUseDemo = onUseDemo
    }

    public var body: some View {
        ZStack {
            Theme.void.ignoresSafeArea()
            GridBackground(spacing: 32, color: Theme.violet.opacity(0.10))
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer().frame(height: 32)
                header
                Spacer().frame(height: 8)
                steps
                Spacer()
                actions
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MODULE · 01")
                .font(HUDFont.monoXS)
                .tracking(2.5)
                .foregroundStyle(Theme.violetGlow)
            Text("Body\nDimension\nCapture")
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(Theme.bone)
                .lineSpacing(-4)
            Text("Real-world measurements via iPhone LiDAR + body tracking. No tape measure required.")
                .font(HUDFont.body)
                .foregroundStyle(Theme.bone.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var steps: some View {
        VStack(spacing: 14) {
            stepRow(number: "01", title: "Stand 2 m back", detail: "Subject in t-shirt or fitted clothing")
            stepRow(number: "02", title: "Aim head to ankles", detail: "Phone held vertically, slow pan")
            stepRow(number: "03", title: "Hold for ~4 seconds", detail: "Mesh fills in; HUD locks onto joints")
            stepRow(number: "04", title: "Save dimensions", detail: "Auto-derives cm / in / size")
        }
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(HUDFont.monoLG)
                .foregroundStyle(Theme.violetGlow)
                .frame(width: 32, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(HUDFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.bone)
                Text(detail)
                    .font(HUDFont.monoXS)
                    .foregroundStyle(Theme.bone.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.carbon)
        .overlay(
            Rectangle().stroke(Theme.lineDark, lineWidth: 0.5)
        )
    }

    private var actions: some View {
        VStack(spacing: 12) {
            HUDButton("Begin Scan", icon: "viewfinder", style: .primary, action: onBeginScan)
            HUDButton("Use Demo Dimensions", icon: "wand.and.stars", style: .ghost, action: onUseDemo)
                .foregroundStyle(Theme.bone.opacity(0.85))
        }
    }
}
