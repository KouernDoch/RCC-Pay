//
//  ContentView.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @StateObject private var viewModel = DashboardViewModel()
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    DashboardChromeView(
                        displayName: "Kouern Doch",
                        roleSubtitle: lm["normal_user"],
                        onMonthSelected: { selectedDate in
                            viewModel.selectedMonth = viewModel.months[selectedDate - 1]
                        }
                    )

                    // ── Scrollable content ────────────────────────
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            CardViewMonthlyBill(
                                selectedmonth: $viewModel.selectedMonth,
                                selectedYear: $viewModel.selectedYear
                            )
                            .padding(.top, 4)

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
                                ForEach(viewModel.paymentModels) { paymentModel in
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
                }
                .onChange(of: viewModel.selectedYear)  { _, _ in }
                .onChange(of: viewModel.selectedMonth) { _, _ in }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
}
