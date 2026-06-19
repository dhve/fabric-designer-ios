import SwiftUI

/// Saved-looks browser, garment inventory, and lightweight analytics.
public struct WardrobeView: View {
    @EnvironmentObject private var app: AppState
    @State private var filterCategory: GarmentCategory? = nil
    @State private var filterFabric: FabricType? = nil

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                if let m = app.measurements { dimensionsCard(m: m) }
                savedLooksSection
                inventorySection
                analyticsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .background(Theme.bone.ignoresSafeArea())
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WARDROBE")
                .font(HUDFont.monoXS).tracking(2)
                .foregroundStyle(Theme.violet)
            Text("Atelier · v0.1")
                .font(HUDFont.displayCondensed)
                .foregroundStyle(Theme.textPrimary)
            Text("\(app.wardrobe.garments.count) garments · \(app.wardrobe.looks.count) saved looks")
                .font(HUDFont.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private func dimensionsCard(m: BodyMeasurements) -> some View {
        HUDPanel(tone: .light, corners: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CURRENT DIMENSIONS")
                        .font(HUDFont.monoXS).tracking(1.8)
                        .foregroundStyle(Theme.violet)
                    Spacer()
                    StatusPill("SIZE \(m.derivedSize)", color: Theme.violet, icon: "tshirt")
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    miniMeasure("Height", value: m.heightCM)
                    miniMeasure("Chest",  value: m.chestCircumferenceCM)
                    miniMeasure("Waist",  value: m.waistCircumferenceCM)
                    miniMeasure("Hip",    value: m.hipCircumferenceCM)
                    miniMeasure("Inseam", value: m.inseamCM)
                    miniMeasure("Sleeve", value: m.sleeveLengthCM)
                }
            }
        }
    }

    private func miniMeasure(_ label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(HUDFont.monoXS).tracking(1.2)
                .foregroundStyle(Theme.textSecondary)
            Text(value.formatted(in: .cm))
                .font(HUDFont.monoLG.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.canvas)
    }

    private var savedLooksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Saved Looks")
            if app.wardrobe.looks.isEmpty {
                emptyHint("No looks saved yet — generate one and tap Save Look.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(app.wardrobe.looks) { look in
                        savedLookCard(look)
                    }
                }
            }
        }
    }

    private func savedLookCard(_ look: SavedLook) -> some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 8) {
                Text(look.name)
                    .font(HUDFont.title)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    ForEach(look.outfit.items) { item in
                        Circle()
                            .fill(item.swiftUIColor)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Theme.line, lineWidth: 0.5))
                    }
                }
                HStack {
                    Button { app.loadOutfit(look.outfit) } label: {
                        Text("LOAD").font(HUDFont.monoXS).tracking(1.4)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .foregroundStyle(Theme.bone).background(Theme.onyx)
                    }
                    Spacer()
                    Button { app.wardrobe.deleteLook(look.name) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.danger)
                    }
                }
            }
        }
    }

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Inventory")

            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("All", isOn: filterCategory == nil && filterFabric == nil) {
                        filterCategory = nil; filterFabric = nil
                    }
                    ForEach(GarmentCategory.allCases.filter { $0 != .accessories }, id: \.self) { cat in
                        chip(cat.displayName, isOn: filterCategory == cat) {
                            filterCategory = (filterCategory == cat) ? nil : cat
                        }
                    }
                    Divider().frame(height: 16).overlay(Theme.line)
                    ForEach(FabricType.allCases.prefix(15), id: \.self) { fab in
                        chip(fab.displayName, isOn: filterFabric == fab) {
                            filterFabric = (filterFabric == fab) ? nil : fab
                        }
                    }
                }
                .padding(.bottom, 2)
            }

            let filtered = app.wardrobe.garments.filter {
                (filterCategory == nil || $0.category == filterCategory!) &&
                (filterFabric == nil || $0.fabricType == filterFabric!)
            }
            if filtered.isEmpty {
                emptyHint("No matching garments.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(filtered) { g in
                        garmentCard(g)
                    }
                }
            }
        }
    }

    private func garmentCard(_ g: Garment) -> some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 6) {
                Circle()
                    .fill(g.swiftUIColor)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Theme.line, lineWidth: 0.5))
                Text(g.name).font(HUDFont.label).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text("\(g.fabricType.displayName) · \(g.colorName)")
                    .font(HUDFont.monoXS)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button("Add to outfit") { app.applyItem(g) }
            Button("Delete", role: .destructive) { app.wardrobe.delete(garmentID: g.id) }
        }
    }

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Analytics")
            HUDPanel(tone: .light) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 16) {
                        statCol("Garments", value: "\(app.wardrobe.garments.count)")
                        statCol("Looks",    value: "\(app.wardrobe.looks.count)")
                        statCol("Likes",    value: "\(app.history.likes.count)")
                        statCol("Dislikes", value: "\(app.history.dislikes.count)")
                    }
                    Divider().overlay(Theme.line)
                    fabricDistribution
                }
            }
        }
    }

    private func statCol(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(HUDFont.monoXS).tracking(1.2)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(HUDFont.displayCondensed)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fabricDistribution: some View {
        let counts = Dictionary(grouping: app.wardrobe.garments, by: \.fabricType).mapValues(\.count)
        let total = max(1, app.wardrobe.garments.count)
        return VStack(alignment: .leading, spacing: 8) {
            Text("FABRIC DISTRIBUTION").font(HUDFont.monoXS).tracking(1.4).foregroundStyle(Theme.textSecondary)
            ForEach(FabricType.allCases, id: \.self) { f in
                let n = counts[f, default: 0]
                if n > 0 {
                    HStack(spacing: 8) {
                        Text(f.displayName).font(HUDFont.monoXS).frame(width: 70, alignment: .leading).foregroundStyle(Theme.textPrimary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Theme.canvas).frame(height: 8)
                                Rectangle().fill(Theme.violet).frame(width: geo.size.width * CGFloat(n) / CGFloat(total), height: 8)
                            }
                        }
                        .frame(height: 8)
                        Text("\(n)").font(HUDFont.monoXS).foregroundStyle(Theme.textSecondary).frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Bits

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(HUDFont.label).tracking(1.8)
            .foregroundStyle(Theme.violet)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(HUDFont.monoXS).tracking(1.2)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .foregroundStyle(isOn ? Theme.bone : Theme.textPrimary)
                .background(isOn ? Theme.violet : Theme.canvas)
                .overlay(Rectangle().stroke(Theme.line, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func emptyHint(_ text: String) -> some View {
        HUDPanel(tone: .light) {
            Text(text)
                .font(HUDFont.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
