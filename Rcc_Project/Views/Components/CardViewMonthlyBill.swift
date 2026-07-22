//
//  CardViewMonthlyBill.swift
//  Rcc_Project
//
//  The hero card on the user dashboard: what's owed this month, how much of it is
//  settled, and the action to pay it.
//
//  All inputs and callbacks are unchanged. The redesign leads with the *outstanding*
//  figure rather than giving three equal columns — that number is the only reason the
//  user opened the app — and adds a progress track so a partial payment is legible at
//  a glance instead of requiring arithmetic across two columns.
//

import SwiftUI

func generateYears(past: Int = 5, future: Int = 10) -> [Int] {
    let current = Calendar.current.component(.year, from: Date())
    return Array((current - past)...(current + future))
}

struct CardViewMonthlyBill: View {

    @Binding var selectedmonth: String
    @Binding var selectedYear: Int

    // Real figures from the backend monthly summary.
    var totalDue: String = "0.00"
    var remain: String = "0.00"
    var paid: String = "0.00"
    var isFullyPaid: Bool = false
    var remainingAmount: Double = 0
    var isPaying: Bool = false
    var onConfirmPaid: () -> Void = {}

    @State private var showQR = false
    @EnvironmentObject private var lm: LocalizationManager

    let years = generateYears()

    // MARK: - Derived presentation

    private var statusTone: DSTone { isFullyPaid ? .success : .warning }

    private var periodLabel: String {
        selectedmonth.isEmpty ? "—" : "\(selectedmonth) \(String(selectedYear))"
    }

    /// Amount strings arrive pre-formatted; parsed here only to draw the progress track.
    private func amount(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var settledFraction: CGFloat {
        let total = amount(totalDue)
        guard total > 0 else { return isFullyPaid ? 1 : 0 }
        return min(1, max(0, CGFloat(amount(paid) / total)))
    }

    /// The headline figure: what's left to pay, or the settled total once it's clear.
    private var heroValue: String { isFullyPaid ? "$\(totalDue)" : "$\(remain)" }
    private var heroCaption: String { isFullyPaid ? lm["paid"] : lm["remain"] }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            header
            hero
            progressTrack
            DSStatStrip(stats: [
                DSStat(label: lm["total_due"], value: "$\(totalDue)", tone: .brand),
                DSStat(label: lm["paid"],      value: "$\(paid)",     tone: .success),
                DSStat(label: lm["remain"],    value: "$\(remain)",   tone: .warning),
            ])
            payButton
        }
        .padding(DS.Space.md)
        .dsSurface(radius: DS.Radius.lg, elevation: .medium)
        .padding(.horizontal, DS.Space.page)
        .fullScreenCover(isPresented: $showQR) {
            PopUpViewQRCode(
                isShowingSheet: $showQR,
                payAmount: remainingAmount,
                onConfirmPaid: remainingAmount > 0 ? onConfirmPaid : nil)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lm["monthly_bill"])
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                Text(periodLabel)
                    .font(.dsTitle2)
                    .foregroundStyle(.primary)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: DS.Space.xs)

            VStack(alignment: .trailing, spacing: DS.Space.xs) {
                DSStatusBadge(
                    text: isFullyPaid ? lm["paid"] : lm["unpaid"],
                    tone: statusTone)

                yearPicker
            }
        }
        .animation(DS.Motion.fade, value: isFullyPaid)
    }

    private var yearPicker: some View {
        Menu {
            Picker(lm["admin_year"], selection: $selectedYear) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            }
        } label: {
            DSMenuChip(title: String(selectedYear))
        }
        .accessibilityLabel(lm["admin_year"])
        .accessibilityValue(String(selectedYear))
    }

    // MARK: - Hero figure

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(heroCaption.uppercased())
                .font(.system(.caption2, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(.secondary)

            Text(heroValue)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(isFullyPaid ? Color.dsSuccess : Color.primary)
                .contentTransition(.numericText())
                .dsNumeric()
                .animation(DS.Motion.smooth, value: heroValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(heroCaption) \(heroValue)")
    }

    // MARK: - Progress

    private var progressTrack: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(isFullyPaid ? Color.dsSuccess : Color.dsBrand)
                        .frame(width: geo.size.width * settledFraction)
                }
            }
            .frame(height: 6)
            .animation(DS.Motion.smooth, value: settledFraction)

            Text("\(Int((settledFraction * 100).rounded()))% \(lm["paid"].lowercased())")
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lm["paid"])
        .accessibilityValue("\(Int((settledFraction * 100).rounded())) percent")
    }

    // MARK: - Action

    private var payButton: some View {
        DSButton(
            title: isFullyPaid ? lm["paid"] : lm["pay_via_qr"],
            systemImage: isFullyPaid ? "checkmark.circle.fill" : "qrcode.viewfinder",
            role: .primary,
            isLoading: isPaying
        ) {
            showQR = true
        }
        .disabled(isFullyPaid || isPaying)
    }
}

// MARK: - Preview

#Preview("Partly paid") {
    CardViewMonthlyBill(
        selectedmonth: .constant("February"),
        selectedYear: .constant(2026),
        totalDue: "58.00",
        remain: "38.00",
        paid: "20.00",
        isFullyPaid: false,
        remainingAmount: 38)
    .padding(.vertical)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.dsBackground)
    .environmentObject(LocalizationManager())
}

#Preview("Settled") {
    CardViewMonthlyBill(
        selectedmonth: .constant("January"),
        selectedYear: .constant(2026),
        totalDue: "38.00",
        remain: "0.00",
        paid: "38.00",
        isFullyPaid: true)
    .padding(.vertical)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.dsBackground)
    .environmentObject(LocalizationManager())
}
