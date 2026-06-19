import Foundation

/// Color-harmony scoring, ported verbatim from `outfit/colorUtils.ts`.
public enum ColorHarmony {

    /// Hex (#rrggbb / #rgb) → HSL (h: 0–360°, s: 0–100, l: 0–100).
    public static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
        var s = hex.replacingOccurrences(of: "#", with: "")
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return (0, 0, 0) }

        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >>  8) & 0xFF) / 255.0
        let b = Double( v        & 0xFF) / 255.0

        let mx = max(r, g, b)
        let mn = min(r, g, b)
        let delta = mx - mn
        let l = (mx + mn) / 2.0
        var sat = 0.0
        var h   = 0.0

        if delta != 0 {
            sat = delta / (1.0 - abs(2.0 * l - 1.0))
            if mx == r {
                let q = (g - b) / delta
                h = q.truncatingRemainder(dividingBy: 6)
            } else if mx == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h = (h * 60 + 360).truncatingRemainder(dividingBy: 360)
        }
        return (h, sat * 100, l * 100)
    }

    /// 0–1 harmony score for a set of garment hex colors.
    ///
    /// Rules (chromatic colors only; neutrals don't penalise):
    ///   < 2 chromatic colors → 1.0 (nothing to clash)
    ///   hue 0–30°   analogous          0.90
    ///   hue 30–60°  near-analogous     0.50
    ///   hue 60–120° clash zone         0.30
    ///   hue 120–150° split-complement  0.80
    ///   hue 150–180° complementary     1.00
    public static func harmonyScore(of hexColors: [String], neutralSatThreshold: Double = 20.0) -> Double {
        let chromatic = hexColors
            .map(hexToHSL)
            .filter { $0.s >= neutralSatThreshold }

        if chromatic.count < 2 { return 1.0 }

        var minScore = 1.0
        for i in 0..<chromatic.count {
            for j in (i + 1)..<chromatic.count {
                let raw = abs(chromatic[i].h - chromatic[j].h)
                let hueDist = min(raw, 360 - raw)
                let pair: Double
                if hueDist <= 30 {
                    pair = 0.9
                } else if hueDist <= 60 {
                    pair = 0.5
                } else if hueDist <= 120 {
                    pair = 0.3
                } else if hueDist <= 150 {
                    pair = 0.8
                } else {
                    pair = 1.0
                }
                if pair < minScore { minScore = pair }
            }
        }
        return minScore
    }
}
