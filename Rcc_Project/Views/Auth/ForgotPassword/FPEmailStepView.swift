//
//  FPEmailStepView.swift
//  RCC Pay
//
//  Step 1 of 3 — collect the account's email address and ask the backend to send an OTP.
//

import SwiftUI

struct FPEmailStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @ObservedObject var vm: ForgotPasswordViewModel
    let palette: FPPalette
    let shake: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 26) {
            FPHeading(title: lm["fp_step1_title"],
                      subtitle: lm["fp_step1_subtitle"],
                      palette: palette)

            FPFieldContainer {
                HStack(spacing: 14) {
                    FPFieldIcon(systemName: "envelope.fill", isActive: isFocused)
                    TextField(lm["ph_email"], text: $vm.email)
                        .focused($isFocused)
                        .font(.system(size: 15))
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.send)
                        .onSubmit(submit)
                }
                .fpFieldRow(isActive: isFocused)
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            if let error = vm.errorMessage {
                FPErrorBanner(message: error.resolved(lm), shake: shake)
            }

            FPPrimaryButton(
                title: lm["fp_send_code"],
                systemImage: "paperplane.circle.fill",
                isEnabled: vm.isEmailValid,
                isLoading: vm.isLoading,
                palette: palette,
                action: submit)
        }
        .animation(.easeInOut(duration: 0.25), value: vm.errorMessage)
    }

    private func submit() {
        isFocused = false
        Task { await vm.sendOtp() }
    }
}
