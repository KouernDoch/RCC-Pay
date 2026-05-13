//
//  AdminTabView.swift
//  Rcc_Project
//
//  Admin shell: shared header + month filter, tabs for Home, Invoice, Payment.
//

import SwiftUI
import Foundation

// MARK: - Models

enum AdminInvoiceType: String, CaseIterable, Identifiable, Hashable {
    case full
    case half

    var id: String { rawValue }
}

struct AdminResidentMonthRecord: Equatable {
    var invoiceIssued: Bool
    var isPaid: Bool
    var paidDate: String
    var invoiceType: AdminInvoiceType? = nil
    var invoiceAmount: Double? = nil
    var invoiceNumber: String? = nil
    var invoiceDate: String? = nil
}

struct AdminResident: Identifiable {
    let id: UUID
    var name: String
    var email: String
    var image: String
    var defaultDue: String
    var defaultPaymentType: AdminInvoiceType
    var months: [String: AdminResidentMonthRecord]
}


private func adminPeriodKey(year: Int, month: Int) -> String {
    "\(year)-\(month)"
}

// MARK: - Root

struct AdminTabView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var filterMonth = Calendar.current.component(.month, from: Date())
    @State private var filterYear = Calendar.current.component(.year, from: Date())
    @State private var selectedmonth = ""
    @State private var residents: [AdminResident] = AdminTabView.seedResidents()
    @State private var showIssuedAlert = false
    @State private var userSearchText: String = ""
    @State private var selectedAdminTab: Int = 0

    // MARK: - Manage Users (edit/delete)
    @State private var showManageEditSheet = false
    @State private var residentToEdit: AdminResident? = nil
    @State private var draftName: String = ""
    @State private var draftEmail: String = ""
    @State private var draftImage: String = "Profile"
    @State private var draftPaymentType: AdminInvoiceType = .full

    @State private var showDeleteConfirmation = false
    @State private var residentToDelete: AdminResident? = nil
    
    @State var paymentModels : [PaymentModel] = [
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00")
    ]


    private let months = Calendar.current.monthSymbols
    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    private var currentKey: String {
        adminPeriodKey(year: filterYear, month: filterMonth)
    }

    private var paidCount: Int {
        residents.filter { $0.months[currentKey]?.isPaid == true }.count
    }

    private var unpaidCount: Int {
        max(0, residents.count - paidCount)
    }

    private var paidResidents: [AdminResident] {
        residents.filter { $0.months[currentKey]?.isPaid == true }
    }

    private var unpaidResidents: [AdminResident] {
        residents.filter { ($0.months[currentKey]?.isPaid ?? false) == false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    DashboardChromeView(
                        displayName: lm["admin_display_name"],
                        roleSubtitle: lm["admin_user"],
                        showMonthSelector: selectedAdminTab != 3,
                        onMonthSelected: { month in
                            filterMonth = month
                            selectedmonth = months[month - 1]
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

                    TabView(selection: $selectedAdminTab) {
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
            if selectedmonth.isEmpty {
                selectedmonth = months[filterMonth - 1]
            }
        }
        .alert(lm["admin_invoice_issued_title"], isPresented: $showIssuedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(lm["admin_invoice_issued_message"]) \(selectedmonth) \(filterYear).")
        }
        .sheet(isPresented: $showManageEditSheet) {
            adminEditUserSheet
        }
        .confirmationDialog(
            lm["admin_delete_user_title"],
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(lm["admin_delete"], role: .destructive) {
                deleteResident()
            }
            Button(lm["admin_cancel_delete"], role: .cancel) { }
        } message: {
            Text(lm["admin_delete_user_message"])
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
                            ForEach(paymentModels) { paymentModel in
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
                        Text(selectedmonth.isEmpty ? "—" : selectedmonth)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Menu {
                            Picker("Year", selection: $filterYear) {
                                ForEach(2024...2040, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(String(filterYear))
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
                        value: "\(residents.count)",
                        title: lm["admin_total_users"],
                        accent: blue
                    )
                    summaryTile(
                        icon: "checkmark.seal.fill",
                        value: "\(paidCount)",
                        title: lm["admin_total_paid_users"],
                        accent: .green
                    )
                    summaryTile(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(unpaidCount)",
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
                Text("\(paidCount) / \(residents.count)")
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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        issueInvoicesForCurrentPeriod()
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

                    Text(lm["admin_invoice_status_header"])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 14) {
                        ForEach(residents) { r in
                            AdminInvoiceCard(
                                resident: r,
                                record: r.months[currentKey]
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
    }

    private func invoiceStatusRow(for r: AdminResident) -> some View {
        let rec = r.months[currentKey]
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

                    if unpaidResidents.isEmpty {
                        Text(lm["admin_all_paid"])
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(unpaidResidents) { r in
                                let due = Double(r.defaultDue) ?? 0.0
                                let rec = r.months[currentKey]
                                let invoiceAmountValue = rec?.invoiceAmount ?? ((r.defaultPaymentType == .half) ? (due / 2.0) : due)
                                let invoiceAmountText = String(format: "%.2f", invoiceAmountValue)
                                CardPayment(
                                    name: r.name,
                                    image: r.image,
                                    date: "\(lm["admin_unpaid_for"]) \(selectedmonth) \(filterYear)",
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
        let filteredResidents: [AdminResident] = {
            let q = userSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !q.isEmpty else { return residents }
            return residents.filter { $0.name.localizedCaseInsensitiveContains(q) }
        }()

        return ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            
                VStack(spacing: 0) {

                // ── Section header ───────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lm["admin_manage_users_title"])
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("\(residents.count) \(lm["admin_total_users"].lowercased())")
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
                            text: $userSearchText
                        )
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)

                        if !userSearchText.isEmpty {
                            Button {
                                userSearchText = ""
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
         ScrollView(.vertical, showsIndicators: false) {

                if filteredResidents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(userSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? lm["admin_manage_users_empty"] : lm["admin_manage_users_no_results"])
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    VStack(spacing: 14) {
                        ForEach(filteredResidents) { r in
                            userManageRow(resident: r)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
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
                            setResidentPaymentType(resident, to: .full)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isFullPay ? "checkmark.circle.fill" : "circle")
                                Text(lm["admin_full"])
                            }
                        }

                        Button {
                            setResidentPaymentType(resident, to: .half)
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

    private func setResidentPaymentType(_ resident: AdminResident, to newType: AdminInvoiceType) {
        guard let idx = residents.firstIndex(where: { $0.id == resident.id }) else { return }
        residents[idx].defaultPaymentType = newType

        // If invoice is already issued for the currently selected period and not paid,
        // update the invoice amount/type so UI stays in sync.
        let key = currentKey
        if var rec = residents[idx].months[key],
           rec.invoiceIssued,
           rec.isPaid == false {
            let due = Double(residents[idx].defaultDue) ?? 0.0
            rec.invoiceType = newType
            rec.invoiceAmount = (newType == .half) ? (due / 2.0) : due
            residents[idx].months[key] = rec
        }
    }

    // MARK: - Manage Users Sheet

    private var adminEditUserSheet: some View {
        AdminEditUserSheetView(
            draftName: $draftName,
            draftEmail: $draftEmail,
            draftImage: $draftImage,
            draftPaymentType: $draftPaymentType,
            onCancel: {
                showManageEditSheet = false
            },
            onSave: {
                saveEditedResident()
                showManageEditSheet = false
            }
        )
    }

    private func beginEdit(_ resident: AdminResident) {
        residentToEdit = resident
        draftName = resident.name
        draftEmail = resident.email
        draftImage = resident.image
        draftPaymentType = resident.defaultPaymentType
        showManageEditSheet = true
    }

    private func saveEditedResident() {
        guard let editing = residentToEdit else { return }
        guard let idx = residents.firstIndex(where: { $0.id == editing.id }) else { return }

        residents[idx].name = draftName
        residents[idx].email = draftEmail
        residents[idx].image = draftImage
        residents[idx].defaultPaymentType = draftPaymentType

        // If invoice is already issued for the currently selected period and not paid,
        // update the invoice amount/type so UI stays in sync.
        let key = currentKey
        if var rec = residents[idx].months[key],
           rec.invoiceIssued,
           rec.isPaid == false {
            let due = Double(residents[idx].defaultDue) ?? 0.0
            rec.invoiceType = draftPaymentType
            rec.invoiceAmount = (draftPaymentType == .half) ? (due / 2.0) : due
            residents[idx].months[key] = rec
        }
    }

    private func deleteResident() {
        guard let toDelete = residentToDelete else { return }
        residents.removeAll { $0.id == toDelete.id }
        residentToDelete = nil
    }

    // MARK: - Actions

    private func issueInvoicesForCurrentPeriod() {
        let key = currentKey

        let invoiceDate = generateInvoiceDateString()
        for i in residents.indices {
            var m = residents[i].months[key] ?? AdminResidentMonthRecord(invoiceIssued: false, isPaid: false, paidDate: "-")

            // Only issue invoices for unpaid records.
            if m.isPaid { continue }

            m.invoiceIssued = true
            let due = Double(residents[i].defaultDue) ?? 0.0
            m.invoiceType = residents[i].defaultPaymentType
            m.invoiceAmount = (m.invoiceType == .half) ? (due / 2.0) : due
            m.invoiceNumber = generateInvoiceNumber(residentIndex: i)
            m.invoiceDate = invoiceDate

            m.isPaid = false
            m.paidDate = "-"
            residents[i].months[key] = m
        }

        showIssuedAlert = true
    }

    private func issueInvoiceForResident(_ resident: AdminResident, invoiceType: AdminInvoiceType, amount: Double) {
        let key = currentKey
        guard let idx = residents.firstIndex(where: { $0.id == resident.id }) else { return }

        var m = residents[idx].months[key] ?? AdminResidentMonthRecord(invoiceIssued: false, isPaid: false, paidDate: "-")
        if m.isPaid { return }

        m.invoiceIssued = true
        m.invoiceType = invoiceType
        m.invoiceAmount = amount
        m.invoiceNumber = generateInvoiceNumber(residentIndex: idx)
        m.invoiceDate = generateInvoiceDateString()

        m.isPaid = false
        m.paidDate = "-"
        residents[idx].months[key] = m
    }

    private func generateInvoiceNumber(residentIndex: Int) -> String {
        let monthPadded = String(format: "%02d", filterMonth)
        let idxPadded = String(format: "%03d", residentIndex + 1)
        return "INV-\(filterYear)-\(monthPadded)-\(idxPadded)"
    }

    private func generateInvoiceDateString() -> String {
        var components = DateComponents()
        components.year = filterYear
        components.month = filterMonth
        components.day = 4

        guard let date = Calendar.current.date(from: components) else { return "-" }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Seed

    private static func seedResidents() -> [AdminResident] {
        let k = adminPeriodKey(year: 2026, month: 1)

        let amount = Double("38.00") ?? 0.0
        let seedComponents = DateComponents(year: 2026, month: 1, day: 4)
        let seedDate = Calendar.current.date(from: seedComponents)

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        let invoiceDate = seedDate.map { formatter.string(from: $0) } ?? "-"

        return [
            AdminResident(
                id: UUID(),
                name: "Leng Chingmony",
                email: "leng.chningmony@example.com",
                image: "Profile",
                defaultDue: "38.00",
                defaultPaymentType: .full,
                months: [
                    k: AdminResidentMonthRecord(
                        invoiceIssued: true,
                        isPaid: true,
                        paidDate: "01 Jan, 2026",
                        invoiceType: .full,
                        invoiceAmount: amount,
                        invoiceNumber: "INV-2026-01-001",
                        invoiceDate: invoiceDate
                    )
                ]
            )
            ,
            AdminResident(
                id: UUID(),
                name: "Sok Dara",
                email: "sok.dara@example.com",
                image: "Profile",
                defaultDue: "38.00",
                defaultPaymentType: .full,
                months: [
                    k: AdminResidentMonthRecord(
                        invoiceIssued: true,
                        isPaid: true,
                        paidDate: "03 Jan, 2026",
                        invoiceType: .full,
                        invoiceAmount: amount,
                        invoiceNumber: "INV-2026-01-002",
                        invoiceDate: invoiceDate
                    )
                ]
            ),
            AdminResident(
                id: UUID(),
                name: "Chan Theary",
                email: "chan.theary@example.com",
                image: "Profile",
                defaultDue: "38.00",
                defaultPaymentType: .full,
                months: [
                    k: AdminResidentMonthRecord(
                        invoiceIssued: true,
                        isPaid: true,
                        paidDate: "02 Jan, 2026",
                        invoiceType: .full,
                        invoiceAmount: amount,
                        invoiceNumber: "INV-2026-01-003",
                        invoiceDate: invoiceDate
                    )
                ]
            ),
            AdminResident(
                id: UUID(),
                name: "Phan Sopheak",
                email: "phan.sopheak@example.com",
                image: "Profile",
                defaultDue: "38.00",
                defaultPaymentType: .half,
                months: [
                    k: AdminResidentMonthRecord(
                        invoiceIssued: true,
                        isPaid: false,
                        paidDate: "-",
                        invoiceType: .half,
                        invoiceAmount: amount / 2,
                        invoiceNumber: "INV-2026-01-004",
                        invoiceDate: invoiceDate
                    )
                ]
            ),
            AdminResident(
                id: UUID(),
                name: "Kouern Doch",
                email: "kouern.doch@example.com",
                image: "Profile",
                defaultDue: "38.00",
                defaultPaymentType: .half,
                months: [
                    k: AdminResidentMonthRecord(
                        invoiceIssued: true,
                        isPaid: false,
                        paidDate: "-",
                        invoiceType: .half,
                        invoiceAmount: amount / 2,
                        invoiceNumber: "INV-2026-01-005",
                        invoiceDate: invoiceDate
                    )
                ]
            )
        ]
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
