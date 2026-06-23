import Foundation
import SwiftData

// SwiftData persistence layer — one @Model per top-level domain entity.

@Model public final class WardrobeGarment {
    @Attribute(.unique) public var id: String
    public var name: String
    public var categoryRaw: String
    public var fabricRaw: String
    public var colorHex: String
    public var colorName: String
    public var size: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(from g: Garment) {
        self.id = g.id
        self.name = g.name
        self.categoryRaw = g.category.rawValue
        self.fabricRaw = g.fabricType.rawValue
        self.colorHex = g.colorHex
        self.colorName = g.colorName
        self.size = g.size
        self.tags = g.tags
        self.createdAt = g.createdAt
        self.updatedAt = g.updatedAt
    }

    public var asGarment: Garment {
        Garment(
            id: id,
            name: name,
            category: GarmentCategory(rawValue: categoryRaw) ?? .top,
            fabricType: FabricType(rawValue: fabricRaw) ?? .cotton,
            colorHex: colorHex,
            colorName: colorName,
            size: size,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model public final class SavedLookRecord {
    @Attribute(.unique) public var name: String
    /// JSON-encoded outfit so we don't need a second @Model relationship.
    public var outfitData: Data
    public var savedAt: Date

    public init(name: String, outfit: Outfit, savedAt: Date = Date()) {
        self.name = name
        self.outfitData = (try? JSONEncoder().encode(outfit)) ?? Data()
        self.savedAt = savedAt
    }

    public var asLook: SavedLook? {
        guard let outfit = try? JSONDecoder().decode(Outfit.self, from: outfitData) else { return nil }
        return SavedLook(name: name, outfit: outfit, savedAt: savedAt)
    }
}

@Model public final class StoredMeasurements {
    public var capturedAt: Date
    public var heightCM: Double
    public var shoulderWidthCM: Double
    public var sleeveLengthCM: Double
    public var chestCircumferenceCM: Double
    public var waistCircumferenceCM: Double
    public var hipCircumferenceCM: Double
    public var inseamCM: Double
    public var neckCircumferenceCM: Double
    public var thighCircumferenceCM: Double
    public var confidence: Double
    public var sourceRaw: String?

    public init(from m: BodyMeasurements) {
        self.capturedAt = m.capturedAt
        self.heightCM = m.heightCM
        self.shoulderWidthCM = m.shoulderWidthCM
        self.sleeveLengthCM = m.sleeveLengthCM
        self.chestCircumferenceCM = m.chestCircumferenceCM
        self.waistCircumferenceCM = m.waistCircumferenceCM
        self.hipCircumferenceCM = m.hipCircumferenceCM
        self.inseamCM = m.inseamCM
        self.neckCircumferenceCM = m.neckCircumferenceCM
        self.thighCircumferenceCM = m.thighCircumferenceCM
        self.confidence = m.confidence
        self.sourceRaw = m.source.rawValue
    }

    public var asMeasurements: BodyMeasurements {
        BodyMeasurements(
            heightCM: heightCM,
            shoulderWidthCM: shoulderWidthCM,
            sleeveLengthCM: sleeveLengthCM,
            chestCircumferenceCM: chestCircumferenceCM,
            waistCircumferenceCM: waistCircumferenceCM,
            hipCircumferenceCM: hipCircumferenceCM,
            inseamCM: inseamCM,
            neckCircumferenceCM: neckCircumferenceCM,
            thighCircumferenceCM: thighCircumferenceCM,
            capturedAt: capturedAt,
            confidence: confidence,
            source: sourceRaw.flatMap(MeasurementSource.init(rawValue:)) ?? .cameraEstimate
        )
    }
}
