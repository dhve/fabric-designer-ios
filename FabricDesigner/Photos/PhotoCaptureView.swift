import SwiftUI
import PhotosUI

/// The PRD's second step: capture 5 reference photos plus design / fit notes
/// that ship with the order. Uses PhotosPicker so it works in simulator and
/// on device without dragging the full camera-capture session in.
public struct PhotoCaptureView: View {
    @EnvironmentObject private var app: AppState
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var thumbnails: [UIImage] = []
    @State private var notes: String = ""

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                photoStrip
                notesField
                summary
                HUDButton("Continue to Checkout", icon: "chevron.right.circle.fill", style: .primary) {
                    app.photos = thumbnails
                    app.designerNotes = notes
                    app.flow = .checkout
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.bone.ignoresSafeArea())
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadImages(from: newItems) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MODULE · 03")
                .font(HUDFont.monoXS).tracking(2.5)
                .foregroundStyle(Theme.violet)
            Text("Reference\nphotos & notes")
                .font(HUDFont.displayHeavy)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(-4)
            Text("Up to 5 photos. Designer or tailor will overlay these with your LiDAR dimensions to cut the pattern.")
                .font(HUDFont.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PHOTOS \(thumbnails.count)/5").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.textSecondary)
                Spacer()
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    StatusPill("ADD", color: Theme.violet, icon: "plus")
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(thumbnails.indices, id: \.self) { i in
                        Image(uiImage: thumbnails[i])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 132)
                            .clipped()
                            .overlay(Rectangle().stroke(Theme.line, lineWidth: 0.5))
                            .overlay(
                                StatusPill("0\(i + 1)", color: Theme.bone, icon: nil)
                                    .padding(6),
                                alignment: .topLeading
                            )
                    }
                    if thumbnails.count < 5 {
                        ForEach(thumbnails.count..<5, id: \.self) { i in
                            VStack(spacing: 6) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("0\(i + 1)").font(HUDFont.monoXS).foregroundStyle(Theme.textSecondary)
                            }
                            .frame(width: 92, height: 132)
                            .background(Theme.canvas)
                            .overlay(Rectangle().stroke(Theme.line, lineWidth: 0.5))
                        }
                    }
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FIT NOTES").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.textSecondary)
            TextEditor(text: $notes)
                .frame(minHeight: 110)
                .padding(8)
                .background(Theme.canvas)
                .overlay(Rectangle().stroke(Theme.line, lineWidth: 0.5))
                .font(HUDFont.body)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var summary: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WHAT GETS SHIPPED").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.violet)
                bullet("Outfit & fabric IDs (chained to designer credit)")
                bullet("LiDAR dimensions (cm + size class)")
                bullet("\(thumbnails.count) reference photo(s)")
                bullet(notes.trimmingCharacters(in: .whitespaces).isEmpty ? "No additional notes" : "Fit notes (\(notes.count) chars)")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("›").font(HUDFont.monoLG).foregroundStyle(Theme.violet)
            Text(text).font(HUDFont.body).foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    @MainActor
    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(5) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                images.append(img)
            }
        }
        thumbnails = images
    }
}
