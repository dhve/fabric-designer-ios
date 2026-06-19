import Foundation

/// All 15 PBR fabrics supported by the designer, mirroring the React
/// Three Fiber `FabricType` union in the original Replit project.
///
/// Grouped into three rows in the swatch grid:
///   Row 0 — Dressy / Luxurious : silk, satin, velvet, chiffon, cashmere
///   Row 1 — Everyday           : cotton, linen, jersey, polyester, canvas
///   Row 2 — Structured / Rugged: denim, tweed, wool, leather, suede
public enum FabricType: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case silk, satin, velvet, chiffon, cashmere
    case cotton, linen, jersey, polyester, canvas
    case denim, tweed, wool, leather, suede

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// Stylistic register used by the outfit scorer.
    public enum Vibe: String, Sendable { case dressy, casual }

    public var vibe: Vibe {
        switch self {
        case .silk, .satin, .velvet, .chiffon, .cashmere,
             .linen, .tweed, .wool, .leather, .suede:
            return .dressy
        case .cotton, .denim, .jersey, .canvas, .polyester:
            return .casual
        }
    }
}

public enum GarmentCategory: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case top, bottom, shoes, outerwear, accessories

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .shoes: return "Shoes"
        case .outerwear: return "Outer"
        case .accessories: return "Accessory"
        }
    }

    public var shortLabel: String {
        switch self {
        case .top: return "TOP"
        case .bottom: return "BOT"
        case .shoes: return "SHO"
        case .outerwear: return "OUT"
        case .accessories: return "ACC"
        }
    }
}
