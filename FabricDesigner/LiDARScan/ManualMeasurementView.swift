import SwiftUI

public struct ManualMeasurementView: View {
    private let title: String
    private let prefill: BodyMeasurements
    private let onSave: (BodyMeasurements) -> Void
    private let onCancel: () -> Void

    @State private var draft: BodyMeasurements

    public init(
        title: String = "Manual Measurements",
        prefill: BodyMeasurements? = nil,
        onSave: @escaping (BodyMeasurements) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.prefill = prefill ?? .demo
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: (prefill ?? .demo).withSource(.manual, confidence: 1.0))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    measurementFields
                    validationPanel
                    actions
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Theme.bone.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TAILOR BASELINE")
                .font(HUDFont.monoXS)
                .tracking(2)
                .foregroundStyle(Theme.violet)
            Text("Enter centimetres from a tape measure. Scan values can be used as a starting point, but manual values are the trusted production record.")
                .font(HUDFont.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var measurementFields: some View {
        HUDPanel(tone: .light) {
            VStack(spacing: 10) {
                ForEach(MeasurementRule.all, id: \.label) { rule in
                    MeasurementNumberField(rule: rule, measurements: $draft)
                }
            }
        }
    }

    @ViewBuilder private var validationPanel: some View {
        let issues = draft.validationIssues
        if issues.isEmpty {
            StatusPill("READY FOR ORDER PDF", color: Theme.emerald, icon: "checkmark.seal")
        } else {
            HUDPanel(tone: .light) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FIX MEASUREMENTS")
                        .font(HUDFont.monoXS)
                        .tracking(1.6)
                        .foregroundStyle(Theme.danger)
                    ForEach(issues, id: \.self) { issue in
                        Text(issue)
                            .font(HUDFont.body)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            HUDButton("Save Measurements", icon: "checkmark", style: .primary) {
                onSave(draft.withSource(.manual, confidence: 1.0))
            }
            .disabled(!draft.isTailorReady)
            .opacity(draft.isTailorReady ? 1 : 0.45)
            HUDButton("Reset Prefill", icon: "arrow.counterclockwise", style: .ghost) {
                draft = prefill.withSource(.manual, confidence: 1.0)
            }
        }
    }
}

private struct MeasurementNumberField: View {
    let rule: MeasurementRule
    @Binding var measurements: BodyMeasurements

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.label.uppercased())
                    .font(HUDFont.monoXS)
                    .tracking(1.4)
                    .foregroundStyle(Theme.textSecondary)
                Text("\(Int(rule.range.lowerBound))-\(Int(rule.range.upperBound)) cm")
                    .font(HUDFont.monoXS)
                    .foregroundStyle(rule.contains(value) ? Theme.textSecondary : Theme.danger)
            }
            Spacer()
            TextField("0", value: valueBinding, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(HUDFont.monoLG.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 92)
                .padding(10)
                .background(Theme.canvas)
                .overlay(Rectangle().stroke(rule.contains(value) ? Theme.line : Theme.danger, lineWidth: 0.8))
            Text("cm")
                .font(HUDFont.monoXS)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 24, alignment: .leading)
        }
    }

    private var value: Double {
        measurements[keyPath: rule.keyPath]
    }

    private var valueBinding: Binding<Double> {
        Binding(
            get: { measurements[keyPath: rule.keyPath] },
            set: { measurements[keyPath: rule.keyPath] = $0 }
        )
    }
}
