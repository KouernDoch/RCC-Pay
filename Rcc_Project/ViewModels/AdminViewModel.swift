//
//  AdminViewModel.swift
//  RCC Pay
//
//  Backend-driven admin data. Keeps the same published surface the admin views bind to
//  (residents / paymentModels / counts / filters) but sources everything from the API and
//  routes every mutation through the backend, then reloads.
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

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var paymentModels: [PaymentModel] = []

    /// invoiceId → paymentId, used to reverse a payment when an admin un-marks "paid".
    private var paymentIdByInvoiceId: [Int: Int] = [:]
    private var settingsCancellable: AnyCancellable?

    let monthSymbols = Calendar.current.monthSymbols

    var currentKey: String { adminPeriodKey(year: filterYear, month: filterMonth) }

    var paidCount: Int { residents.filter { $0.months[currentKey]?.isPaid == true }.count }
    var unpaidCount: Int { max(0, residents.count - paidCount) }

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

    var residentsForInvoiceList: [AdminResident] {
        let key = currentKey
        switch invoiceTabFilter {
        case .all:    return residents
        case .paid:   return residents.filter { $0.months[key]?.isPaid == true }
        case .unpaid: return residents.filter { ($0.months[key]?.isPaid ?? false) == false }
        }
    }

    init() {
        settingsCancellable = NotificationCenter.default
            .publisher(for: AdminPaymentSettings.didChangeNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                for i in self.residents.indices {
                    self.residents[i].defaultDue = AdminPaymentSettings.fullAmountString
                }
            }
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

    // MARK: - Loading

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let usersReq = BackendAPI.listUsers()
            async let invoicesReq = BackendAPI.listInvoices()
            async let paymentsReq = BackendAPI.listPayments()
            let (users, invoices, payments) = try await (usersReq, invoicesReq, paymentsReq)
            rebuild(users: users, invoices: invoices, payments: payments)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Failed to load admin data."
        }
        isLoading = false
    }

    private func rebuild(users: [UserDTO], invoices: [InvoiceDTO], payments: [PaymentDTO]) {
        // Lookups
        var paymentByInvoice: [Int: PaymentDTO] = [:]
        paymentIdByInvoiceId = [:]
        for p in payments {
            paymentByInvoice[p.invoiceId] = p
            paymentIdByInvoiceId[p.invoiceId] = p.paymentId
        }
        let userById = Dictionary(uniqueKeysWithValues: users.map { ($0.userId, $0) })

        // Residents = non-admin users
        let residentUsers = users.filter { $0.role == .user }
        let halfAmount = AdminPaymentSettings.halfAmount

        residents = residentUsers.map { user in
            var months: [String: AdminResidentMonthRecord] = [:]
            for invoice in invoices where invoice.userId == user.userId {
                let (year, month) = Self.yearMonth(from: invoice.issueDate)
                let key = adminPeriodKey(year: year, month: month)
                let payment = paymentByInvoice[invoice.invoiceId]
                // Classify on this period's own charge — the total may also include a carried-forward
                // balance, which would otherwise make every half invoice look like a full one.
                let charge = invoice.currentCharge ?? invoice.amount
                let type: AdminInvoiceType = abs(charge - halfAmount) < 0.001 ? .half : .full
                let hasPayment = invoice.paidSoFar > 0
                months[key] = AdminResidentMonthRecord(
                    invoiceIssued: true,
                    isPaid: invoice.settlementStatus == .paid,
                    paidDate: hasPayment ? DisplayFormat.prettyDate(payment?.paidDate) : "-",
                    invoiceType: type,
                    invoiceAmount: invoice.amount,
                    invoiceNumber: String(format: "INV-%04d-%02d-%03d", year, month, invoice.invoiceId),
                    invoiceDate: DisplayFormat.prettyDate(invoice.issueDate),
                    invoiceId: invoice.invoiceId,
                    paidAmount: invoice.paidSoFar,
                    remainingAmount: invoice.outstanding,
                    previousUnpaidAmount: invoice.previousUnpaidAmount ?? 0)
            }
            return AdminResident(
                id: UUID(),
                userId: user.userId,
                name: user.name,
                email: user.email,
                image: "Profile",
                profileImage: user.profileImage,
                defaultDue: AdminPaymentSettings.fullAmountString,
                defaultPaymentType: storedPaymentType(for: user.userId),
                months: months)
        }

        // Daily payments feed
        paymentModels = payments.map { p in
            let payer = userById[p.invoiceOwnerUserId]
            return PaymentModel(
                image: "Profile",
                profileImage: payer?.profileImage,
                name: payer?.name ?? "User",
                date: DisplayFormat.prettyDate(p.paidDate),
                amount: DisplayFormat.money(p.paidAmount))
        }
    }

    // MARK: - Invoice issuing / status

    func issueInvoicesForCurrentPeriod() {
        let issueDate = DisplayFormat.issueDate(year: filterYear, month: filterMonth)
        let halfPayerIds = Set(
            residents.filter { $0.defaultPaymentType == .half }.map(\.userId))
        Task {
            isLoading = true
            errorMessage = nil
            do {
                // One call issues this period's invoice for every resident; the backend skips
                // anyone who already has one and returns only what it created.
                let result = try await BackendAPI.bulkIssue(
                    amount: AdminPaymentSettings.fullAmount,
                    issueDate: issueDate)

                // Bulk issuing bills a single flat amount, so half payers are corrected after the
                // fact. Any balance carried in from their previous invoice is still owed on top.
                let halfAmount = AdminPaymentSettings.halfAmount
                for invoice in result.invoices where halfPayerIds.contains(invoice.userId) {
                    _ = try await BackendAPI.updateInvoice(
                        id: invoice.invoiceId,
                        InvoiceUpdateRequestDTO(amount: halfAmount + (invoice.previousUnpaidAmount ?? 0)))
                }

                await loadAll()
                showIssuedAlert = true
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? "Failed to issue invoices."
                await loadAll()
            }
        }
    }

    func updateResidentInvoiceStatus(_ resident: AdminResident, to status: AdminInvoiceStatus) {
        let key = currentKey
        let rec = resident.months[key]
        let type = rec?.invoiceType ?? resident.defaultPaymentType
        let issueDate = DisplayFormat.issueDate(year: filterYear, month: filterMonth)
        Task {
            isLoading = true
            errorMessage = nil
            do {
                switch status {
                case .issuedUnpaid:
                    if rec?.invoiceId == nil {
                        _ = try await BackendAPI.createInvoice(InvoiceCreateRequestDTO(
                            userId: resident.userId,
                            amount: AdminPaymentSettings.amount(for: type),
                            issueDate: issueDate))
                    } else if (rec?.paidAmount ?? 0) > 0 {
                        // Covers partially paid invoices too, not just fully paid ones.
                        try await reversePayment(forInvoice: rec?.invoiceId)
                    }

                case .partiallyPaid:
                    // Not admin-selectable: it is the result of a partial payment. Nothing to do.
                    break

                case .paid:
                    var invoiceId = rec?.invoiceId
                    // Pay only what is still owed — the backend rejects anything above the remaining
                    // balance, so sending the full total would fail on a partially paid invoice.
                    var due = rec?.remainingAmount ?? 0
                    if invoiceId == nil {
                        let created = try await BackendAPI.createInvoice(InvoiceCreateRequestDTO(
                            userId: resident.userId,
                            amount: AdminPaymentSettings.amount(for: type),
                            issueDate: issueDate))
                        invoiceId = created.invoiceId
                        due = created.outstanding
                    }
                    if let invoiceId, due > 0 {
                        _ = try await BackendAPI.createPayment(
                            invoiceId: invoiceId,
                            paidAmount: due,
                            paidDate: DisplayFormat.nowLocalDateTime())
                    }

                case .pending:
                    if (rec?.paidAmount ?? 0) > 0 {
                        try await reversePayment(forInvoice: rec?.invoiceId)
                    }
                    if let invoiceId = rec?.invoiceId {
                        try await BackendAPI.deleteInvoice(id: invoiceId)
                    }
                }
                await loadAll()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? "Failed to update invoice."
                await loadAll()
            }
        }
    }

    private func reversePayment(forInvoice invoiceId: Int?) async throws {
        guard let invoiceId, let paymentId = paymentIdByInvoiceId[invoiceId] else { return }
        try await BackendAPI.deletePayment(id: paymentId)
    }

    // MARK: - Payment type (full / half)

    func setResidentPaymentType(_ resident: AdminResident, to newType: AdminInvoiceType) {
        // Persist the client-side preference and reflect it immediately.
        storePaymentType(newType, for: resident.userId)
        if let idx = residents.firstIndex(where: { $0.id == resident.id }) {
            residents[idx].defaultPaymentType = newType
        }
        // If there's an untouched invoice this month, update its amount on the backend to match.
        // Once money has been paid against it the backend refuses to drop the total below what is
        // already settled, so leave those alone.
        let key = currentKey
        if let rec = resident.months[key], let invoiceId = rec.invoiceId, rec.paidAmount == 0 {
            // The payment type sets this period's charge; any balance carried in from the previous
            // month is still owed on top of it.
            let amount = AdminPaymentSettings.amount(for: newType) + rec.previousUnpaidAmount
            Task {
                do {
                    _ = try await BackendAPI.updateInvoice(id: invoiceId, InvoiceUpdateRequestDTO(amount: amount))
                    await loadAll()
                } catch {
                    errorMessage = (error as? APIError)?.errorDescription ?? "Failed to update amount."
                }
            }
        }
    }

    // MARK: - Manage users

    func beginEdit(_ resident: AdminResident) {
        residentToEdit = resident
        draftName = resident.name
        draftEmail = resident.email
        draftImage = resident.image
        draftPaymentType = resident.defaultPaymentType
        showManageEditSheet = true
    }

    func cancelEditSheet() { showManageEditSheet = false }

    func saveEditSheet() {
        guard let editing = residentToEdit else { showManageEditSheet = false; return }
        let name = draftName
        let email = draftEmail
        let type = draftPaymentType
        showManageEditSheet = false
        storePaymentType(type, for: editing.userId)
        Task {
            isLoading = true
            errorMessage = nil
            do {
                _ = try await BackendAPI.updateUser(
                    id: editing.userId,
                    UserUpdateRequestDTO(name: name, email: email))
                await loadAll()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? "Failed to save user."
                await loadAll()
            }
        }
    }

    func requestDeleteResident(_ resident: AdminResident) {
        residentToDelete = resident
        showDeleteConfirmation = true
    }

    func clearPendingDelete() { residentToDelete = nil }

    func deleteResident() {
        guard let toDelete = residentToDelete else { return }
        residentToDelete = nil
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await BackendAPI.deleteUser(id: toDelete.userId)
                await loadAll()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? "Failed to delete user."
                await loadAll()
            }
        }
    }

    // MARK: - Helpers

    private func storedPaymentType(for userId: Int) -> AdminInvoiceType {
        let raw = UserDefaults.standard.string(forKey: "adminPaymentType_\(userId)")
        return raw == "half" ? .half : .full
    }

    private func storePaymentType(_ type: AdminInvoiceType, for userId: Int) {
        UserDefaults.standard.set(type.rawValue, forKey: "adminPaymentType_\(userId)")
    }

    private static func yearMonth(from issueDate: String) -> (Int, Int) {
        // issueDate: "yyyy-MM-dd"
        let parts = issueDate.split(separator: "-")
        let year = parts.count > 0 ? Int(parts[0]) ?? 0 : 0
        let month = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        return (year, month)
    }
}
