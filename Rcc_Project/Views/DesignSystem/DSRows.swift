//
//  DSRows.swift
//  RCC Pay
//
//  The two row shapes the app repeats everywhere:
//
//   • `DSPersonRow`   — avatar, name, subtitle, trailing accessory. Payment feeds,
//                       resident lists, notification senders.
//   • `DSSettingsRow` — icon tile, label, value, chevron. The Apple Settings row.
//

import SwiftUI

// MARK: - Person row

struct DSPersonRow<Trailing: View>: View {

    let name: String
    var subtitle: String? = nil
    var imageURL: String? = nil
    var placeholder: String = "Profile"
    var avatarSize: DSAvatarSize = .md
    var ring: Color? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            DSAvatar(urlString: imageURL, size: avatarSize, placeholder: placeholder, ring: ring)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.dsHeadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: DS.Space.xs)

            trailing
        }
        .accessibilityElement(children: .combine)
    }
}

extension DSPersonRow where Trailing == EmptyView {
    init(
        name: String,
        subtitle: String? = nil,
        imageURL: String? = nil,
        placeholder: String = "Profile",
        avatarSize: DSAvatarSize = .md,
        ring: Color? = nil
    ) {
        self.init(
            name: name,
            subtitle: subtitle,
            imageURL: imageURL,
            placeholder: placeholder,
            avatarSize: avatarSize,
            ring: ring,
            trailing: { EmptyView() })
    }
}

/// A `DSPersonRow` already wrapped in a card — the payment-feed cell.
struct DSPersonCard<Trailing: View>: View {

    let name: String
    var subtitle: String? = nil
    var imageURL: String? = nil
    var placeholder: String = "Profile"
    @ViewBuilder var trailing: Trailing

    var body: some View {
        DSPersonRow(
            name: name,
            subtitle: subtitle,
            imageURL: imageURL,
            placeholder: placeholder,
            avatarSize: .sm,
            trailing: { trailing })
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.xs + 2)
        .dsSurface(radius: DS.Radius.md, elevation: .low)
    }
}

// MARK: - Settings row

struct DSSettingsRow: View {

    let title: String
    let systemImage: String
    var iconTint: Color = .dsBrand
    /// Right-aligned current value ("English", "Dark").
    var value: String? = nil
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: DS.Space.sm + 2) {
            DSIconBadge(systemName: systemImage, tint: iconTint, size: DS.IconSlot.md, style: .filled)

            Text(title)
                .font(.dsBody)
                .foregroundStyle(.primary)

            Spacer(minLength: DS.Space.xs)

            if let value {
                Text(value)
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm + 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Settings row whose accessory is a switch.
struct DSToggleRow: View {

    let title: String
    let systemImage: String
    var iconTint: Color = .dsBrand
    /// Glyph shown when the toggle is off — usually the "slash" variant.
    var offImage: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: DS.Space.sm + 2) {
            DSIconBadge(
                systemName: isOn ? systemImage : (offImage ?? systemImage),
                tint: isOn ? iconTint : .dsNeutral,
                size: DS.IconSlot.md,
                style: .filled)
            .animation(DS.Motion.fade, value: isOn)

            Text(title)
                .font(.dsBody)
                .foregroundStyle(.primary)

            Spacer(minLength: DS.Space.xs)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconTint)
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.xs + 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

/// Settings row whose accessory is an editable amount.
struct DSAmountRow: View {

    let title: String
    let systemImage: String
    var iconTint: Color = .dsBrand
    var prefix: String = "$"
    @Binding var amount: String

    var body: some View {
        HStack(spacing: DS.Space.sm + 2) {
            DSIconBadge(systemName: systemImage, tint: iconTint, size: DS.IconSlot.md, style: .filled)

            Text(title)
                .font(.dsBody)
                .foregroundStyle(.primary)

            Spacer(minLength: DS.Space.xs)

            HStack(spacing: 2) {
                Text(prefix)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.subheadline, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 74)
            }
            .padding(.horizontal, DS.Space.xs)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xs, style: .continuous)
                    .fill(Color.dsSurfaceSunken)
            )
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.xs + 2)
    }
}

// MARK: - Preview

#Preview("Rows") {
    ScrollView {
        VStack(spacing: DS.Space.md) {
            DSPersonCard(name: "Leng Chingmony", subtitle: "01 Jan, 2026") {
                DSAmountPill(amount: "38.00")
            }

            DSGroupedCard {
                DSSettingsRow(title: "Edit Profile", systemImage: "person.text.rectangle.fill",
                              iconTint: .dsBrand)
                DSRowDivider()
                DSToggleRow(title: "Notification", systemImage: "bell.fill",
                            iconTint: .dsDanger, offImage: "bell.slash.fill",
                            isOn: .constant(true))
                DSRowDivider()
                DSSettingsRow(title: "Language", systemImage: "globe",
                              iconTint: .dsSuccess, value: "English")
                DSRowDivider()
                DSAmountRow(title: "Full Payment", systemImage: "dollarsign.circle.fill",
                            iconTint: .dsSuccess, amount: .constant("38.00"))
            }
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
}
