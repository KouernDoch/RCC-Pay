//
//  FPOtpStepView.swift
//  RCC Pay
//
//  Step 2 of 3 — enter the 6-digit code, watch it expire, resend when it does.
//

import SwiftUI

struct FPOtpStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @ObservedObject var vm: ForgotPasswordViewModel
    let palette: FPPalette
    let shake: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            FPHeading(title: lm["fp_otp_title"],
                      subtitle: lm["fp_otp_subtitle"],
                      palette: palette)

            // The address the code went to — the whole point of showing it is to let the
            // user catch a typo without going back a step first.
            HStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 13))
                    .foregroundColor(FPPalette.blue.opacity(0.7))
                Text(vm.normalizedEmail)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.linkColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FPPalette.blue.opacity(0.06)))

            FPOtpEntryField(code: $vm.otp, isFocused: $isFocused)

            countdownRow

            if let info = vm.infoMessage {
                FPInfoBanner(message: info.resolved(lm))
            }
            if let error = vm.errorMessage {
                FPErrorBanner(message: error.resolved(lm), shake: shake)
            }

            FPPrimaryButton(
                title: lm["fp_verify_code"],
                systemImage: "checkmark.circle.fill",
                isEnabled: vm.isOtpComplete,
                isLoading: vm.isLoading,
                palette: palette,
                action: submit)
        }
        .animation(.easeInOut(duration: 0.25), value: vm.errorMessage)
        .animation(.easeInOut(duration: 0.25), value: vm.infoMessage)
        .onAppear { isFocused = true }
        .onChange(of: vm.otp) { _, code in
            // Six digits is unambiguous — submit rather than making the user reach for
            // the button. Guarded so an auto-submit can't stack on an in-flight request.
            if code.count == 6 && !vm.isLoading { submit() }
        }
    }

    // MARK: - Countdown / resend

    private var countdownRow: some View {
        HStack(spacing: 6) {
            if vm.canResend {
                Text(lm["fp_code_expired_hint"])
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                Button {
                    isFocused = false
                    Task { await vm.resendOtp() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text(lm["fp_resend_code"])
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(palette.linkColor)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(lm["fp_code_expires_in"])
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(vm.countdownText)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(vm.secondsRemaining <= 10 ? .orange : palette.linkColor)
                Spacer(minLength: 0)
                // Kept visible but inert so the control doesn't pop into existence at 0:00.
                Text(lm["fp_resend_code"])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.canResend)
    }

    private func submit() {
        isFocused = false
        Task { await vm.verifyOtp() }
    }
}

// MARK: - Six-box OTP entry

/// Six styled slots backed by a single hidden `TextField`, so paste, delete and the
/// number pad all behave natively while the boxes stay purely presentational.
struct FPOtpEntryField: View {

    @Binding var code: String
    var isFocused: FocusState<Bool>.Binding

    private let slots = 6

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .focused(isFocused)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundColor(.clear)
                .tint(.clear)
                .accentColor(.clear)
                // Must stay non-zero: a fully transparent field stops receiving input.
                .opacity(0.02)

            HStack(spacing: 9) {
                ForEach(0..<slots, id: \.self) { index in
                    slot(at: index)
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused.wrappedValue = true }
        .accessibilityElement()
        .accessibilityLabel(Text("Verification code"))
        .accessibilityValue(Text(code.isEmpty ? "empty" : code.map(String.init).joined(separator: " ")))
    }

    private func slot(at index: Int) -> some View {
        let digits = Array(code)
        let digit = index < digits.count ? String(digits[index]) : ""
        // The caret sits on the next empty slot, or the last one when the code is full.
        let isCursor = isFocused.wrappedValue && index == min(digits.count, slots - 1)
        let isFilled = !digit.isEmpty

        return RoundedRectangle(cornerRadius: 14)
            .fill(isFilled ? FPPalette.blue.opacity(0.08) : Color(.systemBackground))
            .frame(height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isCursor ? FPPalette.blue
                                 : FPPalette.blue.opacity(isFilled ? 0.35 : 0.15),
                        lineWidth: isCursor ? 2 : 1.2)
            )
            .overlay(
                Text(digit)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(FPPalette.blue)
            )
            .shadow(color: FPPalette.blue.opacity(isFilled ? 0.12 : 0.05), radius: 6, x: 0, y: 3)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isFilled)
            .animation(.easeInOut(duration: 0.15), value: isCursor)
    }
}
