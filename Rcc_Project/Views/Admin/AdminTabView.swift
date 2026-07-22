//
//  AdminTabView.swift
//  Rcc_Project
//
//  Admin shell: shared header + month filter, with tabs for Home, Invoice, Payment
//  and Manage Users.
//
//  The tab structure, the ViewModel and every call it makes are unchanged. The rewrite
//  fixes three things the old screen got wrong:
//
//   1. Dark mode. The page background was a hard-coded light-blue gradient and two
//      surfaces used literal `Color(.white)`, so in dark mode this screen rendered
//      white-on-white while every other screen adapted.
//   2. Missing states. Home and Invoice rendered an empty column while loading and said
//      nothing when a request failed — `errorMessage` was published but never shown.
//   3. Dead affordance. `AdminViewModel.beginEdit` existed and the edit sheet was wired
//      up, but nothing ever called it. Editing is now reachable from a swipe action and
//      a context menu on each resident row.
//

import SwiftUI
import Foundation

// MARK: - Root

struct AdminTabView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore

    @StateObject private var viewModel = AdminViewModel()

    private var tabItems: [GlassTabItem] {
        [
            GlassTabItem(tag: 0, title: lm["admin_tab_home"], icon: "house", filled: "house.fill"),
            GlassTabItem(tag: 1, title: lm["admin_tab_invoice"], icon: "doc.text", filled: "doc.text.fill"),
            GlassTabItem(tag: 2, title: lm["admin_tab_payment"], icon: "creditcard", filled: "creditcard.fill"),
            GlassTabItem(tag: 3, title: lm["admin_tab_manage_users"], icon: "person.3", filled: "person.3.fill"),
        ]
    }

    /// First load only — a pull-to-refresh keeps the current content on screen.
    private var isInitialLoad: Bool {
        viewModel.isLoading && viewModel.residents.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    DashboardChromeView(
                        displayName: session.displayName.isEmpty ? lm["admin_display_name"] : session.displayName,
                        roleSubtitle: lm["admin_user"],
                        showMonthSelector: viewModel.selectedAdminTab != 3,
                        onMonthSelected: { month in
                            viewModel.onChromeMonthSelected(month)
                        }
                    )

                    adminTabContent
                        .id(viewModel.selectedAdminTab)
                        .transition(.opacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(DS.Motion.fade, value: viewModel.selectedAdminTab)
                        .safeAreaInset(edge: .bottom) {
                            LiquidGlassTabBar(
                                selection: $viewModel.selectedAdminTab,
                                items: tabItems)
                        }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        }
        .onAppear { viewModel.ensureSelectedMonthIfNeeded() }
        .task { await viewModel.loadAll() }
        .alert(lm["admin_invoice_issued_title"], isPresented: $viewModel.showIssuedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(lm["admin_invoice_issued_message"]) \(viewModel.selectedMonthLabel) \(viewModel.filterYear).")
        }
        .sheet(isPresented: $viewModel.showManageEditSheet) {
            adminEditUserSheet
        }
        .confirmationDialog(
            lm["admin_delete_user_title"],
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(lm["admin_delete"], role: .destructive) {
                viewModel.deleteResident()
            }
            Button(lm["admin_cancel_delete"], role: .cancel) {
                viewModel.clearPendingDelete()
            }
        } message: {
            if let name = viewModel.residentToDelete?.name {
                Text("\(lm["admin_delete_user_message"])\n\n\(name)")
            } else {
                Text(lm["admin_delete_user_message"])
            }
        }
    }

    @ViewBuilder
    private var adminTabContent: some View {
        switch viewModel.selectedAdminTab {
        case 0: adminHomeTab
        case 1: adminInvoiceTab
        case 2: adminPaymentTab
        default: adminManageUsersTab
        }
    }

    /// Shown above every tab's content when a request failed. Published on the
    /// ViewModel all along; nothing rendered it before.
    @ViewBuilder
    private var errorBanner: some View {
        if let message = viewModel.errorMessage {
            DSInlineError(message: message) {
                Task { await viewModel.loadAll() }
            }
            .padding(.horizontal, DS.Space.page)
        }
    }

    // MARK: - Home

    private var adminHomeTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                errorBanner

                if isInitialLoad {
                    DSSkeletonCard()
                        .padding(.horizontal, DS.Space.page)
                    DSSkeletonList(count: 3)
                        .padding(.horizontal, DS.Space.page)
                } else {
                    adminSummaryCard
                        .padding(.horizontal, DS.Space.page)

                    paymentFeedSection
                }
            }
            .padding(.top, DS.Space.xs)
            .padding(.bottom, DS.Space.xxl)
            .animation(DS.Motion.smooth, value: isInitialLoad)
        }
        .refreshable { await viewModel.loadAll() }
    }

    private var adminSummaryCard: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                HStack(alignment: .top) {
                    HStack(spacing: DS.Space.xs + 2) {
                        DSIconBadge(systemName: "chart.pie.fill", tint: .dsBrand)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(lm["admin_summary_title"])
                                .font(.dsHeadline)
                                .foregroundStyle(.primary)
                            Text(viewModel.selectedMonthLabel.isEmpty ? "—" : viewModel.selectedMonthLabel)
                                .font(.dsCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: DS.Space.xs)

                    Menu {
                        Picker(lm["admin_year"], selection: $viewModel.filterYear) {
                            ForEach(2024...2040, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                    } label: {
                        DSMenuChip(title: String(viewModel.filterYear))
                    }
                    .accessibilityLabel(lm["admin_year"])
                    .accessibilityValue(String(viewModel.filterYear))
                }

                DSStatTileRow(stats: [
                    DSStat(label: lm["admin_total_users"], value: "\(viewModel.residents.count)",
                           tone: .brand, systemImage: "person.3.fill"),
                    DSStat(label: lm["admin_total_paid_users"], value: "\(viewModel.paidCount)",
                           tone: .success, systemImage: "checkmark.seal.fill"),
                    DSStat(label: lm["admin_total_unpaid_users"], value: "\(viewModel.unpaidCount)",
                           tone: .warning, systemImage: "exclamationmark.triangle.fill"),
                ])

                collectionProgress
            }
        }
    }

    /// How much of the month's billing is settled — the number an admin actually
    /// opens this screen to find, previously only inferable by comparing two tiles.
    private var collectionProgress: some View {
        let total = max(viewModel.residents.count, 1)
        let fraction = CGFloat(viewModel.paidCount) / CGFloat(total)

        return VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(Color.dsSuccess)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            .animation(DS.Motion.smooth, value: fraction)

            Text("\(viewModel.paidCount) / \(viewModel.residents.count) \(lm["admin_paid_this_month"].lowercased())")
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lm["admin_paid_this_month"])
        .accessibilityValue("\(viewModel.paidCount) of \(viewModel.residents.count)")
    }

    private var paymentFeedSection: some View {
        VStack(spacing: DS.Space.xs) {
            DSSectionHeader(
                title: lm["daily_payment"],
                isLoading: viewModel.isLoading && !viewModel.residents.isEmpty
            ) {
                Button {
                    withAnimation(DS.Motion.quick) { viewModel.selectedAdminTab = 2 }
                } label: {
                    Text(lm["see_all"])
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsBrand)
                }
            }
            .padding(.horizontal, DS.Space.page)

            if viewModel.paymentModels.isEmpty {
                DSEmptyState(
                    title: lm["no_payments"],
                    systemImage: "tray")
            } else {
                LazyVStack(spacing: DS.Space.xs) {
                    ForEach(viewModel.paymentModels) { paymentModel in
                        CardPayment(
                            name: paymentModel.name,
                            image: paymentModel.image,
                            profileImage: paymentModel.profileImage,
                            date: paymentModel.date,
                            amount: paymentModel.amount
                        )
                    }
                }
                .animation(DS.Motion.smooth, value: viewModel.paymentModels.count)
            }
        }
    }

    // MARK: - Invoice

    private var adminInvoiceTab: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {

            DSButton(
                title: lm["admin_issue_all_users"],
                systemImage: "doc.badge.plus",
                role: .primary,
                isLoading: viewModel.isLoading
            ) {
                viewModel.issueInvoicesForCurrentPeriod()
            }
            .padding(.horizontal, DS.Space.page)

            // The filter is a chip row rather than the old dropdown: three mutually
            // exclusive options with live counts read faster than a menu that hides two
            // of them behind a tap.
            invoiceFilterBar

            errorBanner

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: DS.Space.sm) {
                    if isInitialLoad {
                        DSSkeletonList(count: 4)
                    } else if viewModel.residentsForInvoiceList.isEmpty {
                        DSEmptyState(
                            title: lm["admin_invoice_filter_empty"],
                            systemImage: "doc.text.magnifyingglass")
                    } else {
                        ForEach(viewModel.residentsForInvoiceList) { r in
                            AdminInvoiceCard(
                                resident: r,
                                record: r.months[viewModel.currentKey],
                                onStatusSelected: { status in
                                    viewModel.updateResidentInvoiceStatus(r, to: status)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, DS.Space.page)
                .padding(.bottom, DS.Space.xxl)
                .animation(DS.Motion.smooth, value: viewModel.invoiceTabFilter)
            }
            .refreshable { await viewModel.loadAll() }
        }
        .padding(.top, DS.Space.xs)
    }

    private var invoiceFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(AdminInvoiceTabFilter.allCases) { option in
                    DSFilterChip(
                        title: invoiceFilterTitle(option),
                        isSelected: viewModel.invoiceTabFilter == option,
                        count: invoiceFilterCount(option),
                        tone: invoiceFilterTone(option)
                    ) {
                        withAnimation(DS.Motion.quick) { viewModel.invoiceTabFilter = option }
                    }
                }
            }
            .padding(.horizontal, DS.Space.page)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private func invoiceFilterTitle(_ filter: AdminInvoiceTabFilter) -> String {
        switch filter {
        case .all:    return lm["admin_invoice_filter_all"]
        case .paid:   return lm["admin_invoice_filter_paid"]
        case .unpaid: return lm["admin_invoice_filter_unpaid"]
        }
    }

    private func invoiceFilterCount(_ filter: AdminInvoiceTabFilter) -> Int {
        switch filter {
        case .all:    return viewModel.residents.count
        case .paid:   return viewModel.paidCount
        case .unpaid: return viewModel.unpaidCount
        }
    }

    private func invoiceFilterTone(_ filter: AdminInvoiceTabFilter) -> DSTone {
        switch filter {
        case .all:    return .brand
        case .paid:   return .success
        case .unpaid: return .warning
        }
    }

    // MARK: - Payment (unpaid)

    private var adminPaymentTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DS.Space.xs) {
                errorBanner

                DSSectionHeader(
                    title: lm["admin_unpaid_section"],
                    subtitle: "\(viewModel.unpaidCount) / \(viewModel.residents.count)",
                    tone: .warning,
                    isLoading: viewModel.isLoading && !viewModel.residents.isEmpty)
                .padding(.horizontal, DS.Space.page)
                .padding(.top, DS.Space.xxs)

                if isInitialLoad {
                    DSSkeletonList(count: 4)
                        .padding(.horizontal, DS.Space.page)
                } else if viewModel.unpaidResidents.isEmpty {
                    DSEmptyState(
                        title: lm["admin_all_paid"],
                        systemImage: "checkmark.seal.fill",
                        tone: .success)
                } else {
                    LazyVStack(spacing: DS.Space.xs) {
                        ForEach(viewModel.unpaidResidents) { r in
                            let rec = r.months[viewModel.currentKey]
                            let invoiceAmountText: String = {
                                guard let amount = rec?.invoiceAmount else { return "-" }
                                return String(format: "%.2f", amount)
                            }()
                            CardPayment(
                                name: r.name,
                                image: r.image,
                                profileImage: r.profileImage,
                                date: "\(lm["admin_unpaid_for"]) \(viewModel.selectedMonthLabel) \(viewModel.filterYear)",
                                amount: invoiceAmountText,
                                // These are amounts *owed*, so they must not render in the
                                // same green the paid feed uses.
                                tone: .warning)
                        }
                    }
                }
            }
            .padding(.bottom, DS.Space.xxl)
            .animation(DS.Motion.smooth, value: isInitialLoad)
        }
        .refreshable { await viewModel.loadAll() }
    }

    // MARK: - Manage Users

    private var adminManageUsersTab: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                DSScreenTitle(
                    title: lm["admin_manage_users_title"],
                    subtitle: "\(viewModel.residents.count) \(lm["admin_total_users"].lowercased())")

                DSSearchField(
                    text: $viewModel.userSearchText,
                    placeholder: lm["admin_search_users"])
            }
            .padding(.horizontal, DS.Space.page)
            .padding(.top, DS.Space.xs)
            .padding(.bottom, DS.Space.sm)

            errorBanner

            if isInitialLoad {
                ScrollView {
                    DSSkeletonList(count: 5)
                        .padding(.horizontal, DS.Space.page)
                }
            } else if viewModel.filteredResidents.isEmpty {
                ScrollView {
                    DSEmptyState(
                        title: viewModel.userSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? lm["admin_manage_users_empty"]
                            : lm["admin_manage_users_no_results"],
                        systemImage: "person.crop.circle.badge.questionmark")
                }
            } else {
                List {
                    ForEach(viewModel.filteredResidents) { r in
                        AdminUserRow(
                            resident: r,
                            onPaymentTypeSelected: { type in
                                viewModel.setResidentPaymentType(r, to: type)
                            })
                        .listRowInsets(EdgeInsets(
                            top: DS.Space.xxs + 2, leading: DS.Space.page,
                            bottom: DS.Space.xxs + 2, trailing: DS.Space.page))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.requestDeleteResident(r)
                            } label: {
                                Label(lm["admin_delete"], systemImage: "trash.fill")
                            }
                            // `beginEdit` and the edit sheet already existed; nothing
                            // in the UI reached them until now.
                            Button {
                                viewModel.beginEdit(r)
                            } label: {
                                Label(lm["edit"], systemImage: "square.and.pencil")
                            }
                            .tint(Color.dsBrand)
                        }
                        .contextMenu {
                            Button {
                                viewModel.beginEdit(r)
                            } label: {
                                Label(lm["edit"], systemImage: "square.and.pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.requestDeleteResident(r)
                            } label: {
                                Label(lm["admin_delete"], systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 1)
                .refreshable { await viewModel.loadAll() }
                .animation(DS.Motion.smooth, value: viewModel.filteredResidents.count)
            }
        }
    }

    // MARK: - Edit sheet

    private var adminEditUserSheet: some View {
        AdminEditUserSheetView(
            draftName: $viewModel.draftName,
            draftEmail: $viewModel.draftEmail,
            draftImage: $viewModel.draftImage,
            draftPaymentType: $viewModel.draftPaymentType,
            profileImage: viewModel.residentToEdit?.profileImage,
            onCancel: { viewModel.cancelEditSheet() },
            onSave: { viewModel.saveEditSheet() })
    }
}

