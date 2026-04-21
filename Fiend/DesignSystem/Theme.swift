import SwiftUI

/// Central design tokens. Kept as plain Swift so we can later swap in
/// an asset catalog-driven theme or a remote config without changing call sites.
enum Theme {
    // Palette: deep blues, soft greens, warm neutrals
    static let primary = Color(red: 0.11, green: 0.31, blue: 0.49)        // deep blue
    static let primaryDeep = Color(red: 0.05, green: 0.18, blue: 0.33)
    static let accent = Color(red: 0.40, green: 0.72, blue: 0.60)         // soft green
    static let warning = Color(red: 0.86, green: 0.47, blue: 0.35)        // warm coral
    static let danger = Color(red: 0.78, green: 0.32, blue: 0.32)
    static let surface = Color(.systemBackground)
    static let surfaceRaised = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let onSurface = Color(.label)
    static let onSurfaceMuted = Color(.secondaryLabel)

    // Intensity ramp (1..5) for charts + chips
    static func intensityColor(_ level: Int) -> Color {
        switch level {
        case ..<2: return Color(red: 0.40, green: 0.72, blue: 0.60)
        case 2:    return Color(red: 0.56, green: 0.76, blue: 0.55)
        case 3:    return Color(red: 0.92, green: 0.76, blue: 0.40)
        case 4:    return Color(red: 0.90, green: 0.55, blue: 0.35)
        default:   return Color(red: 0.80, green: 0.30, blue: 0.30)
        }
    }

    // Spacing
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // Corner radius
    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 14
        static let l: CGFloat = 22
    }
}

// MARK: - Card container

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Space.m)
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
    }
}

// MARK: - Primary button

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 56)
            .font(.headline)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.85 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 48)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.primary)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Theme.primary.opacity(configuration.isPressed ? 0.18 : 0.12))
            )
    }
}
