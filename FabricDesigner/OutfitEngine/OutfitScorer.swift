import Foundation

/// Five-star outfit scoring, ported from `outfit/outfitScorer.ts`.
public struct OutfitScore: Hashable, Sendable {
    public var score: Double
    public var stars: Int          // 1...5
    public var label: String
    public var colorHarmony: Double
    public var fabricVibe: Double
    public var sizeConsistency: Double
}

public enum OutfitScorer {
    // Dimension weights — must sum to 1.0.
    private static let wColor  = 0.40
    private static let wFabric = 0.35
    private static let wSize   = 0.25

    private static let sizeGroups: [String: Int] = [
        "xxs": 0, "xs": 0,
        "s": 1,
        "m": 2,
        "l": 3,
        "xl": 4, "xxl": 4, "2xl": 4,
        "one size": 5, "os": 5
    ]

    private static func normSizeGroup(_ size: String?) -> Int? {
        guard let s = size?.lowercased().trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        if let g = sizeGroups[s] { return g }
        // Numeric sizes: extract first run of digits (e.g. "32x30" → 32, "us 9" → 9).
        guard let firstDigit = s.firstIndex(where: { $0.isNumber }) else { return nil }
        let run = s[firstDigit...].prefix(while: { $0.isNumber })
        return Int(run)
    }

    private static func sizeConsistencyScore(_ outfit: Outfit) -> Double {
        let groups = outfit.items.compactMap { normSizeGroup($0.size) }
        if groups.count < 2 { return 1.0 }
        let mn = groups.min()!
        let mx = groups.max()!
        return mn == mx ? 1.0 : 0.5
    }

    // ── Label rows ───────────────────────────────────────────────────
    private static let colorRows:  [(Double, String)] = [
        (0.85, "Perfect color harmony"),
        (0.65, "Good color balance"),
        (0.40, "Acceptable color mix"),
        (0.00, "Color clash risk"),
    ]
    private static let fabricRows: [(Double, String)] = [
        (0.85, "Great fabric harmony"),
        (0.55, "Mixed fabric vibes"),
        (0.00, "Fabric vibe mismatch"),
    ]
    private static let sizeRows:   [(Double, String)] = [
        (0.85, "Matched sizes"),
        (0.55, "Close sizes"),
        (0.00, "Size mismatch"),
    ]

    private static func pickLabel(_ rows: [(Double, String)], _ value: Double) -> String {
        for (t, text) in rows where value >= t { return text }
        return rows.last!.1
    }

    private static func buildLabel(color: Double, fabric: Double, size: Double) -> String {
        var parts: [String] = []
        let best  = max(color, fabric, size)
        let worst = min(color, fabric, size)

        if best == color  && color  >= 0.65 { parts.append(pickLabel(colorRows,  color))  }
        if best == fabric && fabric >= 0.65 { parts.append(pickLabel(fabricRows, fabric)) }

        if worst < 0.50 {
            let worstLabel: String
            if worst == color {
                worstLabel = pickLabel(colorRows,  color)
            } else if worst == fabric {
                worstLabel = pickLabel(fabricRows, fabric)
            } else {
                worstLabel = pickLabel(sizeRows,   size)
            }
            if !parts.contains(worstLabel) { parts.append(worstLabel) }
        }

        return parts.isEmpty ? "Balanced look" : parts.joined(separator: " · ")
    }

    public static func score(_ outfit: Outfit) -> OutfitScore {
        if outfit.items.isEmpty {
            return OutfitScore(score: 0, stars: 1, label: "No items selected",
                               colorHarmony: 0, fabricVibe: 0, sizeConsistency: 0)
        }

        let color = ColorHarmony.harmonyScore(of: outfit.items.map(\.colorHex))
        let fabric = FabricVibes.vibeScore(of: outfit.items.map(\.fabricType))
        let size = sizeConsistencyScore(outfit)

        let composite = color * wColor + fabric * wFabric + size * wSize
        let stars = max(1, min(5, Int(ceil(composite * 5))))
        let label = buildLabel(color: color, fabric: fabric, size: size)

        return OutfitScore(score: composite, stars: stars, label: label,
                           colorHarmony: color, fabricVibe: fabric, sizeConsistency: size)
    }
}
