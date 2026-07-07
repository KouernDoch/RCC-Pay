//
//  ContentView.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = DashboardViewModel()
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    DashboardChromeView(
                        displayName: session.displayName.isEmpty ? "RCC Member" : session.displayName,
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
                                selectedYear: $viewModel.selectedYear,
                                totalDue: viewModel.totalDue,
                                remain: viewModel.remaining,
                                paid: viewModel.paid,
                                isFullyPaid: viewModel.isFullyPaid,
                                remainingAmount: viewModel.remainingAmount,
                                isPaying: viewModel.isPaying,
                                onConfirmPaid: { Task { await viewModel.payRemaining() } }
                            )
                            .padding(.top, 4)

                            if let errorMessage = viewModel.errorMessage {
                                errorBanner(errorMessage)
                            }

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
                                if viewModel.isLoading {
                                    ProgressView().scaleEffect(0.7)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 14)
                            .padding(.bottom, 6)

                            // Cards
                            if viewModel.paymentModels.isEmpty && !viewModel.isLoading {
                                emptyState
                            } else {
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
                    .refreshable { await viewModel.load() }
                }
                .onChange(of: viewModel.selectedYear)  { _, _ in Task { await viewModel.reloadSummary() } }
                .onChange(of: viewModel.selectedMonth) { _, _ in Task { await viewModel.reloadSummary() } }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
            .task { await viewModel.load() }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundColor(.orange)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.12)))
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(lm["no_payments"])
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
        .environmentObject(SessionStore())
}
