//
//  DSStats.swift
//  RCC Pay
//
//  Figure display. `DSStatStrip` is the divided row used on the monthly bill and the
//  invoice card; `DSStatTile` is the standalone tile used on the admin overview.
//

import SwiftUI

// MARK: - Stat model

struct DSStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var tone: DSTone = .neutral
    var systemImage: String? = nil
}

// MARK: - Strip

/// Two or three figures side by side, separated by hairlines. Values animate with
/// `.numericText()` so a refreshed total rolls rather than snapping.
struct DSStatStrip: View {

    let stats: [DSStat]
    var valueFont: Font = .system(.headline, design: .rounded, weight: .bold)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                VStack(spacing: DS.Space.xxs + 1) {
                    Text(stat.value)
                        .font(valueFont)
                        .monospacedDigit()
                        .foregroundStyle(stat.tone.color)
                        .contentTransition(.numericText())
                        .dsNumeric()

                    Text(stat.label)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(stat.label): \(stat.value)")

                if index < stats.count - 1 {
                    Rectangle()
                        .fill(Color.dsSeparator.opacity(0.4))
                        .frame(width: 1, height: 30)
                }
            }
        }
        // Three fixed columns can't reflow, so growth is capped rather than clipped.
        .dsDenseLayout()
        .animation(DS.Motion.smooth, value: stats.map(\.value))
    }
}

// MARK: - Tile

/// A single figure in its own tinted card. Reads well in a row of three on the
/// admin overview, and stacks into two columns on narrow width.
struct DSStatTile: View {

    let stat: DSStat

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
            if let icon = stat.systemImage {
                Image(systemName: icon)
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(stat.tone.color)
                    .accessibilityHidden(true)
            }

            Text(stat.value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(stat.tone.color)
                .contentTransition(.numericText())
                .dsNumeric()

            Text(stat.label)
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.sm)
        .dsAccentSurface(stat.tone.color, radius: DS.Radius.sm, intensity: 0.09)
        .dsDenseLayout()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.label): \(stat.value)")
    }
}

/// A row of tiles that reflows to a grid when the text gets large.
struct DSStatTileRow: View {

    let stats: [DSStat]

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize >= .accessibility1 {
            // Side-by-side tiles stop working once labels wrap to three lines.
            VStack(spacing: DS.Space.xs) {
                ForEach(stats) { DSStatTile(stat: $0) }
            }
        } else {
            HStack(spacing: DS.Space.xs) {
                ForEach(stats) { DSStatTile(stat: $0) }
            }
        }
    }
}

// MARK: - Key/value row

/// A labelled figure on its own line — used inside detail cards.
struct DSMetricRow: View {

    let label: String
    let value: String
    var tone: DSTone = .neutral
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(.dsSubtext)
                .foregroundStyle(.secondary)
            Spacer(minLength: DS.Space.xs)
            Text(value)
                .font(.system(.subheadline, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(tone == .neutral ? .primary : tone.color)
                .dsNumeric()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("Stats") {
    VStack(spacing: DS.Space.md) {
        DSCard {
            DSStatStrip(stats: [
                DSStat(label: "Total Due", value: "$38.00", tone: .brand),
                DSStat(label: "Remain",    value: "$18.00", tone: .warning),
                DSStat(label: "Paid",      value: "$20.00", tone: .success),
            ])
        }

        DSStatTileRow(stats: [
            DSStat(label: "Total users", value: "24", tone: .brand,   systemImage: "person.3.fill"),
            DSStat(label: "Paid",        value: "18", tone: .success, systemImage: "checkmark.seal.fill"),
            DSStat(label: "Unpaid",      value: "6",  tone: .warning, systemImage: "exclamationmark.triangle.fill"),
        ])

        DSCard {
            VStack(spacing: DS.Space.xs) {
                DSMetricRow(label: "Invoice no.", value: "INV-2026-01-004")
                DSMetricRow(label: "Remaining", value: "$18.00", tone: .warning)
            }
        }
    }
    .padding(DS.Space.page)
    .background(Color.dsBackground)
}
