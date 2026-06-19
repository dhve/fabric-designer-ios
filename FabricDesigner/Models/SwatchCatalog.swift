import Foundation

/// Catalogue of the 15 PBR fabric swatches, ported from the React project's
/// `rendering/swatchData.ts`. Single source of truth for display metadata —
/// the swatch grid, the fabric selector, and the colour-picker presets all
/// pull from this one file.
public struct FabricSwatch: Identifiable, Hashable, Sendable {
    public var id: FabricType { fabric }
    public var fabric: FabricType
    /// Short spec line shown under the swatch name, e.g. "19 momme · glossy".
    public var spec: String
    public var defaultColorHex: String
    public var presetColors: [String]
}

public enum SwatchCatalog {
    /// Row-major order — five swatches per row, three rows.
    public static let all: [FabricSwatch] = [
        // ── Row 0 — Dressy / Luxurious ────────────────────────────────
        FabricSwatch(fabric: .silk,     spec: "19 momme · glossy",     defaultColorHex: "#b07baa",
                     presetColors: ["#b07baa", "#7b9eb0", "#2c3e50", "#e8e0d5", "#c5a55a", "#8b5e83"]),
        FabricSwatch(fabric: .satin,    spec: "7 oz · mirror sheen",   defaultColorHex: "#7b9eb0",
                     presetColors: ["#7b9eb0", "#b07baa", "#c5a55a", "#2c3e50", "#e8c5d5", "#5c8d5c"]),
        FabricSwatch(fabric: .velvet,   spec: "crushed pile · deep",   defaultColorHex: "#6b3e8e",
                     presetColors: ["#6b3e8e", "#3e6b8e", "#8e3e3e", "#3e8e6b", "#8e7b3e", "#1a0030"]),
        FabricSwatch(fabric: .chiffon,  spec: "sheer · featherweight", defaultColorHex: "#f0d5e8",
                     presetColors: ["#f0d5e8", "#d5e8f0", "#f0e8d5", "#e8f0d5", "#d5d5f0", "#f8f8f0"]),
        FabricSwatch(fabric: .cashmere, spec: "2-ply · buttery soft",  defaultColorHex: "#d4b89a",
                     presetColors: ["#d4b89a", "#c8a882", "#4a4a4a", "#8b6b5b", "#e8e0d5", "#2c2c2c"]),

        // ── Row 1 — Everyday ──────────────────────────────────────────
        FabricSwatch(fabric: .cotton,    spec: "5 oz · breathable",    defaultColorHex: "#e8e0d5",
                     presetColors: ["#e8e0d5", "#f5f5f0", "#c8a882", "#4a4a4a", "#7bbf7b", "#4a6fa5"]),
        FabricSwatch(fabric: .linen,     spec: "6 oz · natural weave", defaultColorHex: "#c9b99a",
                     presetColors: ["#c9b99a", "#d4c4a8", "#8b7b6b", "#4a4a4a", "#e8e0d5", "#7b9b7b"]),
        FabricSwatch(fabric: .jersey,    spec: "knit · stretchy",      defaultColorHex: "#4a7a6e",
                     presetColors: ["#4a7a6e", "#7a4a4a", "#4a4a7a", "#7a7a4a", "#2c2c2c", "#e8e8e8"]),
        FabricSwatch(fabric: .polyester, spec: "4 oz · wrinkle-free",  defaultColorHex: "#6b7fa8",
                     presetColors: ["#6b7fa8", "#a87b6b", "#7ba87b", "#a8a86b", "#6b6b6b", "#c8d5e8"]),
        FabricSwatch(fabric: .canvas,    spec: "10 oz · heavy duty",   defaultColorHex: "#8b7355",
                     presetColors: ["#8b7355", "#556b8b", "#8b5555", "#55558b", "#4a4a4a", "#c9b99a"]),

        // ── Row 2 — Structured / Rugged ───────────────────────────────
        FabricSwatch(fabric: .denim,   spec: "12 oz · twill weave",    defaultColorHex: "#4a6fa5",
                     presetColors: ["#4a6fa5", "#1c2c4c", "#3d4f6b", "#7b9eb0", "#2c3e50", "#6b8bb0"]),
        FabricSwatch(fabric: .tweed,   spec: "14 oz · herringbone",    defaultColorHex: "#6b5d4f",
                     presetColors: ["#6b5d4f", "#4f5d6b", "#5d6b4f", "#6b4f5d", "#3d3530", "#8b7b6b"]),
        FabricSwatch(fabric: .wool,    spec: "8 oz · warm fibres",     defaultColorHex: "#8b6b5b",
                     presetColors: ["#8b6b5b", "#5b6b8b", "#6b8b5b", "#8b5b6b", "#4a3a30", "#c9b99a"]),
        FabricSwatch(fabric: .leather, spec: "full-grain · smooth",    defaultColorHex: "#5c3d2e",
                     presetColors: ["#5c3d2e", "#2e3d5c", "#3d5c2e", "#5c2e3d", "#1a1a1a", "#8b6b5b"]),
        FabricSwatch(fabric: .suede,   spec: "napped grain · matte",   defaultColorHex: "#9b7b6b",
                     presetColors: ["#9b7b6b", "#6b7b9b", "#7b9b6b", "#9b6b7b", "#3d3030", "#c9b99a"]),
    ]

    public static func swatch(for fabric: FabricType) -> FabricSwatch {
        all.first { $0.fabric == fabric } ?? all[0]
    }
}
