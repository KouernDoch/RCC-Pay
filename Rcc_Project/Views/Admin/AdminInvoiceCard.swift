//
//  AdminInvoiceCard.swift
//  Rcc_Project
//

import SwiftUI

struct AdminInvoiceCard: View {
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    let resident: AdminResident
    let record: AdminResidentMonthRecord?
    var onStatusSelected: ((AdminInvoiceStatus) -> Void)? = nil

    // MARK: - Computed helpers

    private var emailLine: String {
        resident.email.isEmpty ? "user@example.com" : resident.email
    }

    private var currentStatus: AdminInvoiceStatus {
        record?.invoiceStatus ?? .pending
    }

    private func statusLabel(_ status: AdminInvoiceStatus) -> String {
        switch status {
        case .pending: return lm["admin_status_pending"]
        case .issuedUnpaid: return lm["admin_status_issued_unpaid"]
        case .paid: return lm["admin_status_paid"]
        }
    }

    private func statusColor(_ status: AdminInvoiceStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .issuedUnpaid: return Color(red: 1.00, green: 0.60, blue: 0.15)
        case .paid: return Color(red: 0.18, green: 0.75, blue: 0.48)
        }
    }

    private var statusInfo: (text: String, color: Color) {
        let status = currentStatus
        return (statusLabel(status), statusColor(status))
    }

    private var amountText: String {
        guard let record, let amount = record.invoiceAmount else { return "-" }
        return String(format: "%.2f", amount)
    }

    private var noText: String   { record?.invoiceNumber ?? "-" }
    private var dateText: String { record?.invoiceDate ?? "-" }

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── Header row ──────────────────────────────────────
            HStack(alignment: .center, spacing: 12) {

                Image(resident.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(resident.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(emailLine)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                statusBadge
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Thin separator ───────────────────────────────────
            Rectangle()
                .fill(Color.gray.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // ── Stats grid (Amount / No / Date) ─────────────────
            HStack(spacing: 0) {
                statItem(label: "Amount", value: "$\(amountText)", color: blue, valueFontSize: 13)
                stripDivider
                statItem(label: lm["admin_invoice_no"], value: noText, color: .primary, valueFontSize: 13)
                stripDivider
                statItem(label: lm["admin_invoice_date"], value: dateText, color: .primary, valueFontSize: 13)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark ? .clear : Color.black.opacity(0.06),
            radius: 12, x: 0, y: 4
        )
//        .padding(.horizontal)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusBadge: some View {
        let isStatusEditable = currentStatus != .pending

        let badge = HStack(spacing: 5) {
            Circle()
                .fill(statusInfo.color)
                .frame(width: 6, height: 6)
            Text(statusInfo.text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(statusInfo.color)
            if onStatusSelected != nil, isStatusEditable {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(statusInfo.color.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(statusInfo.color.opacity(colorScheme == .dark ? 0.20 : 0.10)))

        if let onStatusSelected, isStatusEditable {
            Menu {
                ForEach(AdminInvoiceStatus.allCases) { option in
                    Button {
                        onStatusSelected(option)
                    } label: {
                        HStack {
                            Text(statusLabel(option))
                            Spacer(minLength: 8)
                            if currentStatus == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                    }
                }
            } label: {
                badge
            }
        } else {
            badge
        }
    }

    @ViewBuilder
    private func statItem(
        label: String,
        value: String,
        color: Color,
        valueFontSize: CGFloat
    ) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.13))
            .frame(width: 1, height: 32)
    }
}

#Preview {
    VStack(spacing: 12) {
        AdminInvoiceCard(
            resident: AdminResident(id: UUID(), name: "Leng Chingmony", email: "leng.chingmony@example.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .full, months: [:]),
            record: AdminResidentMonthRecord(invoiceIssued: true, isPaid: true, paidDate: "01 Jan 2026", invoiceType: .full, invoiceAmount: 38.0, invoiceNumber: "INV-2026-01-001", invoiceDate: "04 January 2026")
        )
        AdminInvoiceCard(
            resident: AdminResident(id: UUID(), name: "Phan Sopheak", email: "phan.sopheak@example.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .half, months: [:]),
            record: AdminResidentMonthRecord(invoiceIssued: true, isPaid: false, paidDate: "-", invoiceType: .full, invoiceAmount: 38.0, invoiceNumber: "INV-2026-01-004", invoiceDate: "04 January 2026")
        )
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
    .environmentObject(LocalizationManager())
}
