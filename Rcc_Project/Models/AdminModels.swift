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

func adminPeriodKey(year: Int, month: Int) -> String {
    "\(year)-\(month)"
}
