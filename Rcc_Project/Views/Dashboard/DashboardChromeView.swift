//
//  DashboardChromeView.swift
//  Rcc_Project
//
//  Shared top chrome for both dashboards: identity block, quick actions, month rail.
//
//  Same public API as before (`displayName`, `roleSubtitle`, `showMonthSelector`,
//  `onMonthSelected`) so neither ContentView nor AdminTabView needed changing to adopt it.
//

import SwiftUI

struct DashboardChromeView: View {

    @EnvironmentObject private var lm: LocalizationManager

    let displayName: String
    let roleSubtitle: String
    let showMonthSelector: Bool
    let onMonthSelected: (Int) -> Void

    init(
        displayName: String,
        roleSubtitle: String,
        showMonthSelector: Bool = true,
        onMonthSelected: @escaping (Int) -> Void
    ) {
        self.displayName = displayName
        self.roleSubtitle = roleSubtitle
        self.showMonthSelector = showMonthSelector
        self.onMonthSelected = onMonthSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            identityBar
                .padding(.horizontal, DS.Space.page)
                .padding(.top, DS.Space.xs)
                .padding(.bottom, showMonthSelector ? DS.Space.xxs : DS.Space.sm)

            if showMonthSelector {
                DateSelect(onMonthSelected: onMonthSelected)
            }
        }
    }

    // MARK: - Identity + actions

    private var identityBar: some View {
        HStack(spacing: DS.Space.sm) {
            // The whole identity block is one target rather than just the avatar —
            // a 44pt-plus hit area, per HIG, instead of the previous small circle.
            NavigationLink(destination: ProfileView()) {
                HStack(spacing: DS.Space.xs + 2) {
                    DSSelfAvatar(size: .sm)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayName)
                            .font(.dsHeadline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(roleSubtitle)
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(DSPressStyle(scale: 0.98, haptics: false))
            .accessibilityLabel("\(displayName), \(roleSubtitle)")
            .accessibilityHint("Opens your profile")

            Spacer(minLength: DS.Space.xs)

            HStack(spacing: DS.Space.xs) {
                NavigationLink(destination: NotificationView()) {
                    chromeGlyph("bell")
                }
                .accessibilityLabel(lm["notifications"])

                NavigationLink(destination: ProfileView()) {
                    chromeGlyph("gearshape")
                }
                .accessibilityLabel(lm["settings"])
            }
        }
    }

    /// Matches `DSIconButton`'s look, but as a `NavigationLink` label rather than a Button.
    private func chromeGlyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.dsSurface))
            .overlay(Circle().strokeBorder(Color.dsHairline, lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            DashboardChromeView(
                displayName: "Leng Chingmony",
                roleSubtitle: "Normal User",
                onMonthSelected: { _ in })
            Spacer()
        }
        .background(Color.dsBackground)
    }
    .environmentObject(LocalizationManager())
    .environmentObject(SessionStore())
}
