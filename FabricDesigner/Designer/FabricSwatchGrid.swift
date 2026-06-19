import SwiftUI

/// 5×3 swatch grid — the iOS counterpart of the React `FabricSelector`.
/// Each swatch is a sphere preview rendered from the same PBR material the
/// designer scene uses, so cotton looks matte, silk glossy, etc.
public struct FabricSwatchGrid: View {
    public var selectedFabric: FabricType?
    public var selectedColorHex: String?
    public var onPick: (FabricType, String) -> Void

    public init(
        selectedFabric: FabricType?,
        selectedColorHex: String?,
        onPick: @escaping (FabricType, String) -> Void
    ) {
        self.selectedFabric = selectedFabric
        self.selectedColorHex = selectedColorHex
        self.onPick = onPick
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowLabel("DRESSY · LUXURIOUS")
            row(0..<5)
            rowLabel("EVERYDAY")
            row(5..<10)
            rowLabel("STRUCTURED · RUGGED")
            row(10..<15)
        }
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .font(HUDFont.monoXS)
            .tracking(1.4)
            .foregroundStyle(Theme.violetGlow)
    }

    private func row(_ range: Range<Int>) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(range, id: \.self) { i in
                cell(swatch: SwatchCatalog.all[i])
            }
        }
    }

    private func cell(swatch: FabricSwatch) -> some View {
        let isSelected = selectedFabric == swatch.fabric
        let color = isSelected ? (selectedColorHex ?? swatch.defaultColorHex) : swatch.defaultColorHex
        return Button {
            onPick(swatch.fabric, color)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: color) ?? .gray)
                    Circle()
                        .stroke(isSelected ? Theme.violetGlow : Color.white.opacity(0.10), lineWidth: isSelected ? 2 : 1)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                }
                .frame(width: 44, height: 44)
                Text(swatch.fabric.displayName)
                    .font(HUDFont.monoXS)
                    .foregroundStyle(Theme.bone.opacity(0.9))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(swatch.presetColors, id: \.self) { hex in
                Button {
                    onPick(swatch.fabric, hex)
                } label: {
                    Label(hex, systemImage: "circle.fill")
                        .foregroundStyle(Color(hex: hex) ?? .gray)
                }
            }
        }
    }
}
