import Foundation

/// Ported from `outfit/fabricUtils.ts`: split fabrics into two style registers
/// and score how cohesively a set of fabrics work together.
public enum FabricVibes {
    /// 1.0 when all fabrics share the same vibe; 0.5 when dressy mixes with
    /// casual; 1.0 when there's only one unique fabric in play.
    public static func vibeScore(of fabrics: [FabricType]) -> Double {
        let unique = Array(Set(fabrics))
        if unique.count < 2 { return 1.0 }
        let vibes = Set(unique.map(\.vibe))
        return vibes.count <= 1 ? 1.0 : 0.5
    }

    /// Walk the user's liked outfits and decide which vibe to bias the
    /// surprise-me generator toward. Returns nil when the signal is too weak.
    public static func inferPreferredVibe(
        likes: [[String]],
        wardrobeFabricByID: [String: FabricType]
    ) -> FabricType.Vibe? {
        var tally: [FabricType.Vibe: Int] = [.dressy: 0, .casual: 0]
        for ids in likes {
            for id in ids {
                guard let fabric = wardrobeFabricByID[id] else { continue }
                tally[fabric.vibe, default: 0] += 1
            }
        }
        let total = (tally[.dressy] ?? 0) + (tally[.casual] ?? 0)
        if total == 0 { return nil }
        if Double(tally[.dressy] ?? 0) / Double(total) > 0.6 { return .dressy }
        if Double(tally[.casual] ?? 0) / Double(total) > 0.6 { return .casual }
        return nil
    }

    public static func fabrics(for vibe: FabricType.Vibe) -> [FabricType] {
        FabricType.allCases.filter { $0.vibe == vibe }
    }
}
