//
//  FPDesignKit.swift
//  RCC Pay
//
//  Shared chrome for the forgot-password flow. This styling used to be inlined in
//  ForgotPasswordView; it lives here so all four step screens render identical field
//  rows, buttons and banners without copy-paste drift.
//

import SwiftUI

// MARK: - Palette

/// The auth-screen palette. Base hues are shared with LoginView / SignUpView; the
/// instance members resolve the light/dark variants.
struct FPPalette {

    static let navy = Color(red: 0.05, green: 0.15, blue: 0.55)
    static let blue = Color(red: 0.16, green: 0.44, blue: 0.96)
    static let sky  = Color(red: 0.48, green: 0.72, blue: 1.00)

    let isDark: Bool

    init(_ scheme: ColorScheme) { isDark = scheme == .dark }

    var titleGradient: LinearGradient {
        isDark
        ? LinearGradient(colors: [Color(red: 0.60, green: 0.82, blue: 1.00), .white],
                         startPoint: .leading, endPoint: .trailing)
        : LinearGradient(colors: [Color(red: 0.08, green: 0.20, blue: 0.60), Self.blue],
                         startPoint: .leading, endPoint: .trailing)
    }

    var subtitleColor: Color {
        isDark ? Color(red: 0.55, green: 0.78, blue: 1.00) : Self.blue.opacity(0.6)
    }

    var linkColor: Color { isDark ? Self.sky : Self.blue }

    var pageBackground: LinearGradient {
        LinearGradient(
            colors: isDark
                ? [Color(red: 0.04, green: 0.07, blue: 0.16),
                   Color(red: 0.07, green: 0.11, blue: 0.24)]
                : [Color(red: 0.88, green: 0.94, blue: 1.00),
                   Color(red: 0.94, green: 0.97, blue: 1.00)],
            startPoint: .top, endPoint: .bottom)
    }

    var accentBar: LinearGradient {
        LinearGradient(colors: [Self.blue, Self.sky], startPoint: .top, endPoint: .bottom)
    }

    var buttonFill: LinearGradient {
        LinearGradient(colors: [Self.blue, Self.sky],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Section heading

/// The accent bar + title + subtitle block that opens each step.
struct FPHeading: View {
    let title: String
    let subtitle: String
    let palette: FPPalette

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(palette.accentBar)
                .frame(width: 4, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.titleGradient)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(palette.subtitleColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Field container

/// The rounded, gradient-stroked card that wraps one or more field rows.
struct FPFieldContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [FPPalette.blue.opacity(0.20), FPPalette.blue.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)
            )
            .shadow(color: FPPalette.blue.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

/// The circular icon badge that leads every field row.
struct FPFieldIcon: View {
    let systemName: String
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(FPPalette.blue.opacity(isActive ? 0.15 : 0.07))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? FPPalette.blue : FPPalette.blue.opacity(0.5))
        }
    }
}

/// Padding + focus tint shared by every field row.
struct FPFieldRowStyle: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .background(isActive ? FPPalette.blue.opacity(0.05) : Color.clear)
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
        Button { isRevealed.toggle() } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(size: 15))
                .foregroundColor(Color.secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Message banners

/// Red error pill. `shake` is driven by the parent so the offset animates on each failure.
struct FPErrorBanner: View {
    let message: String
    var shake: Bool = false

    var body: some View {
        FPBanner(message: message,
                 systemImage: "exclamationmark.circle.fill",
                 tint: .red)
            .offset(x: shake ? -6 : 0)
    }
}

/// Green confirmation pill (e.g. "a new code is on its way").
struct FPInfoBanner: View {
    let message: String

    var body: some View {
        FPBanner(message: message,
                 systemImage: "checkmark.circle.fill",
                 tint: .green)
    }
}

private struct FPBanner: View {
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage).font(.system(size: 15))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tint.opacity(0.18), lineWidth: 1))
        )
        .transition(.scale(scale: 0.97).combined(with: .opacity))
    }
}

// MARK: - Primary button

/// The 56pt gradient call-to-action, with the blurred glow it has on the other auth screens.
struct FPPrimaryButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    var isLoading: Bool = false
    let palette: FPPalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isEnabled && !isLoading {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [FPPalette.blue.opacity(0.45), FPPalette.sky.opacity(0.3)],
                                startPoint: .leading, endPoint: .trailing))
                        .blur(radius: 14)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled
                        ? AnyShapeStyle(palette.buttonFill)
                        : AnyShapeStyle(Color(.systemFill)))
                    .frame(height: 56)

                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    HStack(spacing: 10) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: systemImage).font(.system(size: 18))
                    }
                    .foregroundColor(isEnabled ? .white : Color.primary.opacity(0.25))
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(FPPressStyle())
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Button style

struct FPPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Wave shape

/// Curved bottom edge of the blue header.
struct FPBottomWave: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - 30))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 30),
            control: CGPoint(x: rect.width / 2, y: rect.height + 40))
        p.closeSubpath()
        return p
    }
}
