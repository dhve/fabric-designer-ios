import SwiftUI

/// Top-level shell: shows the intro until the user starts a scan, then
/// hands them across the designer / photos / checkout pipeline.
public struct RootView: View {
    @EnvironmentObject private var app: AppState

    public var body: some View {
        ZStack {
            switch app.flow {
            case .intro:
                IntroView()
            case .scanning:
                BodyScanView(
                    onComplete: { m in
                        app.acceptMeasurements(m)
                        app.flow = .designer
                    },
                    onCancel: { app.flow = .designer }
                )
            case .checkout:
                NavigationStack { CheckoutView().navigationTitle("Checkout") }
            case .scanIntro, .designer, .wardrobe, .photos:
                designerTabs
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: app.flow)
    }

    private var designerTabs: some View {
        TabView(selection: tabBinding) {
            DesignerView()
                .tabItem { Label("Design", systemImage: "figure") }
                .tag(AppState.Flow.designer)
            WardrobeView()
                .tabItem { Label("Wardrobe", systemImage: "tshirt") }
                .tag(AppState.Flow.wardrobe)
            scanQuickAccess
                .tabItem { Label("Body Scan", systemImage: "viewfinder") }
                .tag(AppState.Flow.scanIntro)
            buyTab
                .tabItem { Label("Order", systemImage: "bag.fill") }
                .tag(AppState.Flow.photos)
        }
        .tint(Theme.violet)
    }

    private var tabBinding: Binding<AppState.Flow> {
        Binding(
            get: { app.flow },
            set: { app.flow = $0 }
        )
    }

    private var scanQuickAccess: some View {
        ScanIntroView(
            onBeginScan: { app.flow = .scanning },
            onUseDemo: {
                app.acceptMeasurements(.demo)
                app.flow = .designer
            }
        )
    }

    private var buyTab: some View {
        PhotoCaptureView()
    }
}

/// First-launch intro card — explains the four modules in one screen.
public struct IntroView: View {
    @EnvironmentObject private var app: AppState

    public var body: some View {
        ZStack {
            Theme.void.ignoresSafeArea()
            GridBackground(spacing: 32, color: Theme.violet.opacity(0.12))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ATELIER · v0.1")
                        .font(HUDFont.monoXS).tracking(3)
                        .foregroundStyle(Theme.violetGlow)
                    Text("Build\nA Setup.")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(Theme.bone)
                        .lineSpacing(-6)
                    Text("Design, measure, and order one outfit. Streetwear combat for designers, boutiques, and individuals fighting fast fashion.")
                        .font(HUDFont.body)
                        .foregroundStyle(Theme.bone.opacity(0.7))
                        .lineLimit(nil)
                }
                Spacer().frame(height: 8)
                moduleRow("01", "Scan",     "iPhone LiDAR body scan → exact dimensions")
                moduleRow("02", "Design",   "3D avatar, 15 PBR fabrics, Surprise Me")
                moduleRow("03", "Photos",   "5 reference photos + fit notes")
                moduleRow("04", "Checkout", "Cash · crypto · gold · electronic transfer")
                Spacer()
                HUDButton("Begin", icon: "play.fill", style: .primary) {
                    app.flow = .scanIntro
                }
                HUDButton("Skip scan — use demo dimensions", style: .ghost) {
                    app.acceptMeasurements(.demo)
                    app.flow = .designer
                }
                .foregroundStyle(Theme.bone.opacity(0.85))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }

    private func moduleRow(_ num: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(num)
                .font(HUDFont.monoLG)
                .foregroundStyle(Theme.violetGlow)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(HUDFont.label).tracking(1.2)
                    .foregroundStyle(Theme.bone)
                Text(detail)
                    .font(HUDFont.monoXS)
                    .foregroundStyle(Theme.bone.opacity(0.6))
            }
            Spacer()
        }
    }
}
