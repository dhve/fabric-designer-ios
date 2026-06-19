import Foundation
import SwiftUI

/// Catalog garment record — value type used everywhere except SwiftData
/// persistence, which mirrors this into a `@Model` class in
/// `Wardrobe/WardrobeModel.swift`.
public struct Garment: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    public var category: GarmentCategory
    public var fabricType: FabricType
    /// Hex string, e.g. "#b07baa".
    public var colorHex: String
    public var colorName: String
    public var size: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        category: GarmentCategory,
        fabricType: FabricType,
        colorHex: String,
        colorName: String,
        size: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.fabricType = fabricType
        self.colorHex = colorHex
        self.colorName = colorName
        self.size = size
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var swiftUIColor: Color { Color(hex: colorHex) ?? .gray }
}

public struct Outfit: Hashable, Codable, Sendable {
    public var items: [Garment]
    public init(items: [Garment] = []) { self.items = items }

    /// Stable fingerprint across category-order — used for like/dislike sets.
    public var key: String {
        items.map(\.id).sorted().joined(separator: "|")
    }

    public func item(in category: GarmentCategory) -> Garment? {
        items.first { $0.category == category }
    }
}

public struct SavedLook: Identifiable, Hashable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var outfit: Outfit
    public var savedAt: Date
    public init(name: String, outfit: Outfit, savedAt: Date = Date()) {
        self.name = name
        self.outfit = outfit
        self.savedAt = savedAt
    }
}
