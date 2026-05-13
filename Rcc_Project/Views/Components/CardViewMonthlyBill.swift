//
//  CardViewMonthlyBill.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

func generateYears(past: Int = 5, future: Int = 10) -> [Int] {
    let current = Calendar.current.component(.year, from: Date())
    return Array((current - past)...(current + future))
}

struct CardViewMonthlyBill: View {
    @Binding var selectedmonth: String
    @Binding var selectedYear: Int

    @State private var showQR = false
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    let years = generateYears()

    private let blue  = Color(red: 0.22, green: 0.50, blue: 0.98)
    private let mint  = Color(red: 0.18, green: 0.75, blue: 0.48)
    private let amber = Color(red: 1.0,  green: 0.60, blue: 0.15)

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ───────────────────────────────────────
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lm["monthly_bill"])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text(selectedmonth.isEmpty ? "—" : "\(selectedmonth) \(String(selectedYear))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Paid badge
                    HStack(spacing: 4) {
                        Circle().fill(mint).frame(width: 6, height: 6)
                        Text(lm["paid"])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(mint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(mint.opacity(colorScheme == .dark ? 0.2 : 0.1)))

                    // Year picker
                    Menu {
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(String(selectedYear))
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(blue.opacity(colorScheme == .dark ? 0.18 : 0.09)))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // ── Stats grid ───────────────────────────────────
            HStack(spacing: 0) {
                statItem(label: lm["total_due"], value: "38.00", color: blue)
                stripDivider
                statItem(label: lm["remain"],    value: "0.00",  color: amber)
                stripDivider
                statItem(label: lm["paid"],      value: "38.00", color: mint)
            }
            .padding(.vertical, 16)

            // ── QR Button ────────────────────────────────────
           
            Button { showQR = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 14, weight: .semibold))
                    Text(lm["pay_via_qr"])
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(blue)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .fullScreenCover(isPresented: $showQR){
                PopUpViewQRCode(isShowingSheet: $showQR)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text("$\(value)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Strip Divider

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.13))
            .frame(width: 1, height: 30)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
}
