//
//  FPResetStepView.swift
//  RCC Pay
//
//  Step 3 of 3 — choose the new password. The checklist mirrors the backend's own
//  strength rules so the user never gets rejected server-side for something we could
//  have told them while they typed.
//

import SwiftUI

struct FPResetStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @ObservedObject var vm: ForgotPasswordViewModel
    let palette: FPPalette
    let shake: Bool

    @State private var showNew = false
    @State private var showConfirm = false

    @FocusState private var focused: Field?
    private enum Field { case newPassword, confirmPassword }

    var body: some View {
        VStack(spacing: 24) {
            FPHeading(title: lm["fp_step2_title"],
                      subtitle: lm["fp_step2_subtitle"],
                      palette: palette)

            FPFieldContainer {
                passwordRow(
                    icon: "lock.fill",
                    placeholder: lm["ph_fp_new_password"],
                    text: $vm.newPassword,
                    isRevealed: $showNew,
                    field: .newPassword)

                Divider().padding(.leading, 52)

                passwordRow(
                    icon: "lock.shield.fill",
                    placeholder: lm["ph_confirm_password"],
                    text: $vm.confirmPassword,
                    isRevealed: $showConfirm,
                    field: .confirmPassword)
            }
            .animation(.easeInOut(duration: 0.2), value: focused)

            requirementChecklist

            if let error = vm.errorMessage {
                FPErrorBanner(message: error.resolved(lm), shake: shake)
            }

            // Shown when the backend's 10-minute post-verification window lapses: the
            // password can no longer be set with this code, so offer the only way forward.
            if vm.mustRestart {
                Button { vm.restart() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text(lm["fp_request_new_code"])
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(palette.linkColor)
                }
                .buttonStyle(.plain)
            }

            FPPrimaryButton(
                title: lm["reset_password"],
                systemImage: "arrow.right.circle.fill",
                isEnabled: vm.canSubmitReset,
                isLoading: vm.isLoading,
                palette: palette,
                action: submit)
        }
        .animation(.easeInOut(duration: 0.25), value: vm.errorMessage)
        .onAppear { focused = .newPassword }
    }

    // MARK: - Rows

    @ViewBuilder
    private func passwordRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isRevealed: Binding<Bool>,
        field: Field
    ) -> some View {
        let isActive = focused == field

        HStack(spacing: 14) {
            FPFieldIcon(systemName: icon, isActive: isActive)

            Group {
                if isRevealed.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .focused($focused, equals: field)
            .font(.system(size: 15))
            .textContentType(.newPassword)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(field == .newPassword ? .next : .done)
            .onSubmit {
                if field == .newPassword { focused = .confirmPassword } else { submit() }
            }

            FPRevealButton(isRevealed: isRevealed)
        }
        .fpFieldRow(isActive: isActive)
    }

    // MARK: - Requirements

    @ViewBuilder
    private var requirementChecklist: some View {
        if !vm.newPassword.isEmpty || !vm.confirmPassword.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(vm.passwordRules) { rule in
                    checkRow(text: lm[rule.labelKey], isMet: rule.isMet)
                }
                if !vm.confirmPassword.isEmpty {
                    checkRow(
                        text: vm.passwordsMatch ? lm["fp_passwords_match"] : lm["password_mismatch"],
                        isMet: vm.passwordsMatch)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .animation(.easeInOut(duration: 0.2), value: vm.newPassword)
            .animation(.easeInOut(duration: 0.2), value: vm.confirmPassword)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func checkRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundColor(isMet ? .green : .secondary.opacity(0.45))
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isMet ? .green : .secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func submit() {
        focused = nil
        Task { await vm.resetPassword() }
    }
}
