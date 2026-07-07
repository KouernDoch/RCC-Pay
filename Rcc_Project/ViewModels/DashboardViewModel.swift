//
//  DashboardViewModel.swift
//  RCC Pay
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    // Displayed data (driven by the backend).
    @Published var paymentModels: [PaymentModel] = []
    @Published var summary: InvoiceSummaryDTO?
    @Published var isLoading = false
    @Published var isPaying = false
    @Published var errorMessage: String?

    // Month/year selection (unchanged UI contract).
    @Published var selectedMonth: String
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    let months = Calendar.current.monthSymbols

    /// All of the current user's payments, cached so month switches don't re-fetch.
    private var allPayments: [PaymentDTO] = []

    init() {
        let monthIndex = Calendar.current.component(.month, from: Date()) - 1
        selectedMonth = Calendar.current.monthSymbols[monthIndex]
    }

    /// 1-based index of the selected month, defaulting to the current month.
    var selectedMonthIndex: Int {
        (months.firstIndex(of: selectedMonth) ?? (Calendar.current.component(.month, from: Date()) - 1)) + 1
    }

    var totalDue: String { DisplayFormat.money(summary?.totalDue ?? 0) }
    var remaining: String { DisplayFormat.money(summary?.remaining ?? 0) }
    var paid: String { DisplayFormat.money(summary?.totalPaid ?? 0) }
    var isFullyPaid: Bool { (summary?.remaining ?? 0) <= 0 && (summary?.invoiceCount ?? 0) > 0 }
    var remainingAmount: Double { summary?.remaining ?? 0 }

    /// Load the monthly bill summary and the user's payments in parallel.
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let summaryReq = BackendAPI.monthlySummary(year: selectedYear, month: selectedMonthIndex)
            async let paymentsReq = BackendAPI.listPayments()
            let (summary, payments) = try await (summaryReq, paymentsReq)
            self.summary = summary
            self.allPayments = payments
            rebuildPaymentModels()
        } catch is CancellationError {
            // Ignore — superseded by a newer load.
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Failed to load your dashboard."
        }
        isLoading = false
    }

    /// Refresh only the summary (after a month/year change) without refetching payments.
    func reloadSummary() async {
        do {
            summary = try await BackendAPI.monthlySummary(year: selectedYear, month: selectedMonthIndex)
            rebuildPaymentModels()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Failed to load the monthly bill."
        }
    }

    /// Pay down the remaining balance for the selected month via the backend.
    func payRemaining() async {
        guard remainingAmount > 0 else { return }
        isPaying = true
        errorMessage = nil
        do {
            _ = try await BackendAPI.payForCurrentUser(
                amount: remainingAmount,
                paidDate: DisplayFormat.today())
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Payment failed."
        }
        isPaying = false
    }

    private func rebuildPaymentModels() {
        let prefix = DisplayFormat.monthPrefix(year: selectedYear, month: selectedMonthIndex)
        let name = UserDefaults.standard.string(forKey: "displayName") ?? "You"
        paymentModels = allPayments
            .filter { ($0.paidDate ?? "").hasPrefix(prefix) }
            .map {
                PaymentModel(
                    image: "Profile",
                    name: name,
                    date: DisplayFormat.prettyDate($0.paidDate),
                    amount: DisplayFormat.money($0.paidAmount))
            }
    }
}
