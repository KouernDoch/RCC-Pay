//
//  FPOtpStepView.swift
//  RCC Pay
//
//  Step 2 of 3 — enter the 6-digit code, watch it expire, resend when it does.
//
//  Behaviour is unchanged: auto-submit at six digits, the same guard against stacking
//  on an in-flight request, the same countdown/resend swap. Only the styling moved onto
//  design-system tokens.
//

import SwiftUI

struct FPOtpStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @ObservedObject var vm: ForgotPasswordViewModel
    let palette: FPPalette
    let shake: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            FPHeading(title: lm["fp_otp_title"],
                      subtitle: lm["fp_otp_subtitle"],
                      palette: palette)

            // The address the code went to — the whole point of showing it is to let the
            // user catch a typo without going back a step first.
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(.footnote))
                    .foregroundStyle(Color.dsBrand.opacity(0.7))
                Text(vm.normalizedEmail)
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(Color.dsBrand)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.xs + 2)
            .dsAccentSurface(.dsBrand, radius: DS.Radius.sm, intensity: 0.07)
            .accessibilityElement(children: .combine)

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
        .animation(DS.Motion.fade, value: vm.errorMessage)
        .animation(DS.Motion.fade, value: vm.infoMessage)
        .onAppear { isFocused = true }
        .onChange(of: vm.otp) { _, code in
            // Six digits is unambiguous — submit rather than making the user reach for
            // the button. Guarded so an auto-submit can't stack on an in-flight request.
            if code.count == 6 && !vm.isLoading { submit() }
        }
    }

    // MARK: - Countdown / resend

    private var countdownRow: some View {
        HStack(spacing: DS.Space.xxs + 2) {
            if vm.canResend {
                Text(lm["fp_code_expired_hint"])
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button {
                    isFocused = false
                    Task { await vm.resendOtp() }
                } label: {
                    HStack(spacing: DS.Space.xxs + 1) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(.caption, weight: .semibold))
                        Text(lm["fp_resend_code"])
                            .font(.system(.footnote, weight: .bold))
                    }
                    .foregroundStyle(Color.dsBrand)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            } else {
                Image(systemName: "clock")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                Text(lm["fp_code_expires_in"])
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                Text(vm.countdownText)
                    .font(.system(.footnote, design: .monospaced, weight: .bold))
                    .foregroundStyle(vm.secondsRemaining <= 10 ? Color.dsWarning : Color.dsBrand)
                Spacer(minLength: 0)
                // Kept visible but inert so the control doesn't pop into existence at 0:00.
                Text(lm["fp_resend_code"])
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .animation(DS.Motion.fade, value: vm.canResend)
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
                .foregroundStyle(.clear)
                .tint(.clear)
                // Must stay non-zero: a fully transparent field stops receiving input.
                .opacity(0.02)

            HStack(spacing: DS.Space.xs) {
                ForEach(0..<slots, id: \.self) { index in
                    slot(at: index)
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused.wrappedValue = true }
        // Six separate boxes would be announced as six empty fields; this presents the
        // code as the single value it actually is.
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

        return RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
            .fill(isFilled ? Color.dsBrand.opacity(0.08) : Color.dsSurfaceSunken)
            .frame(height: 54)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                    .strokeBorder(
                        isCursor ? Color.dsBrand
                                 : (isFilled ? Color.dsBrand.opacity(0.35) : Color.dsHairline),
                        lineWidth: isCursor ? 2 : 1)
            )
            .overlay(
                Text(digit)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.dsBrand)
                    .contentTransition(.numericText())
            )
            .animation(DS.Motion.quick, value: isFilled)
            .animation(DS.Motion.fade, value: isCursor)
    }
}
