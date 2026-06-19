import Foundation

/// Smart outfit generator, ported from the Replit `outfit/OutfitEngine.ts`.
/// Runs a scored tournament over random candidates, biases picks toward the
/// vibe the user has been liking, and skips any combination they've
/// previously disliked.
public enum OutfitEngine {

    // ── Apply / remove ───────────────────────────────────────────────
    public static func apply(_ item: Garment, to outfit: Outfit) -> Outfit {
        var items = outfit.items.filter { $0.category != item.category }
        items.append(item)
        return Outfit(items: items)
    }

    public static func remove(_ category: GarmentCategory, from outfit: Outfit) -> Outfit {
        Outfit(items: outfit.items.filter { $0.category != category })
    }

    // ── Smart generation ─────────────────────────────────────────────
    private static let requiredCategories: [GarmentCategory] = [.top, .bottom, .shoes]
    private static let optionalCategories: [GarmentCategory] = [.outerwear]
    private static let tournamentSize    = 10
    private static let extendedAttempts  = 90
    private static let historyPenalty    = 0.20
    private static let historyThreshold  = 0.50
    private static let biasStrength      = 0.70

    private static func overlapRatio(_ a: [String], _ b: [String]) -> Double {
        if a.isEmpty || b.isEmpty { return 0 }
        let setB = Set(b)
        let common = a.filter { setB.contains($0) }.count
        return Double(common) / Double(max(a.count, b.count))
    }

    private static func pickWithVibeBias(
        pool: [Garment],
        preferred: FabricType.Vibe?,
        biasStrength: Double
    ) -> Garment {
        guard let preferred, Double.random(in: 0..<1) <= biasStrength else {
            return pool.randomElement() ?? pool[0]
        }
        let preferredFabrics = Set(FabricVibes.fabrics(for: preferred))
        let biased = pool.filter { preferredFabrics.contains($0.fabricType) }
        let source = biased.isEmpty ? pool : biased
        return source.randomElement() ?? source[0]
    }

    private static func naivePick(_ catalog: [Garment]) -> Outfit {
        var items: [Garment] = []
        for cat in requiredCategories {
            let pool = catalog.filter { $0.category == cat }
            if let pick = pool.randomElement() { items.append(pick) }
        }
        return Outfit(items: items)
    }

    /// Tournament-based outfit generator.
    public static func generate(
        wardrobe: [Garment],
        history: [[String]] = [],
        likes: [[String]] = [],
        dislikes: [[String]] = []
    ) -> Outfit {
        let wardrobeFabricByID = Dictionary(uniqueKeysWithValues: wardrobe.map { ($0.id, $0.fabricType) })
        let preferredVibe = FabricVibes.inferPreferredVibe(likes: likes, wardrobeFabricByID: wardrobeFabricByID)

        let dislikedKeys: Set<String> = Set(dislikes.map { $0.sorted().joined(separator: "|") })

        var pools: [GarmentCategory: [Garment]] = [:]
        for cat in requiredCategories + optionalCategories {
            pools[cat] = wardrobe.filter { $0.category == cat }
        }
        let outerPool = pools[.outerwear] ?? []

        if requiredCategories.contains(where: { (pools[$0]?.count ?? 0) == 0 }) {
            return naivePick(wardrobe)
        }

        func pickCandidate() -> (items: [Garment], key: String) {
            var items: [Garment] = requiredCategories.map { cat in
                pickWithVibeBias(pool: pools[cat]!, preferred: preferredVibe, biasStrength: biasStrength)
            }
            if !outerPool.isEmpty && Double.random(in: 0..<1) < 0.5 {
                items.append(pickWithVibeBias(pool: outerPool, preferred: preferredVibe, biasStrength: biasStrength))
            }
            let key = items.map(\.id).sorted().joined(separator: "|")
            return (items, key)
        }

        // ── Phase 1: scored tournament ──────────────────────────────
        var best: Outfit? = nil
        var bestScore = -Double.infinity
        for _ in 0..<tournamentSize {
            let (items, key) = pickCandidate()
            if dislikedKeys.contains(key) { continue }
            let ids = items.map(\.id)
            let score = OutfitScorer.score(Outfit(items: items)).score
            let maxOverlap = history.reduce(0.0) { max($0, overlapRatio(ids, $1)) }
            let adjusted = score - (maxOverlap >= historyThreshold ? historyPenalty : 0)
            if adjusted > bestScore {
                bestScore = adjusted
                best = Outfit(items: items)
            }
        }
        if let best { return best }

        // ── Phase 2: extended dislike-safe search ────────────────────
        for _ in 0..<extendedAttempts {
            let (items, key) = pickCandidate()
            if !dislikedKeys.contains(key) { return Outfit(items: items) }
        }

        // ── Phase 3: absolute last resort ───────────────────────────
        return naivePick(wardrobe)
    }
}
