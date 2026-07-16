//
//  DashboardChromeView.swift
//  Rcc_Project
//
//  Shared top header + month strip (matches user home chrome).
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
            HStack(spacing: 12) {
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 10) {
                        ProfileAvatarView(size: 42)
                            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primary)
                            Text(roleSubtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .foregroundStyle(Color.primary)

                Spacer()

                HStack(spacing: 6) {
                    NavigationLink(destination: NotificationView()) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 6)

            if showMonthSelector {
                DateSelect { month in
                    onMonthSelected(month)
                }
            }
        }
    }
}
