import SwiftUI

/// Multi-tender payment picker — every method from the PRD:
///   • Electronic transfer
///   • Cash
///   • Crypto / Web3
///   • Store of value (gold / barter / trade)
///   • Credit card — flagged with the 110% return-restocking notice
public struct PaymentMethodPicker: View {
    @Binding public var selection: PaymentMethod

    public init(selection: Binding<PaymentMethod>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYMENT METHOD")
                .font(HUDFont.monoXS).tracking(1.6).foregroundStyle(Theme.violet)
            ForEach(PaymentMethod.allCases) { method in
                methodRow(method)
            }
            if selection.carriesRestockingNotice {
                restockingNotice
            }
        }
    }

    private func methodRow(_ method: PaymentMethod) -> some View {
        let isSelected = selection == method
        return Button {
            selection = method
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: method.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.bone : Theme.violet)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Theme.violet : Theme.canvas)
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(HUDFont.title)
                        .foregroundStyle(Theme.textPrimary)
                    Text(method.subtitle)
                        .font(HUDFont.monoXS)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if method.carriesRestockingNotice {
                    StatusPill("110% RESTOCK", color: Theme.danger, icon: "exclamationmark.triangle.fill")
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.violet : Theme.line)
            }
            .padding(12)
            .background(isSelected ? Theme.canvas : Theme.bone)
            .overlay(
                Rectangle().stroke(isSelected ? Theme.violet : Theme.line, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var restockingNotice: some View {
        HUDPanel(tone: .light) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.danger)
                    Text("CREDIT CARD T&C").font(HUDFont.label).tracking(1.4).foregroundStyle(Theme.danger)
                }
                Text("Credit card payments carry a 110% return restocking fee per the Atelier T&Cs. We accept the card but recommend an alternate tender to keep the cost at face value.")
                    .font(HUDFont.body)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }
}
