import SwiftUI

/// Cyberpunk results card shown after a successful LiDAR body scan.
/// Lists every dimension, the derived letter size, and lets the user pick
/// cm or inches before they save or rescan.
public struct ScanResultsView: View {
    public let measurements: BodyMeasurements
    @Binding public var unit: LengthUnit
    public let onAccept: () -> Void
    public let onRescan: () -> Void

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55).ignoresSafeArea()
            HUDPanel(tone: .dark, corners: true, scanlines: true, padding: 0) {
                VStack(spacing: 0) {
                    header
                    Divider().background(Theme.lineDark)
                    rows
                    Divider().background(Theme.lineDark)
                    footer
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
        .transition(.move(edge: .bottom))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("BODY DIMENSIONS")
                    .font(HUDFont.monoXS)
                    .tracking(2.0)
                    .foregroundStyle(Theme.violetGlow)
                Text("Scan complete")
                    .font(HUDFont.displayCondensed)
                    .foregroundStyle(Theme.bone)
            }
            Spacer()
            Picker("Unit", selection: $unit) {
                Text("cm").tag(LengthUnit.cm)
                Text("in").tag(LengthUnit.inches)
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
        }
        .padding(16)
    }

    private var rows: some View {
        VStack(spacing: 8) {
            TelemetryRow("Height",        measurements.heightCM.formatted(in: unit))
            TelemetryRow("Shoulder",      measurements.shoulderWidthCM.formatted(in: unit))
            TelemetryRow("Sleeve",        measurements.sleeveLengthCM.formatted(in: unit))
            TelemetryRow("Chest",         measurements.chestCircumferenceCM.formatted(in: unit))
            TelemetryRow("Waist",         measurements.waistCircumferenceCM.formatted(in: unit))
            TelemetryRow("Hip",           measurements.hipCircumferenceCM.formatted(in: unit))
            TelemetryRow("Inseam",        measurements.inseamCM.formatted(in: unit))
            TelemetryRow("Neck",          measurements.neckCircumferenceCM.formatted(in: unit))
            TelemetryRow("Thigh",         measurements.thighCircumferenceCM.formatted(in: unit))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                StatusPill("SIZE \(measurements.derivedSize)", color: Theme.violetGlow, icon: "tshirt")
                Spacer()
                StatusPill("CONFIDENCE \(Int(measurements.confidence * 100))%",
                           color: confidenceColor,
                           icon: "checkmark.seal")
            }
            HStack(spacing: 10) {
                HUDButton("Rescan", icon: "arrow.clockwise", style: .ghost, action: onRescan)
                    .foregroundStyle(Theme.bone)
                HUDButton("Use Dimensions", icon: "checkmark", style: .primary, action: onAccept)
            }
        }
        .padding(16)
    }

    private var confidenceColor: Color {
        switch measurements.confidence {
        case 0.75...:  return Theme.emerald
        case 0.4..<0.75: return Theme.warning
        default:       return Theme.danger
        }
    }
}
