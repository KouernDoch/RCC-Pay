//
//  FPDesignKit.swift
//  RCC Pay
//
//  Shared chrome for the forgot-password flow.
//
//  These types keep the exact same names and signatures they had before, so the four
//  step views did not have to be restructured to adopt the new look. Internally they
//  are now thin adapters over the app-wide design system — `FPPrimaryButton` is a
//  `DSButton`, `FPErrorBanner` is a `DSCallout`, and the palette resolves to the same
//  `Color.dsBrand` every other screen uses.
//
//  The multi-stop gradients, blurred button glow and wave shape are gone; `FPBottomWave`
//  was removed along with them, since `AuthScaffold` now draws the header for all three
//  auth screens.
//

import SwiftUI

// MARK: - Palette

/// Retained as the flow's colour vocabulary, but every value now resolves to a
/// design-system token rather than its own hard-coded RGB.
struct FPPalette {

    static let navy = Color.dsBrand
    static let blue = Color.dsBrand
    static let sky  = Color.dsBrandSoft

    let isDark: Bool

    init(_ scheme: ColorScheme) { isDark = scheme == .dark }

    /// Flat rather than gradient now — a gradient on 22pt text was doing nothing but
    /// costing contrast.
    var titleGradient: LinearGradient {
        LinearGradient(colors: [.primary, .primary], startPoint: .leading, endPoint: .trailing)
    }

    var subtitleColor: Color { .secondary }

    var linkColor: Color { .dsBrand }

    var pageBackground: LinearGradient {
        LinearGradient(colors: [.dsBackground, .dsBackground], startPoint: .top, endPoint: .bottom)
    }

    var accentBar: LinearGradient {
        LinearGradient(colors: [.dsBrand, .dsBrand], startPoint: .top, endPoint: .bottom)
    }

    var buttonFill: LinearGradient {
        LinearGradient(colors: [.dsBrand, .dsBrand], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Section heading

/// The accent bar + title + subtitle block that opens each step.
struct FPHeading: View {
    let title: String
    let subtitle: String
    let palette: FPPalette

    var body: some View {
        AuthHeading(title: title, subtitle: subtitle)
    }
}

// MARK: - Field container

/// The rounded card that wraps one or more field rows.
struct FPFieldContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        DSFieldGroup { content }
    }
}

/// The circular icon badge that leads every field row.
struct FPFieldIcon: View {
    let systemName: String
    let isActive: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(isActive ? Color.dsBrand : Color.secondary)
            .frame(width: DS.IconSlot.md, height: DS.IconSlot.md)
            .background(Circle().fill(Color.dsBrand.opacity(isActive ? 0.14 : 0.07)))
            .accessibilityHidden(true)
    }
}

/// Padding + focus tint shared by every field row.
struct FPFieldRowStyle: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.sm + 2)
            .background(isActive ? Color.dsBrand.opacity(0.06) : Color.clear)
            .animation(DS.Motion.fade, value: isActive)
    }
}

extension View {
    func fpFieldRow(isActive: Bool) -> some View {
        modifier(FPFieldRowStyle(isActive: isActive))
    }
}

/// Eye toggle for secure fields.
struct FPRevealButton: View {
    @Binding var isRevealed: Bool

    var body: some View {
        Button {
            withAnimation(DS.Motion.fade) { isRevealed.toggle() }
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(.footnote))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
    }
}

// MARK: - Message banners

/// Red error pill. `shake` is driven by the parent so the offset animates on each failure.
struct FPErrorBanner: View {
    let message: String
    var shake: Bool = false

    var body: some View {
        DSCallout(message: message, tone: .danger, shake: shake)
    }
}

/// Green confirmation pill (e.g. "a new code is on its way").
struct FPInfoBanner: View {
    let message: String

    var body: some View {
        DSCallout(message: message, tone: .success)
    }
}

// MARK: - Primary button

struct FPPrimaryButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    var isLoading: Bool = false
    let palette: FPPalette
    let action: () -> Void

    var body: some View {
        DSButton(
            title: title,
            systemImage: systemImage,
            role: .primary,
            isLoading: isLoading,
            action: action)
        .disabled(!isEnabled)
    }
}

// MARK: - Button style

struct FPPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        DSPressStyle().makeBody(configuration: configuration)
    }
}
