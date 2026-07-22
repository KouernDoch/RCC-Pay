//
//  DSButtons.swift
//  RCC Pay
//
//  Four button roles — primary, secondary, tertiary, destructive — plus the
//  floating action button. Solid fills rather than gradients: a gradient on a
//  control this small reads as noise, and it makes the disabled state muddy.
//

import SwiftUI

// MARK: - Press feedback

/// Scale-on-press plus a light haptic. Applied by every DS button style, and
/// available on its own for bespoke tappable surfaces (cards, chips, tiles).
struct DSPressStyle: ButtonStyle {

    var scale: CGFloat = 0.97
    var haptics: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(DS.Motion.quick, value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: haptics && configuration.isPressed)
    }
}

// MARK: - Role

enum DSButtonRole {
    case primary, secondary, tertiary, destructive

    var foreground: Color {
        switch self {
        case .primary:     return .white
        case .secondary:   return .dsBrand
        case .tertiary:    return .dsBrand
        case .destructive: return .dsDanger
        }
    }

    var background: Color {
        switch self {
        case .primary:     return .dsBrand
        case .secondary:   return .dsBrand.opacity(0.12)
        case .tertiary:    return .clear
        case .destructive: return .dsDanger.opacity(0.12)
        }
    }

    var border: Color {
        switch self {
        case .primary:     return .clear
        case .secondary:   return .dsBrand.opacity(0.22)
        case .tertiary:    return .clear
        case .destructive: return .dsDanger.opacity(0.22)
        }
    }

    /// Only the primary button earns a shadow — it's the one thing on screen that
    /// should look like it's floating above the content.
    var elevation: DS.Elevation {
        self == .primary ? .low : .none
    }
}

// MARK: - Button style

struct DSButtonStyle: ButtonStyle {

    var role: DSButtonRole = .primary
    var fullWidth: Bool = true
    var compact: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme

    private var verticalPadding: CGFloat { compact ? DS.Space.xs + 2 : DS.Space.sm + 2 }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsButton)
            .foregroundStyle(isEnabled ? role.foreground : Color.secondary)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, compact ? DS.Space.sm : DS.Space.md)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: compact ? 36 : 50)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(isEnabled ? role.background : Color(.systemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .strokeBorder(isEnabled ? role.border : .clear, lineWidth: 1)
            )
            .shadow(
                color: scheme == .dark || !isEnabled
                    ? .clear
                    : Color.dsBrand.opacity(role == .primary ? 0.25 : 0),
                radius: role.elevation.radius,
                x: 0,
                y: role.elevation.y)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DS.Motion.quick, value: configuration.isPressed)
            .animation(DS.Motion.fade, value: isEnabled)
            .sensoryFeedback(.selection, trigger: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DSButtonStyle {
    static var dsPrimary: DSButtonStyle { DSButtonStyle(role: .primary) }
    static var dsSecondary: DSButtonStyle { DSButtonStyle(role: .secondary) }
    static var dsTertiary: DSButtonStyle { DSButtonStyle(role: .tertiary) }
    static var dsDestructive: DSButtonStyle { DSButtonStyle(role: .destructive) }

    static func ds(_ role: DSButtonRole, fullWidth: Bool = true, compact: Bool = false) -> DSButtonStyle {
        DSButtonStyle(role: role, fullWidth: fullWidth, compact: compact)
    }
}

// MARK: - Convenience button

/// A labelled button with a built-in loading state. The spinner replaces the label
/// in place rather than resizing the button, so the layout never jumps mid-request.
struct DSButton: View {

    let title: String
    var systemImage: String? = nil
    var role: DSButtonRole = .primary
    var fullWidth: Bool = true
    var compact: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Kept in the layout (hidden, not removed) so the button holds its width.
                label.opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(role == .primary ? .white : .dsBrand)
                        .controlSize(.small)
                }
            }
        }
        .buttonStyle(DSButtonStyle(role: role, fullWidth: fullWidth, compact: compact))
        .disabled(isLoading)
        .animation(DS.Motion.fade, value: isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? Text("In progress") : Text(""))
    }

    private var label: some View {
        HStack(spacing: DS.Space.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(.subheadline, weight: .semibold))
            }
            Text(title)
        }
    }
}

// MARK: - Floating action button

/// Circular FAB for the single most important action on a scrolling screen.
struct DSFloatingActionButton: View {

    let systemImage: String
    var title: String? = nil
    var tint: Color = .dsBrand
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: systemImage)
                    .font(.system(.body, weight: .semibold))
                if let title {
                    Text(title).font(.dsButton)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, title == nil ? DS.Space.md : DS.Space.lg)
            .frame(height: 54)
            .frame(minWidth: 54)
            .background(Capsule().fill(tint))
            .shadow(
                color: scheme == .dark ? .clear : tint.opacity(0.35),
                radius: 16, x: 0, y: 8)
        }
        .buttonStyle(DSPressStyle(scale: 0.94))
        .accessibilityLabel(title ?? systemImage)
    }
}

// MARK: - Icon button

/// The circular glyph button used in headers (bell, gear, close).
struct DSIconButton: View {

    let systemName: String
    var size: CGFloat = 38
    var tint: Color = .primary
    var badge: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.dsSurfaceSunken))
                .overlay(alignment: .topTrailing) {
                    if let badge, badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 17, minHeight: 17)
                            .background(Capsule().fill(Color.dsDanger))
                            .overlay(Capsule().strokeBorder(Color.dsBackground, lineWidth: 1.5))
                            .offset(x: 4, y: -3)
                    }
                }
        }
        .buttonStyle(DSPressStyle(scale: 0.9))
    }
}

// MARK: - Preview

#Preview("Buttons") {
    ScrollView {
        VStack(spacing: DS.Space.md) {
            DSButton(title: "Pay via QR Code", systemImage: "qrcode.viewfinder") {}
            DSButton(title: "Loading", systemImage: "arrow.clockwise", isLoading: true) {}
            DSButton(title: "Update Manually", systemImage: "square.and.pencil", role: .secondary) {}
            DSButton(title: "Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {}
            DSButton(title: "Disabled") {}.disabled(true)

            HStack(spacing: DS.Space.sm) {
                DSButton(title: "Compact", role: .secondary, fullWidth: false, compact: true) {}
                DSIconButton(systemName: "bell", badge: 3) {}
                DSIconButton(systemName: "gearshape") {}
                Spacer()
                DSFloatingActionButton(systemImage: "plus") {}
            }
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
}
