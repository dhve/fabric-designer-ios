import Foundation
import SwiftUI

/// Top-level observable state container. Owns:
///   • Wardrobe (SwiftData store)
///   • Outfit history / likes / dislikes
///   • The current outfit being edited
///   • The user's body measurements
///   • Photos + designer notes captured for the order
///   • Current flow position (intro → scan → design → photos → checkout)
@MainActor
public final class AppState: ObservableObject {

    public enum Flow: Hashable {
        case intro
        case scanIntro
        case scanning
        case designer
        case wardrobe
        case photos
        case checkout
    }

    @Published public var flow: Flow = .intro
    @Published public var currentOutfit: Outfit = Outfit()
    @Published public var measurements: BodyMeasurements? = nil
    @Published public var photos: [UIImage] = []
    @Published public var designerNotes: String = ""
    @Published public var lastOrder: Order? = nil

    public let wardrobe: WardrobeStore
    public let history:  HistoryStore

    public init(wardrobe: WardrobeStore? = nil, history: HistoryStore? = nil) {
        self.wardrobe = wardrobe ?? WardrobeStore()
        self.history  = history ?? HistoryStore()
        self.measurements = self.wardrobe.measurements

        // Seed with a default outfit so the avatar always has something on.
        let seed = Catalog.default
        if let top    = seed.first(where: { $0.category == .top }),
           let bottom = seed.first(where: { $0.category == .bottom }),
           let shoes  = seed.first(where: { $0.category == .shoes }) {
            currentOutfit = Outfit(items: [top, bottom, shoes])
        }
    }

    // MARK: - Outfit verbs

    public func applyItem(_ item: Garment) {
        currentOutfit = OutfitEngine.apply(item, to: currentOutfit)
    }

    public func removeItem(category: GarmentCategory) {
        currentOutfit = OutfitEngine.remove(category, from: currentOutfit)
    }

    public func applyFabric(_ fabric: FabricType, color: String, to category: GarmentCategory) {
        if let existing = currentOutfit.item(in: category) {
            var updated = existing
            updated.fabricType = fabric
            updated.colorHex = color
            currentOutfit = OutfitEngine.apply(updated, to: currentOutfit)
        } else {
            let base = Catalog.default.first { $0.category == category } ?? Catalog.default[0]
            let custom = Garment(
                id: "\(category.rawValue)-custom-\(UUID().uuidString.prefix(6))",
                name: "Custom \(category.displayName)",
                category: category,
                fabricType: fabric,
                colorHex: color,
                colorName: "Custom",
                size: measurements?.derivedSize ?? base.size
            )
            currentOutfit = OutfitEngine.apply(custom, to: currentOutfit)
        }
    }

    public func surpriseMe() {
        let wardrobePool = wardrobe.garments.isEmpty ? Catalog.default : wardrobe.garments
        let generated = OutfitEngine.generate(
            wardrobe: wardrobePool,
            history: history.history,
            likes: history.likes,
            dislikes: history.dislikes
        )
        history.recordGenerated(generated)
        currentOutfit = generated
    }

    public func like(_ outfit: Outfit) {
        history.like(outfit)
    }

    public func dislike(_ outfit: Outfit) {
        history.dislike(outfit)
        // Roll the dice on something new since the user disliked the current one.
        surpriseMe()
    }

    public func loadOutfit(_ outfit: Outfit) {
        currentOutfit = outfit
    }

    public func saveLook(name: String) {
        wardrobe.saveLook(name, outfit: currentOutfit)
    }

    // MARK: - Measurements

    public func acceptMeasurements(_ m: BodyMeasurements) {
        measurements = m
        wardrobe.storeMeasurements(m)
    }

    // MARK: - Flow

    public func resetFlow() {
        photos = []
        designerNotes = ""
        flow = .designer
    }
}
