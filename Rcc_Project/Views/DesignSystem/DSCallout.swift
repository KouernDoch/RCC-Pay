//
//  DSCallout.swift
//  RCC Pay
//
//  Inline message banners — form errors, confirmations, hints. One component replaces
//  the four near-identical pills that were copy-pasted across the auth screens.
//

import SwiftUI

struct DSCallout: View {

    let message: String
    var tone: DSTone = .danger
    var systemImage: String? = nil
    /// Driven by the parent so a repeated failure re-animates. Pairs with `.dsShake()`.
    var shake: Bool = false

    private var icon: String {
        if let systemImage { return systemImage }
        switch tone {
        case .success: return "checkmark.circle.fill"
        case .danger:  return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .brand:   return "info.circle.fill"
        case .neutral: return "info.circle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.xs + 1) {
            Image(systemName: icon)
                .font(.system(.subheadline))
                .accessibilityHidden(true)

            Text(message)
                .font(.dsSubtext)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.sm)
        .dsAccentSurface(tone.color, radius: DS.Radius.sm, intensity: 0.09)
        .offset(x: shake ? -6 : 0)
        .transition(.scale(scale: 0.97).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        // Errors should interrupt VoiceOver; confirmations shouldn't.
        .accessibilityAddTraits(tone == .danger ? .isStaticText : .isStaticText)
    }
}

// MARK: - Shake

/// Horizontal shake driven by a nonce, for "that credential was wrong" feedback.
/// Skipped entirely under Reduce Motion — the callout still appears, it just doesn't move.
struct DSShakeModifier: ViewModifier {

    let trigger: Int
    @State private var offset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) {
                    offset = -6
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeOut(duration: 0.1)) { offset = 0 }
                }
            }
    }
}

extension View {
    /// Shakes whenever `trigger` changes value.
    func dsShake(on trigger: Int) -> some View {
        modifier(DSShakeModifier(trigger: trigger))
    }
}

// MARK: - Hint row

/// A checklist line — used by the password-rules list on the reset screen.
struct DSRuleRow: View {

    let text: String
    let isSatisfied: Bool

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: isSatisfied ? "checkmark.circle.fill" : "circle")
                .font(.system(.caption))
                .foregroundStyle(isSatisfied ? Color.dsSuccess : Color.secondary.opacity(0.5))
                .contentTransition(.symbolEffect(.replace))

            Text(text)
                .font(.dsCaption)
                .foregroundStyle(isSatisfied ? .primary : .secondary)

            Spacer(minLength: 0)
        }
        .animation(DS.Motion.quick, value: isSatisfied)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSatisfied ? "Met" : "Not met")
    }
}

// MARK: - Strength meter

/// Password strength bar. `fraction` is 0…1; `tone` carries the verdict's colour.
struct DSStrengthMeter: View {

    let label: String
    let fraction: CGFloat
    let tone: DSTone
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs + 1) {
            HStack {
                if let caption {
                    Text(caption)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: DS.Space.xs)
                Text(label)
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(tone.color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(tone.color)
                        .frame(width: max(0, min(1, fraction)) * geo.size.width)
                }
            }
            .frame(height: 5)
            .animation(DS.Motion.smooth, value: fraction)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Password strength")
        .accessibilityValue(label)
    }
}

// MARK: - Preview

#Preview("Callouts") {
    VStack(alignment: .leading, spacing: DS.Space.md) {
        DSCallout(message: "Invalid email or password", tone: .danger)
        DSCallout(message: "Your password has been reset successfully.", tone: .success)
        DSCallout(message: "A new code is on its way to your email.", tone: .brand)

        VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
            DSRuleRow(text: "8–128 characters", isSatisfied: true)
            DSRuleRow(text: "An uppercase and a lowercase letter", isSatisfied: true)
            DSRuleRow(text: "At least one number", isSatisfied: false)
        }

        DSStrengthMeter(label: "Strong", fraction: 1, tone: .success, caption: "Password strength")
    }
    .padding(DS.Space.page)
    .background(Color.dsBackground)
}
