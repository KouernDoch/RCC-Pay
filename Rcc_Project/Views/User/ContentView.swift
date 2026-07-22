//
//  ContentView.swift
//  Rcc_Project
//
//  The resident's dashboard: this month's bill, and the payments made against it.
//
//  Data flow is untouched — the same `DashboardViewModel`, the same load / reload /
//  pay calls. What changed is the presentation of the states around that data: the
//  first load now shows skeletons shaped like the real content instead of a bare
//  screen, a failed refresh surfaces inline (it was commented out before) rather
//  than failing silently, and the empty feed explains itself.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showManualUpdate = false

    /// True only for the very first load, when there's nothing to show underneath.
    /// A pull-to-refresh keeps the existing content and uses the section spinner instead.
    private var isInitialLoad: Bool {
        viewModel.isLoading && viewModel.summary == nil && viewModel.paymentModels.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    DashboardChromeView(
                        displayName: session.displayName.isEmpty ? "RCC Member" : session.displayName,
                        roleSubtitle: lm["normal_user"],
                        onMonthSelected: { selectedDate in
                            viewModel.selectedMonth = viewModel.months[selectedDate - 1]
                        }
                    )

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: DS.Space.md) {
                            if isInitialLoad {
                                loadingContent
                            } else {
                                loadedContent
                            }
                        }
                        .padding(.top, DS.Space.xs)
                        .padding(.bottom, DS.Space.xxl)
                        .animation(DS.Motion.smooth, value: isInitialLoad)
                    }
                    .refreshable { await viewModel.load() }
                    .scrollDismissesKeyboard(.immediately)
                }
                .onChange(of: viewModel.selectedYear)  { _, _ in Task { await viewModel.reloadSummary() } }
                .onChange(of: viewModel.selectedMonth) { _, _ in Task { await viewModel.reloadSummary() } }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
            .task { await viewModel.load() }
        }
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: DS.Space.md) {
            DSSkeletonCard()
                .padding(.horizontal, DS.Space.page)
            DSSkeletonList(count: 3)
                .padding(.horizontal, DS.Space.page)
        }
        .transition(.opacity)
    }

    // MARK: - Loaded

    private var loadedContent: some View {
        VStack(spacing: DS.Space.md) {

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

            manualUpdateButton

            // Previously commented out, so a failed refresh left the user staring at
            // stale figures with no explanation.
            if let errorMessage = viewModel.errorMessage {
                DSInlineError(message: errorMessage) {
                    Task { await viewModel.load() }
                }
                .padding(.horizontal, DS.Space.page)
            }

            paymentSection
        }
        .transition(.opacity)
    }

    // MARK: - Payment feed

    private var paymentSection: some View {
        VStack(spacing: DS.Space.xs) {
            DSSectionHeader(
                title: lm["daily_payment"],
                subtitle: viewModel.paymentModels.isEmpty
                    ? nil
                    : "\(viewModel.paymentModels.count)",
                isLoading: viewModel.isLoading
            )
            .padding(.horizontal, DS.Space.page)
            .padding(.top, DS.Space.xxs)

            if viewModel.paymentModels.isEmpty {
                DSEmptyState(
                    title: lm["no_payments"],
                    message: lm["update_payment_manually_hint"],
                    systemImage: "tray")
            } else {
                LazyVStack(spacing: DS.Space.xs) {
                    ForEach(viewModel.paymentModels) { paymentModel in
                        CardPayment(
                            name: paymentModel.name,
                            image: paymentModel.image,
                            profileImage: paymentModel.profileImage,
                            date: paymentModel.date,
                            amount: paymentModel.amount
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(DS.Motion.smooth, value: viewModel.paymentModels.count)
            }
        }
    }

    // MARK: - Manual update

    /// Lets the user record the payment themselves after they've paid with the QR code.
    private var manualUpdateButton: some View {
        DSButton(
            title: lm["update_payment_manually"],
            systemImage: "square.and.pencil",
            role: .secondary
        ) {
            showManualUpdate = true
        }
        .disabled(viewModel.isPaying)
        .padding(.horizontal, DS.Space.page)
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
}

// MARK: - Manual payment sheet

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

    /// Guard against recording more than is actually owed.
    private var exceedsRemaining: Bool {
        guard let amount, remainingAmount > 0 else { return false }
        return amount > remainingAmount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.md) {
                        amountCard

                        if remainingAmount > 0 {
                            DSButton(
                                title: lm["use_remaining_amount"],
                                systemImage: "equal.circle",
                                role: .secondary
                            ) {
                                withAnimation(DS.Motion.quick) {
                                    amountText = String(format: "%.2f", remainingAmount)
                                }
                            }
                        }

                        if exceedsRemaining {
                            DSCallout(
                                message: "That's more than the $\(String(format: "%.2f", remainingAmount)) still outstanding.",
                                tone: .warning)
                        }

                        Text(lm["update_payment_manually_hint"])
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.Space.xxs)
                    }
                    .padding(DS.Space.page)
                    .animation(DS.Motion.fade, value: exceedsRemaining)
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
                    .fontWeight(.semibold)
                    .disabled(amount == nil)
                }
            }
            .onAppear {
                if remainingAmount > 0 { amountText = String(format: "%.2f", remainingAmount) }
                amountFocused = true
            }
        }
    }

    /// A large, centred amount field — the only thing this sheet exists to collect.
    private var amountCard: some View {
        VStack(spacing: DS.Space.xs) {
            Text(lm["amount_paid"].uppercased())
                .font(.system(.caption2, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: DS.Space.xxs) {
                Text("$")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .focused($amountFocused)
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.lg)
        .padding(.horizontal, DS.Space.md)
        .dsSurface(radius: DS.Radius.lg, elevation: .low)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
        .environmentObject(SessionStore())
}
