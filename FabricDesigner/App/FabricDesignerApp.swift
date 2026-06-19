import SwiftData
import SwiftUI

@main
struct FabricDesignerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .modelContainer(appState.wardrobe.container)
        }
    }
}
