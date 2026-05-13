//
//  AdminViewModel.swift
//  RCC Pay
//

import Foundation
import Combine

@MainActor
final class AdminViewModel: ObservableObject {

    @Published var filterMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var filterYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonthLabel: String = ""
    @Published var residents: [AdminResident] = []
    @Published var showIssuedAlert = false
    @Published var userSearchText: String = ""
    @Published var selectedAdminTab: Int = 0

    @Published var showManageEditSheet = false
    @Published var residentToEdit: AdminResident?
    @Published var draftName: String = ""
    @Published var draftEmail: String = ""
    @Published var draftImage: String = "Profile"
    @Published var draftPaymentType: AdminInvoiceType = .full

    @Published var showDeleteConfirmation = false
    @Published var residentToDelete: AdminResident?

    @Published var invoiceTabFilter: AdminInvoiceTabFilter = .all

    @Published var paymentModels: [PaymentModel] = [
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00")
    ]

    let monthSymbols = Calendar.current.monthSymbols

    var currentKey: String {
        adminPeriodKey(year: filterYear, month: filterMonth)
    }

    var paidCount: Int {
        residents.filter { $0.months[currentKey]?.isPaid == true }.count
    }

    var unpaidCount: Int {
        max(0, residents.count - paidCount)
    }

    var paidResidents: [AdminResident] {
        residents.filter { $0.months[currentKey]?.isPaid == true }
    }

    var unpaidResidents: [AdminResident] {
        residents.filter { ($0.months[currentKey]?.isPaid ?? false) == false }
    }

    var filteredResidents: [AdminResident] {
        let q = userSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return residents }
        return residents.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// Residents shown on the Invoice tab for the current period and filter.
    var residentsForInvoiceList: [AdminResident] {
        let key = currentKey
        switch invoiceTabFilter {
        case .all:
            return residents
        case .paid:
            return residents.filter { $0.months[key]?.isPaid == true }
        case .unpaid:
            return residents.filter { ($0.months[key]?.isPaid ?? false) == false }
        }
    }

    init() {
        residents = Self.seedResidents()
    }

    func ensureSelectedMonthIfNeeded() {
        if selectedMonthLabel.isEmpty {
            selectedMonthLabel = monthSymbols[filterMonth - 1]
        }
    }

    func onChromeMonthSelected(_ month: Int) {
        filterMonth = month
        selectedMonthLabel = monthSymbols[month - 1]
    }

    func setResidentPaymentType(_ resident: AdminResident, to newType: AdminInvoiceType) {
        guard let idx = residents.firstIndex(where: { $0.id == resident.id }) else { return }
        residents[idx].defaultPaymentType = newType

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

    func beginEdit(_ resident: AdminResident) {
        residentToEdit = resident
        draftName = resident.name
        draftEmail = resident.email
        draftImage = resident.image
        draftPaymentType = resident.defaultPaymentType
        showManageEditSheet = true
    }

    func saveEditedResident() {
        guard let editing = residentToEdit else { return }
        guard let idx = residents.firstIndex(where: { $0.id == editing.id }) else { return }

        residents[idx].name = draftName
        residents[idx].email = draftEmail
        residents[idx].image = draftImage
        residents[idx].defaultPaymentType = draftPaymentType

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

    func cancelEditSheet() {
        showManageEditSheet = false
    }

    func saveEditSheet() {
        saveEditedResident()
        showManageEditSheet = false
    }

    func requestDeleteResident(_ resident: AdminResident) {
        residentToDelete = resident
        showDeleteConfirmation = true
    }

    func clearPendingDelete() {
        residentToDelete = nil
    }

    func deleteResident() {
        guard let toDelete = residentToDelete else { return }
        residents.removeAll { $0.id == toDelete.id }
        residentToDelete = nil
    }

    func issueInvoicesForCurrentPeriod() {
        let key = currentKey
        let invoiceDate = generateInvoiceDateString()
        for i in residents.indices {
            var m = residents[i].months[key] ?? AdminResidentMonthRecord(invoiceIssued: false, isPaid: false, paidDate: "-")

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

    func generateInvoiceNumber(residentIndex: Int) -> String {
        let monthPadded = String(format: "%02d", filterMonth)
        let idxPadded = String(format: "%03d", residentIndex + 1)
        return "INV-\(filterYear)-\(monthPadded)-\(idxPadded)"
    }

    func generateInvoiceDateString() -> String {
        var components = DateComponents()
        components.year = filterYear
        components.month = filterMonth
        components.day = 4

        guard let date = Calendar.current.date(from: components) else { return "-" }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

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
            ),
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
