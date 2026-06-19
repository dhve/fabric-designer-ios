import SwiftUI

/// Final step of the PRD flow — multi-tender checkout + shipping notes.
/// In demo mode this records the order locally and shows a confirmation;
/// no card numbers, network requests, or PII leaves the device.
public struct CheckoutView: View {
    @EnvironmentObject private var app: AppState
    @State private var payment: PaymentMethod = .crypto
    @State private var shipping = ShippingInfo()
    @State private var confirmed = false
    @State private var basePrice: Double = 489.0

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                outfitSummary
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MODULE · 04")
                .font(HUDFont.monoXS).tracking(2.5)
                .foregroundStyle(Theme.violet)
            Text("Checkout")
                .font(HUDFont.displayHeavy)
                .foregroundStyle(Theme.textPrimary)
            Text("One outfit, locked to your dimensions and designer credit. Pick a tender that matches your tribe.")
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
                Text("SHIP TO").font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.violet)
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
            HUDButton("Place Order", icon: "checkmark.seal.fill", style: .primary) {
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
                confirmed = true
            }
            HUDButton("Back", style: .ghost) { app.flow = .photos }
        }
    }

    private var confirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Theme.violet)
            Text("Order placed").font(HUDFont.displayHeavy).foregroundStyle(Theme.textPrimary)
            Text("This is a demo — no payment was charged and no data was sent off-device.")
                .font(HUDFont.body).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
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
