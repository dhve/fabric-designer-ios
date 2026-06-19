import Foundation
import SwiftData
import SwiftUI

/// SwiftData-backed wardrobe store. Wraps a `ModelContainer` and exposes the
/// CRUD verbs the UI needs without leaking SwiftData types upwards.
///
/// Seeded with `Catalog.default` the first time the store is created — the
/// PRD's MVP requires that the first launch already has a usable wardrobe.
@MainActor
public final class WardrobeStore: ObservableObject {
    @Published public private(set) var garments: [Garment] = []
    @Published public private(set) var looks:    [SavedLook] = []
    @Published public private(set) var measurements: BodyMeasurements? = nil

    public let container: ModelContainer

    public init() {
        // Try persistent first, fall back to in-memory, fall back to a
        // minimal scratch container so the app still runs even if SwiftData
        // is completely unhappy (e.g. sandbox edge cases on simulators).
        let schema = Schema([WardrobeGarment.self, SavedLookRecord.self, StoredMeasurements.self])
        if let persistent = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
        ) {
            self.container = persistent
        } else if let memory = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) {
            self.container = memory
        } else {
            // Last resort — a fresh empty in-memory container with no
            // configurations argument. This is what SwiftData itself uses
            // as the default when no config is supplied.
            self.container = try! ModelContainer(for: schema)
        }
        refresh()
        if garments.isEmpty {
            seedDefaults()
        }
    }

    private var context: ModelContext { container.mainContext }

    public func refresh() {
        garments     = (try? context.fetch(FetchDescriptor<WardrobeGarment>()).map(\.asGarment)) ?? []
        looks        = (try? context.fetch(FetchDescriptor<SavedLookRecord>()).compactMap(\.asLook)) ?? []
        looks.sort { $0.savedAt > $1.savedAt }
        let stored   = try? context.fetch(FetchDescriptor<StoredMeasurements>(
            sortBy: [.init(\.capturedAt, order: .reverse)]
        ))
        measurements = stored?.first?.asMeasurements
    }

    private func seedDefaults() {
        for g in Catalog.default {
            context.insert(WardrobeGarment(from: g))
        }
        try? context.save()
        refresh()
    }

    // ── Garment CRUD ─────────────────────────────────────────────────
    public func add(_ garment: Garment) {
        var g = garment
        g.createdAt = Date()
        g.updatedAt = Date()
        context.insert(WardrobeGarment(from: g))
        try? context.save()
        refresh()
    }

    public func delete(garmentID: String) {
        let pred = #Predicate<WardrobeGarment> { $0.id == garmentID }
        if let matches = try? context.fetch(FetchDescriptor<WardrobeGarment>(predicate: pred)) {
            matches.forEach { context.delete($0) }
            try? context.save()
            refresh()
        }
    }

    // ── Saved looks ──────────────────────────────────────────────────
    public func saveLook(_ name: String, outfit: Outfit) {
        // Replace if a look with the same name already exists.
        let pred = #Predicate<SavedLookRecord> { $0.name == name }
        if let existing = try? context.fetch(FetchDescriptor<SavedLookRecord>(predicate: pred)) {
            existing.forEach { context.delete($0) }
        }
        context.insert(SavedLookRecord(name: name, outfit: outfit))
        try? context.save()
        refresh()
    }

    public func deleteLook(_ name: String) {
        let pred = #Predicate<SavedLookRecord> { $0.name == name }
        if let matches = try? context.fetch(FetchDescriptor<SavedLookRecord>(predicate: pred)) {
            matches.forEach { context.delete($0) }
            try? context.save()
            refresh()
        }
    }

    // ── Body measurements ────────────────────────────────────────────
    public func storeMeasurements(_ m: BodyMeasurements) {
        context.insert(StoredMeasurements(from: m))
        try? context.save()
        refresh()
    }
}
