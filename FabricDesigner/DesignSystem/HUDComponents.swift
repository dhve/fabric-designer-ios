import SwiftUI

// MARK: - Corner-bracketed panel

/// Cyberpunk-style panel with bracketed corners and optional scanline overlay.
public struct HUDPanel<Content: View>: View {
    public var tone: Tone = .light
    public var corners: Bool = true
    public var scanlines: Bool = false
    public var padding: CGFloat = 16
    public var content: Content

    public enum Tone { case light, dark, glass }

    public init(
        tone: Tone = .light,
        corners: Bool = true,
        scanlines: Bool = false,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.corners = corners
        self.scanlines = scanlines
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        ZStack {
            background
            content.padding(padding)
            if corners { CornerBrackets(color: bracketColor) }
            if scanlines { ScanlineOverlay().opacity(0.18).allowsHitTesting(false) }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    @ViewBuilder private var background: some View {
        switch tone {
        case .light:
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bone)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.line, lineWidth: 0.5)
                )
        case .dark:
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.carbon)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.lineDark, lineWidth: 0.5)
                )
        case .glass:
            RoundedRectangle(cornerRadius: 4)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.lineDark, lineWidth: 0.5)
                )
        }
    }

    private var bracketColor: Color {
        switch tone {
        case .light: return Theme.onyx
        case .dark, .glass: return Theme.violetGlow
        }
    }
}

public struct CornerBrackets: View {
    public var color: Color = Theme.onyx
    public var inset: CGFloat = 6
    public var arm: CGFloat = 14

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { p in
                // Top-left
                p.move(to: CGPoint(x: inset, y: inset + arm))
                p.addLine(to: CGPoint(x: inset, y: inset))
                p.addLine(to: CGPoint(x: inset + arm, y: inset))
                // Top-right
                p.move(to: CGPoint(x: w - inset - arm, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset + arm))
                // Bottom-left
                p.move(to: CGPoint(x: inset, y: h - inset - arm))
                p.addLine(to: CGPoint(x: inset, y: h - inset))
                p.addLine(to: CGPoint(x: inset + arm, y: h - inset))
                // Bottom-right
                p.move(to: CGPoint(x: w - inset - arm, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset - arm))
            }
            .stroke(color, lineWidth: 1.0)
        }
        .allowsHitTesting(false)
    }
}

public struct ScanlineOverlay: View {
    public var spacing: CGFloat = 3
    public var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    ctx.fill(Path(rect), with: .color(Color.white.opacity(0.5)))
                    y += spacing
                }
            }
            .blendMode(.overlay)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - HUD button

public struct HUDButton: View {
    public enum Style { case primary, secondary, ghost, danger }
    public var title: String
    public var icon: String? = nil
    public var style: Style = .primary
    public var action: () -> Void

    public init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
                Text(title.uppercased())
                    .font(HUDFont.label.monospacedDigit())
                    .tracking(1.4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            LinearGradient(colors: [Theme.violet, Theme.violetDeep], startPoint: .top, endPoint: .bottom)
        case .secondary:
            Theme.onyx
        case .ghost:
            Color.clear
        case .danger:
            Theme.burgundy
        }
    }

    private var foreground: Color {
        switch style {
        case .primary, .secondary, .danger: return Theme.bone
        case .ghost:                        return Theme.onyx
        }
    }

    private var border: Color {
        switch style {
        case .primary: return Theme.violetGlow.opacity(0.8)
        case .secondary, .danger: return .black.opacity(0.6)
        case .ghost: return Theme.onyx
        }
    }
}

// MARK: - Status pill / chip

public struct StatusPill: View {
    public var label: String
    public var color: Color = Theme.violet
    public var icon: String? = nil

    public init(_ label: String, color: Color = Theme.violet, icon: String? = nil) {
        self.label = label
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 9, weight: .heavy)) }
            Text(label.uppercased())
                .font(HUDFont.monoXS)
                .tracking(1.2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .stroke(color.opacity(0.6), lineWidth: 1)
                .background(color.opacity(0.10))
        )
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Telemetry row (label / value)

public struct TelemetryRow: View {
    public var label: String
    public var value: String
    public var unitTone: Color = Theme.violetGlow

    public init(_ label: String, _ value: String, unitTone: Color = Theme.violetGlow) {
        self.label = label
        self.value = value
        self.unitTone = unitTone
    }

    public var body: some View {
        HStack {
            Text(label.uppercased())
                .font(HUDFont.monoXS)
                .tracking(1.4)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(HUDFont.monoLG.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - Grid background (for "future punk corporate" surfaces)

public struct GridBackground: View {
    public var spacing: CGFloat = 24
    public var color: Color = Theme.onyx.opacity(0.05)
    public var body: some View {
        Canvas { ctx, size in
            var x: CGFloat = 0
            while x < size.width {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(color), lineWidth: 0.5)
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(color), lineWidth: 0.5)
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
