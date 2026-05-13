//
//  NotificationView.swift
//  RCC Pay
//
//  Created by HRD on 1/8/26.
//

import SwiftUI

// MARK: - Model

struct NotificationModel: Identifiable {
    let id = UUID()
    var image: String
    var userName: String
    var payMonth: String
    var transactionDate: String
    var amount: String
    var isRead: Bool
}

// MARK: - Filter

enum NotifFilter: String, CaseIterable {
    case all    = "all"
    case unread = "unread"
}

// MARK: - Card

struct NotificationCard: View {
    let item: NotificationModel

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private let mint = Color(red: 0.18, green: 0.75, blue: 0.48)

    var body: some View {
        HStack(spacing: 14) {

            // Profile photo + unread badge
            ZStack(alignment: .bottomTrailing) {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGroupedBackground), lineWidth: 2)
                    )

                if !item.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 13, height: 13)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {

                // Name + amount
                HStack(alignment: .firstTextBaseline) {
                    Text(item.userName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("$\(item.amount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(mint)
                }

                // Pay month
                Text("\(lm["monthly_bill"]) · \(item.payMonth)")
                    .font(.system(size: 13))
                    .foregroundColor(item.isRead ? .secondary : .blue)

                // Transaction date
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(item.transactionDate)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(item.isRead
                      ? Color(.systemBackground)
                      : Color(.systemBlue).opacity(colorScheme == .dark ? 0.15 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    item.isRead
                        ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear)
                        : Color.blue.opacity(colorScheme == .dark ? 0.4 : 0.15),
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark ? .clear : (item.isRead ? Color.black.opacity(0.05) : Color.blue.opacity(0.1)),
            radius: item.isRead ? 6 : 12, x: 0, y: item.isRead ? 2 : 5
        )
    }
}

// MARK: - Empty State

struct NotifEmptyState: View {
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.07))
                    .frame(width: 86, height: 86)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.blue.opacity(0.3))
            }
            Text(lm["no_notifications"])
                .font(.system(size: 17, weight: .semibold))
            Text(lm["all_caught_up"])
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Main View

struct NotificationView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: NotifFilter = .all
    @State private var notifications: [NotificationModel] = [
        NotificationModel(image: "Profile", userName: "Kouern Doch",    payMonth: "March 2026",    transactionDate: "20 Mar 2026  ·  09:30 AM", amount: "150.00", isRead: false),
        NotificationModel(image: "Profile", userName: "Leng Chingmony", payMonth: "March 2026",    transactionDate: "19 Mar 2026  ·  02:15 PM", amount: "150.00", isRead: false),
        NotificationModel(image: "Profile", userName: "Kouern Doch",    payMonth: "February 2026", transactionDate: "18 Feb 2026  ·  10:00 AM", amount: "150.00", isRead: true),
        NotificationModel(image: "Profile", userName: "Leng Chingmony", payMonth: "February 2026", transactionDate: "17 Feb 2026  ·  11:30 AM", amount: "150.00", isRead: true),
        NotificationModel(image: "Profile", userName: "Kouern Doch",    payMonth: "January 2026",  transactionDate: "15 Jan 2026  ·  09:45 AM", amount: "150.00", isRead: true),
        NotificationModel(image: "Profile", userName: "Leng Chingmony", payMonth: "January 2026",  transactionDate: "14 Jan 2026  ·  03:00 PM", amount: "150.00", isRead: true),
    ]

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    private var displayed: [NotificationModel] {
        filter == .unread ? notifications.filter { !$0.isRead } : notifications
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerView
                filterBar.padding(.bottom, 8)

                List {
                    if displayed.isEmpty {
                        NotifEmptyState()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    } else {
                        ForEach(displayed) { item in
                            cardRow(item)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .animation(.easeInOut(duration: 0.25), value: notifications.map { $0.isRead })
                .animation(.easeInOut(duration: 0.25), value: notifications.count)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(lm["notifications"])
                .font(.system(size: 24, weight: .bold))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(NotifFilter.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        filter = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(lm[tab.rawValue])
                            .font(.system(size: 14,
                                          weight: filter == tab ? .semibold : .regular))
                        if tab == .unread, unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(filter == tab ? .blue : .white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Capsule()
                                    .fill(filter == tab ? Color.white : Color.red))
                        }
                    }
                    .foregroundColor(filter == tab ? .white : .gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(filter == tab ? Color.blue : Color(.systemBackground))
                    )
                    .overlay(
                        Capsule()
                            .stroke(filter == tab ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func cardRow(_ item: NotificationModel) -> some View {
        NotificationCard(item: item)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) { markAsRead(item) }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    withAnimation { deleteNotif(item) }
                } label: {
                    Label(lm["delete"], systemImage: "trash")
                }
                if !item.isRead {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { markAsRead(item) }
                    } label: {
                        Label(lm["mark_read"], systemImage: "checkmark.circle.fill")
                    }
                    .tint(.blue)
                }
            }
    }

    // MARK: - Actions

    private func markAsRead(_ item: NotificationModel) {
        if let i = notifications.firstIndex(where: { $0.id == item.id }) {
            notifications[i].isRead = true
        }
    }

    private func deleteNotif(_ item: NotificationModel) {
        notifications.removeAll { $0.id == item.id }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationView()
            .environmentObject(LocalizationManager())
    }
}
