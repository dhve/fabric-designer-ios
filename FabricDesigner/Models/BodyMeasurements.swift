import Foundation

/// Output of a LiDAR body scan. Every measurement is stored in centimetres;
/// `formatted(_:)` converts to inches when the user prefers imperial.
public struct BodyMeasurements: Codable, Hashable, Sendable {
    public var heightCM: Double
    public var shoulderWidthCM: Double
    public var sleeveLengthCM: Double
    public var chestCircumferenceCM: Double
    public var waistCircumferenceCM: Double
    public var hipCircumferenceCM: Double
    public var inseamCM: Double
    public var neckCircumferenceCM: Double
    public var thighCircumferenceCM: Double
    public var capturedAt: Date

    /// Confidence reported by the scanner — driven by the number of
    /// mesh anchors collected and how stable the body anchor stayed.
    public var confidence: Double

    public init(
        heightCM: Double,
        shoulderWidthCM: Double,
        sleeveLengthCM: Double,
        chestCircumferenceCM: Double,
        waistCircumferenceCM: Double,
        hipCircumferenceCM: Double,
        inseamCM: Double,
        neckCircumferenceCM: Double,
        thighCircumferenceCM: Double,
        capturedAt: Date = Date(),
        confidence: Double = 0
    ) {
        self.heightCM = heightCM
        self.shoulderWidthCM = shoulderWidthCM
        self.sleeveLengthCM = sleeveLengthCM
        self.chestCircumferenceCM = chestCircumferenceCM
        self.waistCircumferenceCM = waistCircumferenceCM
        self.hipCircumferenceCM = hipCircumferenceCM
        self.inseamCM = inseamCM
        self.neckCircumferenceCM = neckCircumferenceCM
        self.thighCircumferenceCM = thighCircumferenceCM
        self.capturedAt = capturedAt
        self.confidence = confidence
    }

    /// Average adult demo profile used as a baseline / simulator fallback.
    public static let demo = BodyMeasurements(
        heightCM: 178.0,
        shoulderWidthCM: 44.0,
        sleeveLengthCM: 63.5,
        chestCircumferenceCM: 98.0,
        waistCircumferenceCM: 81.0,
        hipCircumferenceCM: 96.0,
        inseamCM: 81.0,
        neckCircumferenceCM: 39.0,
        thighCircumferenceCM: 56.0,
        confidence: 0.0
    )

    /// Map circumferences onto a standard letter size for the wardrobe.
    /// Conservative — picks the larger end when two thresholds straddle.
    public var derivedSize: String {
        switch chestCircumferenceCM {
        case ..<86:   return "XS"
        case ..<92:   return "S"
        case ..<100:  return "M"
        case ..<108:  return "L"
        case ..<118:  return "XL"
        default:      return "XXL"
        }
    }
}

public enum LengthUnit: String, CaseIterable, Sendable {
    case cm, inches

    public var label: String { self == .cm ? "cm" : "in" }
}

public extension Double {
    func formatted(in unit: LengthUnit, precision: Int = 1) -> String {
        let value: Double = unit == .cm ? self : self / 2.54
        return String(format: "%.\(precision)f %@", value, unit.label)
    }
}
