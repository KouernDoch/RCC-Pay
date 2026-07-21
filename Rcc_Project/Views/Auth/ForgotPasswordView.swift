
//
//  ForgotPasswordView.swift
//  RCC Pay
//
//  Container for the password-reset flow. It owns the shared chrome — header, card,
//  back button, step pills — and swaps in the screen for the current step. All state
//  and networking live in ForgotPasswordViewModel; the step views are stateless.
//
//  Flow: Login → Email → OTP → New password → Success → Login
//

import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @StateObject private var vm = ForgotPasswordViewModel()

    /// Seeded from the login screen so the user doesn't retype an address they just typed.
    var prefilledEmail: String = ""

    /// Called once the password has actually been changed, so the login screen can
    /// confirm it. Fires when the user leaves the success step.
    var onPasswordReset: () -> Void = {}

    @State private var appeared = false
    @State private var shake = false

    private let screenH = UIScreen.main.bounds.height
    private var palette: FPPalette { FPPalette(scheme) }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            palette.pageBackground.ignoresSafeArea()

            headerView.ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: screenH * 0.36)
                    formCard.padding(.top, -52)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)

            topBar
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.prefill(email: prefilledEmail)
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
        // The countdown is a live Task; without this it keeps ticking after the user leaves.
        .onDisappear { vm.stopCountdown() }
        // Shake is presentation-only, so it's driven here rather than from the ViewModel.
        // Keyed on the nonce so a repeat of the same error still animates.
        .onChange(of: vm.errorNonce) { _, _ in triggerShake() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            if vm.step != .success {
                Button {
                    // The ViewModel decides whether there's a step to fall back to;
                    // `false` means we're at the start of the flow, so leave it.
                    if !vm.goBack() { dismiss() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text(lm["back"])
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
            }

            Spacer()

            if vm.step != .success {
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(vm.step.rawValue >= index ? 1.0 : 0.3))
                            .frame(width: vm.step.rawValue == index ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.step)
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.25), value: vm.step)
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            FPBottomWave()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.30, blue: 0.88),
                            Color(red: 0.22, green: 0.52, blue: 1.00),
                            FPPalette.sky,
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing))

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 220)
                .offset(x: 90, y: -screenH * 0.36 * 0.22)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 150)
                .offset(x: -100, y: screenH * 0.36 * 0.05)

            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 76)
                    Circle().fill(Color.white.opacity(0.22)).frame(width: 58)
                    Image(systemName: headerIcon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 6)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.bottom, 44)
        }
        .frame(height: screenH * 0.36, alignment: .top)
    }

    private var headerIcon: String {
        switch vm.step {
        case .email:   return "lock.rotation"
        case .otp:     return "envelope.badge.shield.half.filled"
        case .reset:   return "key.fill"
        case .success: return "checkmark.shield.fill"
        }
    }

    // MARK: - Card

    private var formCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32).fill(Color(.systemBackground))
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [FPPalette.blue.opacity(palette.isDark ? 0.20 : 0.08),
                                 FPPalette.blue.opacity(palette.isDark ? 0.06 : 0.02),
                                 Color.clear],
                        startPoint: .top, endPoint: .center))

            Circle()
                .fill(FPPalette.blue.opacity(0.05))
                .frame(width: 200)
                .offset(x: 80, y: -50)
                .blur(radius: 2)
            Circle()
                .fill(FPPalette.sky.opacity(0.05))
                .frame(width: 110)
                .offset(x: -50, y: 90)

            stepContent
                .padding(.horizontal, 26)
                .padding(.top, 32)
                .padding(.bottom, 44)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [FPPalette.blue.opacity(0.22), FPPalette.blue.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
        )
        .shadow(color: FPPalette.blue.opacity(0.16), radius: 20, x: 0, y: -10)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch vm.step {
            case .email:
                FPEmailStepView(vm: vm, palette: palette, shake: shake)
            case .otp:
                FPOtpStepView(vm: vm, palette: palette, shake: shake)
            case .reset:
                FPResetStepView(vm: vm, palette: palette, shake: shake)
            case .success:
                FPSuccessStepView(palette: palette) {
                    onPasswordReset()
                    dismiss()
                }
            }
        }
        // Forward steps slide in from the trailing edge, back steps from the leading one.
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)))
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: vm.step)
    }

    // MARK: - Helpers

    private func triggerShake() {
        withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { shake = false }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(LocalizationManager())
    }
}