// MARK: - Resident row

private struct AdminUserRow: View {

    @EnvironmentObject private var lm: LocalizationManager

    let resident: AdminResident
    let onPaymentTypeSelected: (AdminInvoiceType) -> Void

    private var isFullPay: Bool { resident.defaultPaymentType == .full }
    private var paymentTone: DSTone { isFullPay ? .success : .warning }
    private var paymentText: String { isFullPay ? lm["admin_full"] : lm["admin_half"] }

    var body: some View {
        DSPersonRow(
            name: resident.name,
            subtitle: resident.email,
            imageURL: resident.profileImage,
            placeholder: resident.image,
            avatarSize: .lg
        ) {
            VStack(alignment: .trailing, spacing: DS.Space.xxs + 1) {
                Text(lm["admin_payment_type"])
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.secondary)

                Menu {
                    Picker(lm["admin_payment_type"], selection: paymentTypeBinding) {
                        Text(lm["admin_full"]).tag(AdminInvoiceType.full)
                        Text(lm["admin_half"]).tag(AdminInvoiceType.half)
                    }
                } label: {
                    DSStatusBadge(
                        text: paymentText,
                        tone: paymentTone,
                        showsDot: false,
                        isInteractive: true)
                }
                .accessibilityLabel(lm["admin_payment_type"])
                .accessibilityValue(paymentText)
            }
        }
        .padding(DS.Space.sm + 2)
        .dsSurface(radius: DS.Radius.lg, elevation: .low)
    }

    /// Wraps the callback as a `Binding` so the menu can use a `Picker` — which gives
    /// the selected option a checkmark for free, rather than hand-drawing one.
    private var paymentTypeBinding: Binding<AdminInvoiceType> {
        Binding(
            get: { resident.defaultPaymentType },
            set: { onPaymentTypeSelected($0) })
    }
}

