//
//  DSSectionHeader.swift
//  RCC Pay
//
//  Two header shapes: the accent-bar header that opens a content section, and the
//  quiet uppercase caption that labels a group of settings rows.
//

import SwiftUI

// MARK: - Section header

struct DSSectionHeader<Trailing: View>: View {

    let title: String
    var subtitle: String? = nil
    var tone: DSTone = .brand
    /// Set while the section's data is refreshing — shows an inline spinner.
    var isLoading: Bool = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.xs) {
            Capsule()
                .fill(tone.color)
                .frame(width: 3, height: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }

            if isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .padding(.leading, DS.Space.xxs)
                    .transition(.opacity)
            }

            Spacer(minLength: DS.Space.xs)

            trailing
        }
        .animation(DS.Motion.fade, value: isLoading)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

extension DSSectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, tone: DSTone = .brand, isLoading: Bool = false) {
        self.init(
            title: title,
            subtitle: subtitle,
            tone: tone,
            isLoading: isLoading,
            trailing: { EmptyView() })
    }
}

// MARK: - Group caption

/// The quiet uppercase label above a settings group.
struct DSGroupCaption: View {

    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption2, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Screen title

/// Large title for screens that hide the navigation bar and draw their own header.
struct DSScreenTitle<Trailing: View>: View {

    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsTitle)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.dsSubtext)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: DS.Space.xs)
            trailing
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

extension DSScreenTitle where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}

// MARK: - Preview

#Preview("Headers") {
    VStack(alignment: .leading, spacing: DS.Space.lg) {
        DSScreenTitle(title: "Notifications", subtitle: "3 unread") {
            Button("Mark all read") {}.font(.dsSubtext)
        }
        DSSectionHeader(title: "Daily Payment", isLoading: true) {
            Text("See all").font(.dsCaption).foregroundStyle(Color.dsBrand)
        }
        DSSectionHeader(title: "Paid this month", subtitle: "18 / 24", tone: .success)
        DSGroupCaption(text: "Preference")
    }
    .padding(DS.Space.page)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.dsBackground)
}
