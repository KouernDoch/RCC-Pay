//
//  DSBadges.swift
//  RCC Pay
//
//  Status pills. One component covers every "Paid / Unpaid / Pending" chip in the app,
//  so a status never renders one way on the invoice card and another way on the bill.
//

import SwiftUI

// MARK: - Tone

/// The semantic vocabulary for status. Screens map their domain enum onto a tone
/// rather than picking colours, which is how the same status stays the same colour
/// on every screen.
enum DSTone {
    case brand, success, warning, danger, neutral

    var color: Color {
        switch self {
        case .brand:   return .dsBrand
        case .success: return .dsSuccess
        case .warning: return .dsWarning
        case .danger:  return .dsDanger
        case .neutral: return .dsNeutral
        }
    }
}

// MARK: - Status badge

struct DSStatusBadge: View {

    let text: String
    var tone: DSTone = .neutral
    /// Leading dot. Drop it when the badge sits in a dense row and the colour alone reads.
    var showsDot: Bool = true
    /// Trailing chevron, for badges that open a menu.
    var isInteractive: Bool = false
    var size: Size = .regular

    enum Size {
        case regular, small

        var font: Font { self == .regular ? .dsMicro : .system(.caption2, weight: .semibold) }
        var hPadding: CGFloat { self == .regular ? DS.Space.sm - 2 : DS.Space.xs }
        var vPadding: CGFloat { self == .regular ? 6 : 4 }
    }

    var body: some View {
        HStack(spacing: DS.Space.xxs + 1) {
            if showsDot {
                Circle()
                    .fill(tone.color)
                    .frame(width: 6, height: 6)
            }
            Text(text)
                .font(size.font)
                .lineLimit(1)
            if isInteractive {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, size.hPadding)
        .padding(.vertical, size.vPadding)
        .background(Capsule().fill(tone.color.opacity(0.13)))
        .overlay(Capsule().strokeBorder(tone.color.opacity(0.18), lineWidth: 0.5))
        // The dot is decorative; the colour is already carried by the label's meaning.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Count badge

/// Small numeric badge — unread counts, filter result counts.
struct DSCountBadge: View {

    let count: Int
    var tone: DSTone = .brand
    var isInverted: Bool = false

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(.caption2, weight: .bold))
            .foregroundStyle(isInverted ? tone.color : .white)
            .padding(.horizontal, 6)
            .frame(minWidth: 20, minHeight: 20)
            .background(Capsule().fill(isInverted ? Color.white : tone.color))
            .accessibilityLabel("\(count)")
    }
}

// MARK: - Value pill

/// The amount chip on a payment row. Monospaced digits so a column of them
/// lines up on the decimal point.
struct DSAmountPill: View {

    let amount: String
    var tone: DSTone = .success
    var prefix: String = "$"

    var body: some View {
        Text("\(prefix)\(amount)")
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(tone.color)
            .dsNumeric()
            .padding(.horizontal, DS.Space.xs + 2)
            .padding(.vertical, 5)
            .background(Capsule().fill(tone.color.opacity(0.12)))
    }
}

// MARK: - Preview

#Preview("Badges") {
    VStack(alignment: .leading, spacing: DS.Space.md) {
        HStack(spacing: DS.Space.xs) {
            DSStatusBadge(text: "Paid", tone: .success)
            DSStatusBadge(text: "Unpaid", tone: .warning)
            DSStatusBadge(text: "Pending", tone: .neutral)
        }
        HStack(spacing: DS.Space.xs) {
            DSStatusBadge(text: "Partially paid", tone: .brand, isInteractive: true)
            DSStatusBadge(text: "Overdue", tone: .danger, size: .small)
        }
        HStack(spacing: DS.Space.xs) {
            DSCountBadge(count: 3)
            DSCountBadge(count: 128, tone: .danger)
            DSAmountPill(amount: "38.00")
            DSAmountPill(amount: "19.00", tone: .warning)
        }
    }
    .padding(DS.Space.page)
    .background(Color.dsBackground)
}