// MARK: - Edit Sheet

private struct AdminEditUserSheetView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @Binding var draftName: String
    @Binding var draftEmail: String
    @Binding var draftImage: String
    @Binding var draftPaymentType: AdminInvoiceType

    /// The resident's uploaded photo URL, shown read-only.
    let profileImage: String?

    let onCancel: () -> Void
    let onSave: () -> Void

    private var isValid: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draftEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.lg) {

                        // Read-only: the photo is set by the resident from their own
                        // profile screen, so there is nothing for an admin to pick here.
                        VStack(spacing: DS.Space.xs) {
                            DSAvatar(urlString: profileImage, size: .xl, placeholder: draftImage)
                            Text(profileImage?.isEmpty == false
                                 ? lm["admin_profile_photo_set"]
                                 : lm["admin_profile_photo_none"])
                                .font(.dsCaption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.md)

                        DSCard {
                            VStack(spacing: DS.Space.md) {
                                DSLabeledField(label: lm["admin_name"], systemImage: "person.fill") {
                                    TextField(lm["admin_name"], text: $draftName)
                                        .autocorrectionDisabled()
                                }

                                DSLabeledField(label: lm["admin_email"], systemImage: "envelope.fill") {
                                    TextField(lm["admin_email"], text: $draftEmail)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }

                                VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
                                    Text(lm["admin_payment_type"])
                                        .font(.dsCaption)
                                        .foregroundStyle(.secondary)
                                    Picker(lm["admin_payment_type"], selection: $draftPaymentType) {
                                        Text(lm["admin_full"]).tag(AdminInvoiceType.full)
                                        Text(lm["admin_half"]).tag(AdminInvoiceType.half)
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                    }
                    .padding(DS.Space.page)
                }
            }
            .navigationTitle(lm["admin_edit_user"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["admin_cancel"]) {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["admin_save"]) {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Tab bar

struct GlassTabItem: Identifiable {
    let tag: Int
    let title: String
    let icon: String
    let filled: String
    var id: Int { tag }
}

/// Floating glass tab bar. Rebuilt on `.ultraThinMaterial` with adaptive strokes —
/// the previous version layered white-only highlights and borders, which vanished
/// against a dark background.
private struct LiquidGlassTabBar: View {

    @Binding var selection: Int
    let items: [GlassTabItem]

    @Namespace private var pillNamespace
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: DS.Space.xxs) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(DS.Space.xxs + 2)
        .frame(height: 68)
        .background(glassSurface)
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.xs)
        .dsDenseLayout()
    }

    private var glassSurface: some View {
        RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .strokeBorder(
                        scheme == .dark
                            ? Color.white.opacity(0.14)
                            : Color.white.opacity(0.65),
                        lineWidth: 1)
            )
            .shadow(
                color: scheme == .dark ? .black.opacity(0.4) : Color.dsBrand.opacity(0.16),
                radius: 20, x: 0, y: 10)
    }

    private func tabButton(for item: GlassTabItem) -> some View {
        let isSelected = selection == item.tag

        return Button {
            withAnimation(DS.Motion.smooth) { selection = item.tag }
        } label: {
            ZStack {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.dsBrand)
                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                }

                HStack(spacing: DS.Space.xxs + 2) {
                    Image(systemName: isSelected ? item.filled : item.icon)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))

                    if isSelected {
                        Text(item.title)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: true, vertical: false)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, isSelected ? DS.Space.sm : 0)
            }
            .frame(maxWidth: isSelected ? .infinity : 52)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview {
    AdminTabView()
        .environmentObject(LocalizationManager())
        .environmentObject(SessionStore())
}
