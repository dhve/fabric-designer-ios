import SwiftUI

/// Horizontal scroll of garment chips per category, plus a slot picker.
/// Sits at the bottom of the designer viewport.
public struct GarmentRail: View {
    public var wardrobe: [Garment]
    public var activeCategory: GarmentCategory
    public var selected: Outfit
    public var onPick: (Garment) -> Void
    public var onRemove: (GarmentCategory) -> Void
    public var onCategoryChange: (GarmentCategory) -> Void

    public var body: some View {
        VStack(spacing: 8) {
            categoryBar
            chipScroll
        }
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [
                Theme.void.opacity(0.0),
                Theme.void.opacity(0.65),
                Theme.void.opacity(0.85),
            ], startPoint: .top, endPoint: .bottom)
        )
    }

    // ── Category selector ───────────────────────────────────────────
    private var categoryBar: some View {
        HStack(spacing: 0) {
            ForEach(GarmentCategory.allCases.filter { $0 != .accessories }, id: \.self) { cat in
                Button { onCategoryChange(cat) } label: {
                    VStack(spacing: 4) {
                        Text(cat.shortLabel)
                            .font(HUDFont.monoXS)
                            .tracking(1.6)
                            .foregroundStyle(cat == activeCategory ? Theme.violetGlow : Theme.bone.opacity(0.6))
                        Rectangle()
                            .fill(cat == activeCategory ? Theme.violetGlow : Color.clear)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── Garment chips ───────────────────────────────────────────────
    private var chipScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                let pool = wardrobe.filter { $0.category == activeCategory }
                ForEach(pool) { item in
                    chip(item: item, selected: selected.item(in: activeCategory)?.id == item.id)
                }
                if selected.item(in: activeCategory) != nil {
                    Button { onRemove(activeCategory) } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.danger)
                                .frame(width: 50, height: 50)
                                .background(Theme.carbon)
                            Text("CLEAR")
                                .font(HUDFont.monoXS)
                                .foregroundStyle(Theme.bone.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(item: Garment, selected: Bool) -> some View {
        Button { onPick(item) } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(item.swiftUIColor)
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(selected ? Theme.violetGlow : Color.white.opacity(0.10),
                                lineWidth: selected ? 2 : 1)
                        .frame(width: 50, height: 50)
                }
                Text(item.name)
                    .font(HUDFont.monoXS)
                    .foregroundStyle(Theme.bone.opacity(selected ? 1 : 0.7))
                    .lineLimit(1)
                    .frame(maxWidth: 80)
                Text(item.fabricType.displayName.uppercased())
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .tracking(1.4)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundStyle(Theme.bone)
                    .background(Theme.violet.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}
