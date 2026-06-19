import SwiftUI

/// Brand palette and design tokens for "Build A Setup / Atelier".
///
/// PRD direction: "Sterile whites with vibrant but limited explosions of dark
/// but bold colors, violets, burgundy, or other gem tones, but with a stark
/// contrast of monochromatic elements. Cyberpunk, ghost in the shell,
/// information warfare, streetwear combat, future punk corporate."
public enum Theme {
    // ── Surfaces (sterile whites / monochrome contrast) ──────────────
    public static let bone        = Color(hex: "#F6F6F2")!         // primary surface
    public static let canvas      = Color(hex: "#ECECEA")!         // recessed surface
    public static let chrome      = Color(hex: "#D9D9D6")!         // hairlines on light
    public static let onyx        = Color(hex: "#0A0A0F")!         // primary dark
    public static let void        = Color(hex: "#05050A")!         // deepest dark
    public static let carbon      = Color(hex: "#16161D")!         // raised dark
    public static let graphite    = Color(hex: "#1F1F2A")!         // panel dark

    // ── Brand accents (gem-tone explosions) ───────────────────────────
    public static let violet      = Color(hex: "#6B3E8E")!         // primary accent
    public static let violetDeep  = Color(hex: "#3D1F66")!
    public static let violetGlow  = Color(hex: "#B07BFF")!
    public static let burgundy    = Color(hex: "#8E3E5C")!         // secondary accent
    public static let emerald     = Color(hex: "#3E8E6B")!         // gem 1
    public static let sapphire    = Color(hex: "#3E6B8E")!         // gem 2
    public static let citrine     = Color(hex: "#C5A55A")!         // gem 3
    public static let plasma      = Color(hex: "#FF4DAA")!         // signal/highlight

    // ── Semantic tokens ───────────────────────────────────────────────
    public static let textPrimary   = onyx
    public static let textSecondary = Color(hex: "#5C5C66")!
    public static let textInverse   = bone
    public static let line          = Color(hex: "#23232E")!.opacity(0.18)
    public static let lineDark      = Color.white.opacity(0.10)
    public static let success       = emerald
    public static let warning       = Color(hex: "#D89A3E")!
    public static let danger        = Color(hex: "#D24A4A")!
}

public extension Color {
    /// Hex initializer — accepts `#rrggbb` or `#rgb`. Returns nil on bad input.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >>  8) & 0xFF) / 255.0
        let b = Double( v        & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

/// Monospaced HUD font stack — anchors the "information warfare" tone.
public enum HUDFont {
    public static let mono   = Font.system(size: 11, design: .monospaced).weight(.medium)
    public static let monoXS = Font.system(size: 9,  design: .monospaced).weight(.medium)
    public static let monoLG = Font.system(size: 14, design: .monospaced).weight(.semibold)
    public static let displayHeavy = Font.system(size: 34, weight: .heavy, design: .default)
    public static let displayCondensed = Font.system(size: 22, weight: .heavy, design: .rounded)
    public static let title  = Font.system(size: 17, weight: .bold)
    public static let body   = Font.system(size: 14, weight: .regular)
    public static let label  = Font.system(size: 12, weight: .semibold)
}
