
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
//  The ViewModel contract is untouched: same `goBack`, same `stopCountdown` on
//  disappear, same shake driven off `errorNonce`. Only the chrome changed — it now
//  comes from `AuthScaffold`, shared with Login and Sign Up.
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

    @State private var shake = false

    private var palette: FPPalette { FPPalette(scheme) }

    // MARK: - Body

    var body: some View {
        AuthScaffold(
            systemImage: headerIcon,
            title: nil,
            subtitle: nil,
            isCompact: true,
            accessory: { topBar },
            content: { stepContent })
        .navigationBarHidden(true)
        .onAppear { vm.prefill(email: prefilledEmail) }
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
                AuthBackButton(title: lm["back"]) {
                    // The ViewModel decides whether there's a step to fall back to;
                    // `false` means we're at the start of the flow, so leave it.
                    if !vm.goBack() { dismiss() }
                }
            }

            Spacer()

            if vm.step != .success {
                AuthStepPills(current: vm.step.rawValue, total: 3)
            }
        }
        .animation(DS.Motion.fade, value: vm.step)
    }

    private var headerIcon: String {
        switch vm.step {
        case .email:   return "lock.rotation"
        case .otp:     return "envelope.badge.shield.half.filled"
        case .reset:   return "key.fill"
        case .success: return "checkmark.shield.fill"
        }
    }

    // MARK: - Step content

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
        .animation(DS.Motion.smooth, value: vm.step)
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
