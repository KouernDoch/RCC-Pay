//
//  AdminInvoiceCard.swift
//  Rcc_Project
//
//  One resident's invoice for the selected month.
//
//  Same inputs and the same status-menu behaviour (still only editable once an invoice
//  exists). The layout now leads with the outstanding balance and folds the invoice
//  number and date into a quieter metadata block — on the old card, "No" and "Date" were
//  given the same visual weight as the amount, which buried the figure that matters.
//

import SwiftUI

struct AdminInvoiceCard: View {

    @EnvironmentObject private var lm: LocalizationManager

    let resident: AdminResident
    let record: AdminResidentMonthRecord?
    var onStatusSelected: ((AdminInvoiceStatus) -> Void)? = nil

    // MARK: - Derived

    private var emailLine: String {
        resident.email.isEmpty ? "user@example.com" : resident.email
    }

    private var currentStatus: AdminInvoiceStatus {
        record?.invoiceStatus ?? .pending
    }

    private func statusLabel(_ status: AdminInvoiceStatus) -> String {
        switch status {
        case .pending:       return lm["admin_status_pending"]
        case .issuedUnpaid:  return lm["admin_status_issued_unpaid"]
        case .partiallyPaid: return lm["admin_status_partially_paid"]
        case .paid:          return lm["admin_status_paid"]
        }
    }

    private func statusTone(_ status: AdminInvoiceStatus) -> DSTone {
        switch status {
        case .pending:       return .neutral
        case .issuedUnpaid:  return .warning
        case .partiallyPaid: return .brand
        case .paid:          return .success
        }
    }

    private var amountText: String {
        guard let record, let amount = record.invoiceAmount else { return "-" }
        return String(format: "%.2f", amount)
    }

    private var noText: String   { record?.invoiceNumber ?? "-" }
    private var dateText: String { record?.invoiceDate ?? "-" }
    private var paidText: String { String(format: "%.2f", record?.paidAmount ?? 0) }
    private var remainingText: String { String(format: "%.2f", record?.remainingAmount ?? 0) }

    /// Shown once money has been paid but the invoice is not settled.
    private var showsBalanceBreakdown: Bool { currentStatus == .partiallyPaid }

    /// Shown when this invoice absorbed an unpaid balance from the previous month.
    private var carriedInText: String? {
        guard let carried = record?.previousUnpaidAmount, carried > 0 else { return nil }
        return String(format: "%.2f", carried)
    }

