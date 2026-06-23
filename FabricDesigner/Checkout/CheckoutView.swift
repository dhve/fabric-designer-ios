import SwiftUI

/// Final demo handoff step: builds a tailor-ready order/spec PDF with optional
/// shipping and payment notes. No card numbers, network requests, or PII leave
/// the device.
public struct CheckoutView: View {
    @EnvironmentObject private var app: AppState
    @State private var payment: PaymentMethod = .crypto
    @State private var shipping = ShippingInfo()
    @State private var confirmed = false
    @State private var basePrice: Double = 489.0
    @State private var pdfURL: URL?
    @State private var pdfError: String?
    @State private var showMeasurementEditor = false

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                outfitSummary
                measurementsCard
                shippingForm
                PaymentMethodPicker(selection: $payment)
                totalsCard
                actions
            }
            .padding(20)
            .padding(.bottom, 80)
        }
        .background(Theme.bone.ignoresSafeArea())
        .sheet(isPresented: $confirmed) { confirmation }
        .sheet(isPresented: $showMeasurementEditor) {
            ManualMeasurementView(title: "Edit Measurements", prefill: app.measurements) { measurements in
                app.acceptMeasurements(measurements)
                showMeasurementEditor = false
            } onCancel: {
                showMeasurementEditor = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MODULE · 04")
                .font(HUDFont.monoXS).tracking(2.5)
                .foregroundStyle(Theme.violet)
            Text("Order PDF")
                .font(HUDFont.displayHeavy)
                .foregroundStyle(Theme.textPrimary)
            Text("Generate a tailor-ready spec sheet from the selected look and trusted measurements. Payment remains demo-only.")
                .font(HUDFont.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var outfitSummary: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 10) {
                Text("LINE ITEMS").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.violet)
                ForEach(app.currentOutfit.items) { item in
                    HStack {
                        Circle().fill(item.swiftUIColor).frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Theme.line, lineWidth: 0.5))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.name).font(HUDFont.label).foregroundStyle(Theme.textPrimary)
                            Text("\(item.fabricType.displayName.uppercased()) · \(item.colorName)")
                                .font(HUDFont.monoXS).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                }
                if let m = app.measurements {
                    Divider().overlay(Theme.line)
                    HStack {
                        StatusPill("SIZE \(m.derivedSize)", color: Theme.violet, icon: "tshirt")
                        StatusPill("CHEST \(Int(m.chestCircumferenceCM))CM", color: Theme.bone, icon: "ruler")
                        StatusPill("WAIST \(Int(m.waistCircumferenceCM))CM", color: Theme.bone, icon: "ruler")
                    }
                }
            }
        }
    }

    private var shippingForm: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SHIP TO · OPTIONAL FOR DEMO").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.violet)
                field("Full name", text: $shipping.fullName)
                field("Street 1",  text: $shipping.line1)
                field("Street 2",  text: $shipping.line2)
                HStack {
                    field("City",       text: $shipping.city)
                    field("Region",     text: $shipping.region).frame(width: 110)
                }
                HStack {
                    field("Postal Code",text: $shipping.postalCode).frame(width: 140)
                    field("Country",    text: $shipping.country)
                }
                field("Notes",     text: $shipping.notes)
            }
        }
    }

    private var measurementsCard: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MEASUREMENTS")
                        .font(HUDFont.monoXS)
                        .tracking(1.6)
                        .foregroundStyle(Theme.violet)
                    Spacer()
                    Button {
                        showMeasurementEditor = true
                    } label: {
                        StatusPill(app.measurements == nil ? "ENTER" : "EDIT", color: Theme.violet, icon: "ruler")
                    }
                    .buttonStyle(.plain)
                }

                if let m = app.measurements {
                    HStack {
                        StatusPill(m.source.displayName.uppercased(), color: Theme.violet, icon: "checkmark.seal")
                        StatusPill("CONF \(Int(m.confidence * 100))%", color: m.confidence >= 0.8 ? Theme.emerald : Theme.warning, icon: "gauge")
                    }
                    HStack {
                        StatusPill("CHEST \(Int(m.chestCircumferenceCM))CM", color: Theme.bone, icon: "ruler")
                        StatusPill("WAIST \(Int(m.waistCircumferenceCM))CM", color: Theme.bone, icon: "ruler")
                        StatusPill("INSEAM \(Int(m.inseamCM))CM", color: Theme.bone, icon: "ruler")
                    }
                    if !m.validationIssues.isEmpty {
                        Text(m.validationIssues.joined(separator: "\n"))
                            .font(HUDFont.body)
                            .foregroundStyle(Theme.danger)
                    }
                } else {
                    Text("Manual measurements are required before generating the tailor order PDF.")
                        .font(HUDFont.body)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .padding(10)
            .background(Theme.canvas)
            .overlay(Rectangle().stroke(Theme.line, lineWidth: 0.5))
            .font(HUDFont.body)
            .foregroundStyle(Theme.textPrimary)
    }

    private var totalsCard: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 8) {
                row("Outfit base",  String(format: "$%.2f", basePrice))
                row("Restocking",   payment.carriesRestockingNotice
                    ? String(format: "+ $%.2f (110%%)", basePrice * 0.10)
                    : "$0.00")
                Divider().overlay(Theme.line)
                row("TOTAL", String(format: "$%.2f", basePrice * payment.restockingMultiplier), bold: true)
            }
        }
    }

    private func row(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label.uppercased()).font(HUDFont.monoXS).tracking(1.4).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? HUDFont.displayCondensed.monospacedDigit() : HUDFont.monoLG.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            HUDButton("Generate Order PDF", icon: "doc.richtext", style: .primary) {
                let order = Order(
                    outfit: app.currentOutfit,
                    measurements: app.measurements,
                    photoCount: app.photos.count,
                    designerNotes: app.designerNotes,
                    paymentMethod: payment,
                    shipping: shipping,
                    basePriceUSD: basePrice
                )
                app.lastOrder = order
                do {
                    pdfURL = try OrderPDFGenerator.generate(order: order)
                    pdfError = nil
                } catch {
                    pdfURL = nil
                    pdfError = error.localizedDescription
                }
                confirmed = true
            }
            .disabled(!canGeneratePDF)
            .opacity(canGeneratePDF ? 1 : 0.45)
            HUDButton("Back", style: .ghost) { app.flow = .photos }
        }
    }

    private var canGeneratePDF: Bool {
        app.measurements?.isTailorReady == true
    }

    private var confirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Theme.violet)
            Text("PDF ready").font(HUDFont.displayHeavy).foregroundStyle(Theme.textPrimary)
            Text("The order/spec PDF was generated on device. No payment was charged and no data was sent off-device.")
                .font(HUDFont.body).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Label("Share / Email Order PDF", systemImage: "square.and.arrow.up")
                        .font(HUDFont.label)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.onyx)
                        .foregroundStyle(Theme.bone)
                }
                .padding(.horizontal, 32)
            } else if let pdfError {
                Text("PDF generation failed: \(pdfError)")
                    .font(HUDFont.body)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            HUDButton("Done", icon: "checkmark", style: .primary) {
                confirmed = false
                app.resetFlow()
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 60)
        .background(Theme.bone.ignoresSafeArea())
    }
}
