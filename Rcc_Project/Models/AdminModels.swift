//
//  AdminModels.swift
//  RCC Pay
//

import Foundation

enum AdminInvoiceType: String, CaseIterable, Identifiable, Hashable {
    case full
    case half

    var id: String { rawValue }
}

/// Invoice tab list filter (paid / unpaid for the selected period).
enum AdminInvoiceTabFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case paid
    case unpaid

    var id: String { rawValue }
}

/// Editable invoice status for a resident in the selected month.
enum AdminInvoiceStatus: String, CaseIterable, Identifiable, Hashable {
    case pending
    case issuedUnpaid
    case paid

    var id: String { rawValue }
}

extension AdminResidentMonthRecord {
    var invoiceStatus: AdminInvoiceStatus {
        if isPaid { return .paid }
        if invoiceIssued { return .issuedUnpaid }
        return .pending
    }
}

struct AdminResidentMonthRecord: Equatable {
    var invoiceIssued: Bool
    var isPaid: Bool
    var paidDate: String
    var invoiceType: AdminInvoiceType? = nil
    var invoiceAmount: Double? = nil
    var invoiceNumber: String? = nil
    var invoiceDate: String? = nil
    /// Backend invoice id for this resident/month (nil when no invoice exists yet).
    var invoiceId: Int? = nil
}

struct AdminResident: Identifiable {
    let id: UUID
    /// Backend user id — the stable key for API calls.
    var userId: Int = 0
    var name: String
    var email: String
    var image: String
    var defaultDue: String
    var defaultPaymentType: AdminInvoiceType
    var months: [String: AdminResidentMonthRecord]
}

func adminPeriodKey(year: Int, month: Int) -> String {
    "\(year)-\(month)"
}

/// Global full / half payment amounts configured by admin in Settings.
enum AdminPaymentSettings {
    static let fullAmountKey = "adminFullPaymentAmount"
    static let halfAmountKey = "adminHalfPaymentAmount"
    static let didChangeNotification = Notification.Name("AdminPaymentSettingsDidChange")

    static let defaultFull = "38.00"
    static let defaultHalf = "19.00"

    static var fullAmountString: String {
        get { UserDefaults.standard.string(forKey: fullAmountKey) ?? defaultFull }
        set { UserDefaults.standard.set(newValue, forKey: fullAmountKey) }
    }

    static var halfAmountString: String {
        get { UserDefaults.standard.string(forKey: halfAmountKey) ?? defaultHalf }
        set { UserDefaults.standard.set(newValue, forKey: halfAmountKey) }
    }

    static var fullAmount: Double {
        parseAmount(fullAmountString) ?? 38.0
    }

    static var halfAmount: Double {
        parseAmount(halfAmountString) ?? 19.0
    }

    static func amount(for type: AdminInvoiceType) -> Double {
        type == .half ? halfAmount : fullAmount
    }

    static func formattedAmount(for type: AdminInvoiceType) -> String {
        String(format: "%.2f", amount(for: type))
    }

    @discardableResult
    static func save(full: String, half: String) -> Bool {
        guard let fullValue = parseAmount(full), fullValue > 0,
              let halfValue = parseAmount(half), halfValue > 0 else { return false }

        fullAmountString = String(format: "%.2f", fullValue)
        halfAmountString = String(format: "%.2f", halfValue)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
        return true
    }

    private static func parseAmount(_ text: String) -> Double? {
        let trimmed = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
}