    /// Progress toward settling this invoice, for the partial-payment track.
    private var settledFraction: CGFloat {
        guard let record, let total = record.invoiceAmount, total > 0 else { return 0 }
        return min(1, max(0, CGFloat(record.paidAmount / total)))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            header

            Divider().overlay(Color.dsSeparator.opacity(0.4))

            amountBlock

            if showsBalanceBreakdown {
                partialBreakdown
            }

            metadata

            if let carriedInText {
                carriedForwardNote(carriedInText)
            }
        }
        .padding(DS.Space.sm + 2)
        .dsSurface(radius: DS.Radius.lg, elevation: .low)
        .animation(DS.Motion.smooth, value: currentStatus)
    }

    // MARK: - Header

    private var header: some View {
        DSPersonRow(
            name: resident.name,
            subtitle: emailLine,
            imageURL: resident.profileImage,
            placeholder: resident.image,
            avatarSize: .md
        ) {
            statusBadge
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        // Pending means no invoice exists yet — there is nothing to re-status, so the
        // badge stays inert until one is issued.
        let isStatusEditable = currentStatus != .pending

        let badge = DSStatusBadge(
            text: statusLabel(currentStatus),
            tone: statusTone(currentStatus),
            isInteractive: onStatusSelected != nil && isStatusEditable)

        if let onStatusSelected, isStatusEditable {
            Menu {
                Picker(
                    lm["admin_invoice_status_header"],
                    selection: Binding(
                        get: { currentStatus },
                        set: { onStatusSelected($0) })
                ) {
                    ForEach(AdminInvoiceStatus.selectableCases) { option in
                        Text(statusLabel(option)).tag(option)
                    }
                }
            } label: {
                badge
            }
            .accessibilityLabel(lm["admin_invoice_status_header"])
            .accessibilityValue(statusLabel(currentStatus))
        } else {
            badge
        }
    }

    // MARK: - Amount

    private var amountBlock: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                // The old card labelled this column with a hard-coded English "Amount".
                // `total_due` carries the same meaning and is already translated.
                Text(lm["total_due"])
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)

                Text("$\(amountText)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .dsNumeric()
            }

            Spacer(minLength: DS.Space.xs)

            if currentStatus == .paid {
                Label(lm["admin_status_paid"], systemImage: "checkmark.seal.fill")
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsSuccess)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    // MARK: - Partial payment

    private var partialBreakdown: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(Color.dsBrand)
                        .frame(width: geo.size.width * settledFraction)
                }
            }
            .frame(height: 5)
            .animation(DS.Motion.smooth, value: settledFraction)

            HStack(spacing: 0) {
                DSMetricRow(
                    label: lm["admin_invoice_paid_amount"],
                    value: "$\(paidText)",
                    tone: .success)
                Spacer(minLength: DS.Space.md)
                DSMetricRow(
                    label: lm["admin_invoice_remaining"],
                    value: "$\(remainingText)",
                    tone: .warning)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Metadata

    private var metadata: some View {
        VStack(spacing: DS.Space.xxs + 1) {
            DSMetricRow(label: lm["admin_invoice_no"], value: noText, systemImage: "number")
            DSMetricRow(label: lm["admin_invoice_date"], value: dateText, systemImage: "calendar")
        }
    }

    private func carriedForwardNote(_ text: String) -> some View {
        HStack(spacing: DS.Space.xxs + 2) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(.caption2, weight: .bold))
            Text("\(lm["admin_invoice_carried_forward"]) $\(text)")
                .font(.dsCaption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, DS.Space.xs)
        .padding(.vertical, DS.Space.xs)
        .dsAccentSurface(.dsNeutral, radius: DS.Radius.xs, intensity: 0.08)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DS.Space.sm) {
            AdminInvoiceCard(
                resident: AdminResident(id: UUID(), name: "Leng Chingmony", email: "leng.chingmony@example.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .full, months: [:]),
                record: AdminResidentMonthRecord(invoiceIssued: true, isPaid: true, paidDate: "01 Jan 2026", invoiceType: .full, invoiceAmount: 38.0, invoiceNumber: "INV-2026-01-001", invoiceDate: "04 January 2026", paidAmount: 38.0, remainingAmount: 0),
                onStatusSelected: { _ in })

            AdminInvoiceCard(
                resident: AdminResident(id: UUID(), name: "Phan Sopheak", email: "phan.sopheak@example.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .half, months: [:]),
                record: AdminResidentMonthRecord(invoiceIssued: true, isPaid: false, paidDate: "-", invoiceType: .full, invoiceAmount: 38.0, invoiceNumber: "INV-2026-01-004", invoiceDate: "04 January 2026", paidAmount: 0, remainingAmount: 38.0),
                onStatusSelected: { _ in })

            // Partially paid, with a balance carried in from the previous month.
            AdminInvoiceCard(
                resident: AdminResident(id: UUID(), name: "Kouern Doch", email: "doch@rcc.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .full, months: [:]),
                record: AdminResidentMonthRecord(invoiceIssued: true, isPaid: false, paidDate: "12 Feb 2026", invoiceType: .full, invoiceAmount: 58.0, invoiceNumber: "INV-2026-02-007", invoiceDate: "01 February 2026", paidAmount: 20.0, remainingAmount: 38.0, previousUnpaidAmount: 20.0),
                onStatusSelected: { _ in })

            AdminInvoiceCard(
                resident: AdminResident(id: UUID(), name: "New Resident", email: "new@rcc.com", image: "Profile", defaultDue: "38.00", defaultPaymentType: .full, months: [:]),
                record: nil)
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
    .environmentObject(LocalizationManager())
}
