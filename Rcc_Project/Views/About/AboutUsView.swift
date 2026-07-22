//
//  AboutUsView.swift
//  RCC Pay
//
//  App and author information. Content is unchanged; the layout now uses the shared
//  card/row vocabulary, and the contact rows are actually actionable — the email
//  address was previously plain text you couldn't do anything with.
//

import SwiftUI

struct AboutUsView: View {

    @EnvironmentObject private var lm: LocalizationManager

    private let contactEmail = "dochkouern@gmail.com"

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Space.lg) {
                    appHero
                    creatorSection
                    appInfoSection
                }
                .padding(.horizontal, DS.Space.page)
                .padding(.top, DS.Space.md)
                .padding(.bottom, DS.Space.xxl)
            }
        }
        .navigationTitle(lm["about_us"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var appHero: some View {
        VStack(spacing: DS.Space.sm) {
            // The app mark, at the size and corner radius iOS uses for an app icon.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.dsBrand)
                .frame(width: 76, height: 76)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text("RCC Pay")
                    .font(.dsTitle)
                    .foregroundStyle(.primary)
                Text("\(lm["version"]) 1.0.0")
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.lg)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Creator

    private var creatorSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            DSGroupCaption(text: lm["creator"])
                .padding(.horizontal, DS.Space.xxs)

            DSGroupedCard {
                HStack(spacing: DS.Space.sm + 2) {
                    DSMonogram(name: "Kouern Doch", size: .lg)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kouern Doch")
                            .font(.dsHeadline)
                            .foregroundStyle(.primary)
                        Text("IT Instructor")
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: DS.Space.xs)

                    VStack(spacing: 0) {
                        Text("24")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.dsBrand)
                        Text("yrs")
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 44, height: 44)
                    .dsAccentSurface(.dsBrand, radius: DS.Radius.xs)
                }
                .padding(DS.Space.md)
                .accessibilityElement(children: .combine)

                DSRowDivider()

                infoRow(
                    icon: "building.2.fill",
                    tint: .dsBrand,
                    label: lm["organization"],
                    value: "Korea Software HRD")

                DSRowDivider()

                // Tapping opens Mail with the address filled in.
                Link(destination: URL(string: "mailto:\(contactEmail)")!) {
                    infoRow(
                        icon: "envelope.fill",
                        tint: .dsSuccess,
                        label: lm["email"],
                        value: contactEmail,
                        showsChevron: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - App description

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            DSGroupCaption(text: lm["about_the_app"])
                .padding(.horizontal, DS.Space.xxs)

            DSCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    HStack(spacing: DS.Space.sm) {
                        DSIconBadge(systemName: "house.fill", tint: .dsBrand)
                        Text("RCC Pay")
                            .font(.dsHeadline)
                    }

                    Text(lm["rcc_pay_description"])
                        .font(.dsSubtext)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(
        icon: String,
        tint: Color,
        label: String,
        value: String,
        showsChevron: Bool = false
    ) -> some View {
        HStack(spacing: DS.Space.sm + 2) {
            DSIconBadge(systemName: icon, tint: tint, size: DS.IconSlot.sm + 4)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: DS.Space.xs)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutUsView()
            .environmentObject(LocalizationManager())
    }
}
