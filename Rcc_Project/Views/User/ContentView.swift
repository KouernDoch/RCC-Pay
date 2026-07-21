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
    @State private var showManualUpdate = false

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

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

                            manualUpdateButton

//                            if let errorMessage = viewModel.errorMessage {
//                                errorBanner(errorMessage)
//                            }

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
                                            profileImage: paymentModel.profileImage,
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

//    private func errorBanner(_ message: String) -> some View {
//        HStack(spacing: 8) {
//            Image(systemName: "exclamationmark.triangle.fill")
//            Text(message).font(.system(size: 12, weight: .medium))
//            Spacer()
//        }
//        .foregroundColor(.orange)
//        .padding(12)
//        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.12)))
//        .padding(.horizontal)
//        .padding(.top, 10)
//    }

    /// Lets the user record the payment themselves after they've paid with the QR code.
    private var manualUpdateButton: some View {
        Button { showManualUpdate = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13, weight: .semibold))
                Text(lm["update_payment_manually"])
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(blue.opacity(0.4), lineWidth: 1)
            )
        }
        .disabled(viewModel.isPaying)
        .opacity(viewModel.isPaying ? 0.5 : 1)
        .padding(.horizontal)
        .padding(.top, 10)
        .sheet(isPresented: $showManualUpdate) {
            ManualPaymentUpdateSheet(
                remainingAmount: viewModel.remainingAmount,
                onSubmit: { amount in
                    Task { await viewModel.pay(amount: amount) }
                }
            )
            .environmentObject(lm)
        }
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

/// Amount entry for a payment the user made outside the app (via the QR code).
struct ManualPaymentUpdateSheet: View {

    let remainingAmount: Double
    let onSubmit: (Double) -> Void

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""
    @FocusState private var amountFocused: Bool

    private var amount: Double? {
        let value = Double(amountText.trimmingCharacters(in: .whitespaces))
        guard let value, value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("$")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 17, weight: .semibold))
                            .focused($amountFocused)
                    }
                } header: {
                    Text(lm["amount_paid"])
                } footer: {
                    Text(lm["update_payment_manually_hint"])
                }

                if remainingAmount > 0 {
                    Section {
                        Button(lm["use_remaining_amount"]) {
                            amountText = String(format: "%.2f", remainingAmount)
                        }
                    }
                }
            }
            .navigationTitle(lm["update_payment_manually"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["confirm"]) {
                        guard let amount else { return }
                        onSubmit(amount)
                        dismiss()
                    }
                    .disabled(amount == nil)
                }
            }
            .onAppear {
                if remainingAmount > 0 { amountText = String(format: "%.2f", remainingAmount) }
                amountFocused = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
        .environmentObject(SessionStore())
}
