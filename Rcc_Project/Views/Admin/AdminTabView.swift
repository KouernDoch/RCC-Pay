//
//  AdminTabView.swift
//  Rcc_Project
//
//  Admin shell: shared header + month filter, tabs for Home, Invoice, Payment.
//

import SwiftUI
import Foundation

// MARK: - Root

struct AdminTabView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = AdminViewModel()

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    DashboardChromeView(
                        displayName: lm["admin_display_name"],
                        roleSubtitle: lm["admin_user"],
                        showMonthSelector: viewModel.selectedAdminTab != 3,
                        onMonthSelected: { month in
                            viewModel.onChromeMonthSelected(month)
                        }
                    )

//                    HStack {
//                        Text(selectedmonth.isEmpty ? "—" : selectedmonth)
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundStyle(.primary)
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 6)

                    TabView(selection: $viewModel.selectedAdminTab) {
                        adminHomeTab
                            .tabItem { Label(lm["admin_tab_home"], systemImage: "house.fill") }
                            .tag(0)
                        adminInvoiceTab
                            .tabItem { Label(lm["admin_tab_invoice"], systemImage: "doc.text.fill") }
                            .tag(1)
                        adminPaymentTab
                            .tabItem { Label(lm["admin_tab_payment"], systemImage: "creditcard.fill") }
                            .tag(2)
                        adminManageUsersTab
                            .tabItem { Label(lm["admin_tab_manage_users"], systemImage: "person.3.fill") }
                            .tag(3)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.ensureSelectedMonthIfNeeded()
        }
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

    // MARK: - Home

    private var adminHomeTab: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    adminSummaryCard
                        .padding(.top, 8)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        // Section header
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color(red: 0.22, green: 0.50, blue: 0.98))
                                .frame(width: 3, height: 14)
                                .clipShape(Capsule())
                            Text(lm["daily_payment"])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Text(lm["see_all"])
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(red: 0.22, green: 0.50, blue: 0.98))
                        }
                        .padding(.horizontal)
                        .padding(.top, 14)
                        .padding(.bottom, 6)

                        // Cards
                        VStack(spacing: 8) {
                            ForEach(viewModel.paymentModels) { paymentModel in
                                CardPayment(
                                    name: paymentModel.name,
                                    image: paymentModel.image,
                                    date: paymentModel.date,
                                    amount: paymentModel.amount
                                )
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
               
                .padding(.bottom, 10)
            }
        }
    }

    private var adminSummaryCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(blue.opacity(0.15))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lm["admin_summary_title"])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(viewModel.selectedMonthLabel.isEmpty ? "—" : viewModel.selectedMonthLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            Picker("Year", selection: $viewModel.filterYear) {
                                ForEach(2024...2040, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(String(viewModel.filterYear))
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(blue.opacity(colorScheme == .dark ? 0.18 : 0.09))
                            )
                        }
                    }
                }
                
                HStack(spacing: 10) {
                    summaryTile(
                        icon: "person.3.fill",
                        value: "\(viewModel.residents.count)",
                        title: lm["admin_total_users"],
                        accent: blue
                    )
                    summaryTile(
                        icon: "checkmark.seal.fill",
                        value: "\(viewModel.paidCount)",
                        title: lm["admin_total_paid_users"],
                        accent: .green
                    )
                    summaryTile(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(viewModel.unpaidCount)",
                        title: lm["admin_total_unpaid_users"],
                        accent: .orange
                    )
                }
            }
            .padding(14)
            .background(Color(.white))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(blue.opacity(0.12), lineWidth: 1)
            )
        }

    private func summaryTile(icon: String, value: String, title: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }

    private var paidSectionHeader: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(blue)
                .frame(width: 3, height: 16)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(lm["admin_paid_this_month"])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text("\(viewModel.paidCount) / \(viewModel.residents.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var emptyPaidState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
                .opacity(0.65)
            Text(lm["admin_no_paid_users"])
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Invoice

    private var adminInvoiceTab: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

           
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        viewModel.issueInvoicesForCurrentPeriod()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(lm["admin_issue_all_users"])
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    HStack(alignment: .center, spacing: 12) {
                        Text(lm["admin_invoice_status_header"])
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 8)

                        Menu {
                            ForEach(AdminInvoiceTabFilter.allCases) { option in
                                Button {
                                    viewModel.invoiceTabFilter = option
                                } label: {
                                    HStack {
                                        Text(invoiceFilterTitle(option))
                                        Spacer(minLength: 8)
                                        if viewModel.invoiceTabFilter == option {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(invoiceFilterTitle(viewModel.invoiceTabFilter))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(blue)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(blue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(blue.opacity(colorScheme == .dark ? 0.22 : 0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(blue.opacity(0.28), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    ScrollView(.vertical, showsIndicators: false) {

                    if viewModel.residentsForInvoiceList.isEmpty {
                        Text(lm["admin_invoice_filter_empty"])
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(viewModel.residentsForInvoiceList) { r in
                                AdminInvoiceCard(
                                    resident: r,
                                    record: r.months[viewModel.currentKey]
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func invoiceFilterTitle(_ filter: AdminInvoiceTabFilter) -> String {
        switch filter {
        case .all: return lm["admin_invoice_filter_all"]
        case .paid: return lm["admin_invoice_filter_paid"]
        case .unpaid: return lm["admin_invoice_filter_unpaid"]
        }
    }

    private func invoiceStatusRow(for r: AdminResident) -> some View {
        let rec = r.months[viewModel.currentKey]
        let status: String = {
            guard let rec else { return lm["admin_status_no_invoice"] }
            if rec.isPaid { return lm["admin_status_paid"] }
            if rec.invoiceIssued { return lm["admin_status_issued_unpaid"] }
            return lm["admin_status_pending"]
        }()

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(r.name)
                    .font(.system(size: 14, weight: .semibold))
                Text("$\(r.defaultDue)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(status)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Payment (unpaid)

    private var adminPaymentTab: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 3, height: 14)
                            .clipShape(Capsule())
                        Text(lm["admin_unpaid_section"])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                    if viewModel.unpaidResidents.isEmpty {
                        Text(lm["admin_all_paid"])
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.unpaidResidents) { r in
                                let due = Double(r.defaultDue) ?? 0.0
                                let rec = r.months[viewModel.currentKey]
                                let invoiceAmountValue = rec?.invoiceAmount ?? ((r.defaultPaymentType == .half) ? (due / 2.0) : due)
                                let invoiceAmountText = String(format: "%.2f", invoiceAmountValue)
                                CardPayment(
                                    name: r.name,
                                    image: r.image,
                                    date: "\(lm["admin_unpaid_for"]) \(viewModel.selectedMonthLabel) \(viewModel.filterYear)",
                                    amount: invoiceAmountText
                                )
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }

    // MARK: - Manage Users

    private var adminManageUsersTab: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            
                VStack(spacing: 0) {

                // ── Section header ───────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lm["admin_manage_users_title"])
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("\(viewModel.residents.count) \(lm["admin_total_users"].lowercased())")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField(
                            lm["admin_search_users"],
                            text: $viewModel.userSearchText
                        )
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)

                        if !viewModel.userSearchText.isEmpty {
                            Button {
                                viewModel.userSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.white))
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                .padding(.bottom, 12)

                if viewModel.filteredResidents.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(viewModel.userSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? lm["admin_manage_users_empty"] : lm["admin_manage_users_no_results"])
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredResidents) { r in
                            userManageRow(resident: r)
                                .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.requestDeleteResident(r)
                                    } label: {
                                        Label(lm["admin_delete"], systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 1)
                }
            }
        }
    }

    private func userManageRow(resident: AdminResident) -> some View {
        let isFullPay = resident.defaultPaymentType == .full
        let paymentText = isFullPay ? lm["admin_full"] : lm["admin_half"]
        let paymentColor: Color = isFullPay
            ? Color(red: 0.18, green: 0.75, blue: 0.48)
            : Color(red: 1.00, green: 0.60, blue: 0.15)

        return VStack(spacing: 0) {
            // ── Top: avatar + info ───────────────────────────────
            HStack(alignment: .center, spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Image(resident.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1.5))

                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(resident.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(resident.email)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Payment type selector (top-right)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(lm["admin_payment_type"])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Menu {
                        Button {
                            viewModel.setResidentPaymentType(resident, to: .full)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isFullPay ? "checkmark.circle.fill" : "circle")
                                Text(lm["admin_full"])
                            }
                        }

                        Button {
                            viewModel.setResidentPaymentType(resident, to: .half)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: !isFullPay ? "checkmark.circle.fill" : "circle")
                                Text(lm["admin_half"])
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(paymentText)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(paymentColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(paymentColor.opacity(0.14)))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? .clear : Color.black.opacity(0.07),
            radius: 12, x: 0, y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.07) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Manage Users Sheet

    private var adminEditUserSheet: some View {
        AdminEditUserSheetView(
            draftName: $viewModel.draftName,
            draftEmail: $viewModel.draftEmail,
            draftImage: $viewModel.draftImage,
            draftPaymentType: $viewModel.draftPaymentType,
            onCancel: {
                viewModel.cancelEditSheet()
            },
            onSave: {
                viewModel.saveEditSheet()
            }
        )
    }
}

#Preview {
    AdminTabView()
        .environmentObject(LocalizationManager())
}

// MARK: - Edit Sheet

private struct AdminEditUserSheetView: View {
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @Binding var draftName: String
    @Binding var draftEmail: String
    @Binding var draftImage: String
    @Binding var draftPaymentType: AdminInvoiceType

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(lm["admin_name"]) {
                    TextField(lm["admin_name"], text: $draftName)
                        .autocorrectionDisabled()
                }

                Section(lm["admin_email"]) {
                    TextField(lm["admin_email"], text: $draftEmail)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }

                Section(lm["admin_profile"]) {
                    Picker(lm["admin_profile"], selection: $draftImage) {
                        Text("Profile").tag("Profile")
                    }
                    .pickerStyle(.segmented)
                }

                Section(lm["admin_payment_type"]) {
                    Picker(lm["admin_payment_type"], selection: $draftPaymentType) {
                        Text(lm["admin_full"]).tag(AdminInvoiceType.full)
                        Text(lm["admin_half"]).tag(AdminInvoiceType.half)
                    }
                    .pickerStyle(.segmented)
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
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              draftEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
