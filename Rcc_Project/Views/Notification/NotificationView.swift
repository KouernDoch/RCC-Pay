//
//  NotificationView.swift
//  RCC Pay
//
//  The notification inbox.
//
//  Model, loading and the optimistic mark-read / mark-all / delete calls are unchanged.
//  The presentation gains skeleton loading, a visible error state (`errorMessage` was
//  set but never rendered), and an unread treatment that leans on a leading accent bar
//  rather than tinting the whole card — which made unread rows hard to read in dark mode.
//

import SwiftUI

// MARK: - Model

struct NotificationModel: Identifiable {
    let id = UUID()
    /// Backend notification id (nil for previews/mock rows).
    var backendId: Int? = nil
    /// Local asset used as the placeholder when the sender has no uploaded photo.
    var image: String
    /// Sender's uploaded avatar URL, from the backend `senderProfileImage`.
    var profileImage: String? = nil
    var userName: String
    var payMonth: String
    var transactionDate: String
    var amount: String
    var isRead: Bool
}

// MARK: - Filter

enum NotifFilter: String, CaseIterable, Identifiable {
    case all    = "all"
    case unread = "unread"

    var id: String { rawValue }
}

// MARK: - Card

struct NotificationCard: View {

    let item: NotificationModel

    var body: some View {
        HStack(spacing: 0) {
            // Unread marker: a solid rail on the leading edge. Legible in both schemes,
            // and it leaves the card's own background alone so the text keeps full contrast.
            Rectangle()
                .fill(item.isRead ? Color.clear : Color.dsBrand)
                .frame(width: 3)
                .accessibilityHidden(true)

            HStack(spacing: DS.Space.sm + 2) {
                DSAvatar(
                    urlString: item.profileImage,
                    size: .md,
                    placeholder: item.image,
                    statusTone: item.isRead ? nil : .brand)

                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                        Text(item.userName)
                            .font(.system(.subheadline, weight: item.isRead ? .medium : .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if !item.amount.isEmpty {
                            DSAmountPill(amount: item.amount)
                        }
                    }

                    Text(item.payMonth)
                        .font(.dsSubtext)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DS.Space.xxs) {
                        Image(systemName: "clock")
                            .font(.system(.caption2))
                            .foregroundStyle(.tertiary)
                        Text(item.transactionDate)
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, DS.Space.sm + 2)
            .padding(.vertical, DS.Space.sm + 2)
        }
        .dsSurface(radius: DS.Radius.md, elevation: .low)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.isRead ? "" : "Unread. ")\(item.userName). \(item.payMonth). \(item.transactionDate)")
    }
}

// MARK: - Main view

struct NotificationView: View {

    @EnvironmentObject private var lm: LocalizationManager

    @State private var filter: NotifFilter = .all
    @State private var notifications: [NotificationModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    private var displayed: [NotificationModel] {
        filter == .unread ? notifications.filter { !$0.isRead } : notifications
    }

    private var isInitialLoad: Bool { isLoading && !hasLoadedOnce }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                header
                filterBar

                if let errorMessage, notifications.isEmpty {
                    DSErrorState(message: errorMessage) {
                        Task { await load() }
                    }
                    Spacer()
                } else {
                    list
                }
            }
            .padding(.top, DS.Space.xs)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        DSScreenTitle(
            title: lm["notifications"],
            subtitle: unreadCount > 0 ? "\(unreadCount) \(lm["unread"].lowercased())" : nil
        ) {
            if unreadCount > 0 {
                Button {
                    withAnimation(DS.Motion.smooth) { markAllRead() }
                } label: {
                    Text(lm["mark_all_read"])
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(Color.dsBrand)
                }
            }
        }
        .padding(.horizontal, DS.Space.page)
    }

    // MARK: - Filter

    private var filterBar: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(NotifFilter.allCases) { tab in
                DSFilterChip(
                    title: lm[tab.rawValue],
                    isSelected: filter == tab,
                    count: tab == .unread ? unreadCount : nil
                ) {
                    withAnimation(DS.Motion.quick) { filter = tab }
                }
            }
            Spacer()
        }
        .padding(.horizontal, DS.Space.page)
    }

    // MARK: - List

    private var list: some View {
        List {
            if isInitialLoad {
                DSSkeletonList(count: 5)
                    .padding(.horizontal, DS.Space.page)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            } else if displayed.isEmpty {
                DSEmptyState(
                    title: lm["no_notifications"],
                    message: lm["all_caught_up"],
                    systemImage: "bell.slash.fill",
                    tone: .brand)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            } else {
                // A failed refresh shouldn't discard rows we already have — surface it
                // above them instead.
                if let errorMessage {
                    DSInlineError(message: errorMessage) {
                        Task { await load() }
                    }
                    .padding(.horizontal, DS.Space.page)
                    .padding(.bottom, DS.Space.xs)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }

                ForEach(displayed) { item in
                    cardRow(item)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await load() }
        .animation(DS.Motion.smooth, value: notifications.map(\.isRead))
        .animation(DS.Motion.smooth, value: notifications.count)
        .animation(DS.Motion.smooth, value: filter)
    }

    @ViewBuilder
    private func cardRow(_ item: NotificationModel) -> some View {
        NotificationCard(item: item)
            .padding(.horizontal, DS.Space.page)
            .padding(.vertical, DS.Space.xxs)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(DS.Motion.smooth) { markAsRead(item) }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    withAnimation(DS.Motion.smooth) { deleteNotif(item) }
                } label: {
                    Label(lm["delete"], systemImage: "trash")
                }
                if !item.isRead {
                    Button {
                        withAnimation(DS.Motion.smooth) { markAsRead(item) }
                    } label: {
                        Label(lm["mark_read"], systemImage: "checkmark.circle.fill")
                    }
                    .tint(Color.dsBrand)
                }
            }
            .contextMenu {
                if !item.isRead {
                    Button {
                        withAnimation(DS.Motion.smooth) { markAsRead(item) }
                    } label: {
                        Label(lm["mark_read"], systemImage: "checkmark.circle")
                    }
                }
                Button(role: .destructive) {
                    withAnimation(DS.Motion.smooth) { deleteNotif(item) }
                } label: {
                    Label(lm["delete"], systemImage: "trash")
                }
            }
    }

    // MARK: - Actions

    private func markAsRead(_ item: NotificationModel) {
        guard let i = notifications.firstIndex(where: { $0.id == item.id }), !notifications[i].isRead else { return }
        notifications[i].isRead = true  // optimistic
        if let backendId = item.backendId {
            Task { _ = try? await BackendAPI.markNotificationRead(id: backendId) }
        }
    }

    private func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }  // optimistic
        Task { try? await BackendAPI.markAllNotificationsRead() }
    }

    private func deleteNotif(_ item: NotificationModel) {
        notifications.removeAll { $0.id == item.id }  // optimistic
        if let backendId = item.backendId {
            Task { try? await BackendAPI.deleteNotification(id: backendId) }
        }
    }

    // MARK: - Loading

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await BackendAPI.listNotifications()
            notifications = items.map { dto in
                NotificationModel(
                    backendId: dto.notificationId,
                    image: "Profile",
                    profileImage: dto.senderProfileImage,
                    userName: dto.title,
                    payMonth: dto.message,
                    transactionDate: DisplayFormat.prettyDate(dto.createdAt),
                    amount: "",
                    isRead: dto.read)
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Failed to load notifications."
        }
        isLoading = false
        hasLoadedOnce = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationView()
            .environmentObject(LocalizationManager())
    }
}
