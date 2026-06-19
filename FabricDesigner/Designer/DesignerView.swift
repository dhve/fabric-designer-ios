import SwiftUI

/// Main outfit-designer screen. Hosts the SceneKit viewport, garment rail,
/// pose chips, surprise-me FAB, and the fabric swatch sheet.
public struct DesignerView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var sceneHolder: SceneHolder
    @State private var pose: AvatarPose = .standing
    @State private var activeCategory: GarmentCategory = .top
    @State private var showFabricSheet = false
    @State private var showCompare = false
    @State private var beforeOutfit: Outfit? = nil
    @State private var showSaveSheet = false
    @State private var saveName = ""

    public init() {
        _sceneHolder = StateObject(wrappedValue: SceneHolder())
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            renderer
            VStack(spacing: 0) {
                topHUD
                Spacer()
            }
            VStack(spacing: 12) {
                Spacer()
                outfitBadges
                surpriseFAB
                GarmentRail(
                    wardrobe: wardrobe,
                    activeCategory: activeCategory,
                    selected: app.currentOutfit,
                    onPick: pickItem,
                    onRemove: removeCategory,
                    onCategoryChange: { activeCategory = $0 }
                )
            }
        }
        .background(Theme.void)
        .sheet(isPresented: $showFabricSheet) {
            fabricSheet
        }
        .sheet(isPresented: $showSaveSheet) {
            saveLookSheet
        }
        .sheet(isPresented: $showCompare) {
            if let beforeOutfit {
                BeforeAfterView(before: beforeOutfit, after: app.currentOutfit, measurements: app.measurements)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: app.currentOutfit) { _, new in
            sceneHolder.scene.update(outfit: new)
        }
        .onAppear {
            sceneHolder.scene.update(outfit: app.currentOutfit)
            sceneHolder.scene.setPose(pose)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Renderer

    private var renderer: some View {
        AvatarRenderer(scene: sceneHolder.scene)
            .ignoresSafeArea()
            .background(Theme.void)
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(alignment: .top) {
            poseChip
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatusPill("ATELIER", color: Theme.violetGlow, icon: "sparkles")
                if let m = app.measurements {
                    StatusPill("SIZE \(m.derivedSize)", color: Theme.bone, icon: "tshirt")
                }
                Button { showFabricSheet = true } label: {
                    StatusPill("FABRICS", color: Theme.bone, icon: "circle.grid.3x3.fill")
                }
                if beforeOutfit != nil {
                    Button { showCompare = true } label: {
                        StatusPill("COMPARE", color: Theme.burgundy, icon: "rectangle.split.2x1")
                    }
                }
                Button { showSaveSheet = true; saveName = "" } label: {
                    StatusPill("SAVE LOOK", color: Theme.emerald, icon: "bookmark.fill")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var poseChip: some View {
        HStack(spacing: 6) {
            ForEach(AvatarPose.allCases, id: \.self) { p in
                Button {
                    pose = p
                    sceneHolder.scene.setPose(p)
                } label: {
                    Text(p.displayName.uppercased())
                        .font(HUDFont.monoXS)
                        .tracking(1.2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(pose == p ? Theme.onyx : Theme.bone)
                        .background(pose == p ? Theme.bone : Color.clear)
                        .overlay(
                            Rectangle().stroke(Theme.bone.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Outfit badges (top-right)

    private var outfitBadges: some View {
        let items = app.currentOutfit.items
        let score = OutfitScorer.score(app.currentOutfit)
        return VStack(alignment: .center, spacing: 6) {
            if !items.isEmpty {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= score.stars ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(i <= score.stars ? Theme.violetGlow : Theme.bone.opacity(0.3))
                    }
                    Text(score.label.uppercased())
                        .font(HUDFont.monoXS)
                        .tracking(1.2)
                        .foregroundStyle(Theme.bone)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().stroke(Theme.violetGlow.opacity(0.45), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Surprise Me FAB

    private var surpriseFAB: some View {
        HStack(spacing: 10) {
            Button {
                beforeOutfit = app.currentOutfit
                app.surpriseMe()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("SURPRISE ME").font(HUDFont.label).tracking(1.6)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.bone)
                .background(
                    LinearGradient(colors: [Theme.violet, Theme.violetDeep],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .overlay(Rectangle().stroke(Theme.violetGlow, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { app.like(app.currentOutfit) } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 16, weight: .bold))
                    .padding(14)
                    .foregroundStyle(Theme.emerald)
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().stroke(Theme.emerald.opacity(0.6), lineWidth: 1))
            }
            Button { app.dislike(app.currentOutfit) } label: {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .padding(14)
                    .foregroundStyle(Theme.danger)
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().stroke(Theme.danger.opacity(0.6), lineWidth: 1))
            }
        }
    }

    // MARK: - Sheets

    private var fabricSheet: some View {
        ZStack {
            Theme.void.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text("FABRIC LAB · \(activeCategory.displayName.uppercased())")
                        .font(HUDFont.label)
                        .tracking(1.6)
                        .foregroundStyle(Theme.bone)
                    Spacer()
                    Button { showFabricSheet = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .foregroundStyle(Theme.bone)
                            .background(Theme.carbon)
                    }
                }
                ScrollView {
                    FabricSwatchGrid(
                        selectedFabric: app.currentOutfit.item(in: activeCategory)?.fabricType,
                        selectedColorHex: app.currentOutfit.item(in: activeCategory)?.colorHex
                    ) { fabric, hex in
                        app.applyFabric(fabric, color: hex, to: activeCategory)
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(16)
        }
        .preferredColorScheme(.dark)
    }

    private var saveLookSheet: some View {
        ZStack {
            Theme.void.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("SAVE THIS LOOK")
                    .font(HUDFont.displayCondensed)
                    .foregroundStyle(Theme.bone)
                TextField("Name (e.g. Tokyo Friday)", text: $saveName)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Theme.onyx)
                HUDButton("Save", icon: "bookmark.fill") {
                    let name = saveName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        app.saveLook(name: name)
                        showSaveSheet = false
                    }
                }
                HUDButton("Cancel", style: .ghost) { showSaveSheet = false }
                    .foregroundStyle(Theme.bone)
                Spacer()
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var wardrobe: [Garment] {
        app.wardrobe.garments.isEmpty ? Catalog.default : app.wardrobe.garments
    }

    private func pickItem(_ item: Garment) {
        beforeOutfit = app.currentOutfit
        if app.currentOutfit.item(in: item.category)?.id == item.id {
            app.removeItem(category: item.category)
        } else {
            app.applyItem(item)
        }
    }

    private func removeCategory(_ category: GarmentCategory) {
        beforeOutfit = app.currentOutfit
        app.removeItem(category: category)
    }

    @MainActor
    final class SceneHolder: ObservableObject {
        let scene = AvatarScene()
    }
}
