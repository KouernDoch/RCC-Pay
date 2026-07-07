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
    @Environment(\.colorScheme) private var colorScheme

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

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
                            HStack(spacing: 8) {
                            
                                Text(lm["daily_payment"])
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.primary)

                            
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                            // Cards
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.paymentModels) { paymentModel in
                                    CardPayment(
                                        name: paymentModel.name,
                                        image: paymentModel.image,
                                        date: paymentModel.date,
                                        amount: paymentModel.amount
                                    )
                                }
                            }
                            .padding(.bottom, 24)
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

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemGroupedBackground)

            // Soft brand-tinted glow behind the top cards
            LinearGradient(
                colors: colorScheme == .dark
                    ? [blue.opacity(0.18), .clear]
                    : [blue.opacity(0.10), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
}
