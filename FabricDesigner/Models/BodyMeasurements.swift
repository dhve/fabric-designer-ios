import Foundation

public enum MeasurementSource: String, Codable, CaseIterable, Sendable {
    case manual
    case cameraEstimate
    case lidarEnhanced
    case demo

    public var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .cameraEstimate: return "Camera estimate"
        case .lidarEnhanced: return "LiDAR enhanced"
        case .demo: return "Demo"
        }
    }
}

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
    public var source: MeasurementSource

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
        confidence: Double = 0,
        source: MeasurementSource = .cameraEstimate
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
        self.source = source
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
        confidence: 0.0,
        source: .demo
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

    public var validationIssues: [String] {
        MeasurementRule.all.compactMap { rule in
            rule.contains(rule.value(in: self)) ? nil : rule.message
        }
    }

    public var isTailorReady: Bool { validationIssues.isEmpty }

    public func withSource(_ source: MeasurementSource, confidence: Double? = nil) -> BodyMeasurements {
        var copy = self
        copy.source = source
        copy.confidence = confidence ?? self.confidence
        copy.capturedAt = Date()
        return copy
    }
}

public struct MeasurementRule: Hashable {
    public var label: String
    public var keyPath: WritableKeyPath<BodyMeasurements, Double>
    public var range: ClosedRange<Double>

    public var message: String {
        "\(label) must be \(Int(range.lowerBound))-\(Int(range.upperBound)) cm"
    }

    public func value(in measurements: BodyMeasurements) -> Double {
        measurements[keyPath: keyPath]
    }

    public func contains(_ value: Double) -> Bool {
        range.contains(value)
    }

    public static let all: [MeasurementRule] = [
        MeasurementRule(label: "Height", keyPath: \.heightCM, range: 90...230),
        MeasurementRule(label: "Shoulder", keyPath: \.shoulderWidthCM, range: 25...80),
        MeasurementRule(label: "Sleeve", keyPath: \.sleeveLengthCM, range: 30...100),
        MeasurementRule(label: "Chest", keyPath: \.chestCircumferenceCM, range: 50...180),
        MeasurementRule(label: "Waist", keyPath: \.waistCircumferenceCM, range: 40...170),
        MeasurementRule(label: "Hip", keyPath: \.hipCircumferenceCM, range: 50...190),
        MeasurementRule(label: "Inseam", keyPath: \.inseamCM, range: 40...120),
        MeasurementRule(label: "Neck", keyPath: \.neckCircumferenceCM, range: 20...70),
        MeasurementRule(label: "Thigh", keyPath: \.thighCircumferenceCM, range: 25...100)
    ]
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
