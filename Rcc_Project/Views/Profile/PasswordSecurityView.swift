//
//  PasswordSecurityView.swift
//  RCC Pay
//
//  Change the signed-in user's password.
//
//  The strength model, validation rules and the change → confirm → dismiss sequence
//  are all carried over. Two UX fixes: the fields are now a focus chain (each one
//  advances to the next on Return, instead of every field being an island), and a
//  mismatched confirmation is called out as you type rather than only on submit.
//

import SwiftUI

// MARK: - Password strength

private enum PasswordStrength {
    case empty, weak, medium, strong

    init(_ password: String) {
        guard password.count >= 6 else { self = password.isEmpty ? .empty : .weak; return }
        var score = 0
        if password.count >= 8                                                   { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil       { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil       { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        switch score {
        case 0...1: self = .weak
        case 2:     self = .medium
        default:    self = .strong
        }
    }

    var fraction: CGFloat {
        switch self {
        case .empty:  return 0
        case .weak:   return 0.33
        case .medium: return 0.66
        case .strong: return 1
        }
    }

    var tone: DSTone {
        switch self {
        case .empty:  return .neutral
        case .weak:   return .danger
        case .medium: return .warning
        case .strong: return .success
        }
    }

    var labelKey: String {
        switch self {
        case .empty:  return ""
        case .weak:   return "strength_weak"
        case .medium: return "strength_medium"
        case .strong: return "strength_strong"
        }
    }
}

// MARK: - Main view

struct PasswordSecurityView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentPwd = ""
    @State private var newPwd     = ""
    @State private var confirmPwd = ""

    @State private var errorMsg    = ""
    @State private var showSuccess = false
    @State private var isSaving    = false

    @FocusState private var focus: Field?
    private enum Field { case current, new, confirm }

    private var strength: PasswordStrength { PasswordStrength(newPwd) }

    /// Live mismatch feedback, but only once the confirmation has content.
    private var showsMismatch: Bool {
        !confirmPwd.isEmpty && newPwd != confirmPwd
    }

    private var showsMatch: Bool {
        !confirmPwd.isEmpty && newPwd == confirmPwd
    }

    private var isFormValid: Bool {
        !currentPwd.isEmpty && newPwd.count >= 8 && newPwd == confirmPwd
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Space.md) {
                    intro
                    fieldsCard

                    if !errorMsg.isEmpty {
                        DSCallout(message: errorMsg, tone: .danger)
                    }

                    DSButton(
                        title: lm["save_changes"],
                        systemImage: "checkmark.circle.fill",
                        isLoading: isSaving
                    ) {
                        attemptSave()
                    }
                    .disabled(!isFormValid)
                }
                .padding(.horizontal, DS.Space.page)
                .padding(.top, DS.Space.md)
                .padding(.bottom, DS.Space.xxl)
                .animation(DS.Motion.fade, value: errorMsg)
            }

            if showSuccess {
                DSSuccessOverlay(message: lm["password_changed"])
            }
        }
        .navigationTitle(lm["password_security"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: DS.Space.xs) {
            DSIconBadge(systemName: "lock.shield.fill", tint: .dsBrand, size: 52)
            Text("Keep your account safe")
                .font(.dsSubtext)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: - Fields

    private var fieldsCard: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Space.md) {

                DSLabeledField(label: lm["current_password"], systemImage: "lock") {
                    SecureField(lm["ph_current_password"], text: $currentPwd)
                        .focused($focus, equals: .current)
                        .textContentType(.password)
                        .submitLabel(.next)
                        .onSubmit { focus = .new }
                }

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    DSLabeledField(label: lm["new_password"], systemImage: "lock.rotation") {
                        SecureField(lm["ph_new_password"], text: $newPwd)
                            .focused($focus, equals: .new)
                            .textContentType(.newPassword)
                            .submitLabel(.next)
                            .onSubmit { focus = .confirm }
                    }

                    if !newPwd.isEmpty {
                        DSStrengthMeter(
                            label: lm[strength.labelKey],
                            fraction: strength.fraction,
                            tone: strength.tone,
                            caption: lm["password_strength"])
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    DSLabeledField(
                        label: lm["confirm_password"],
                        systemImage: "checkmark.gobackward",
                        isInvalid: showsMismatch
                    ) {
                        SecureField(lm["ph_confirm_password"], text: $confirmPwd)
                            .focused($focus, equals: .confirm)
                            .textContentType(.newPassword)
                            .submitLabel(.done)
                            .onSubmit { if isFormValid { attemptSave() } }
                    }

                    if showsMismatch || showsMatch {
                        HStack(spacing: DS.Space.xxs + 2) {
                            Image(systemName: showsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(.caption))
                            Text(showsMatch ? lm["fp_passwords_match"] : lm["password_mismatch"])
                                .font(.dsCaption)
                        }
                        .foregroundStyle(showsMatch ? Color.dsSuccess : Color.dsDanger)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .animation(DS.Motion.fade, value: newPwd.isEmpty)
            .animation(DS.Motion.fade, value: showsMismatch)
            .animation(DS.Motion.fade, value: showsMatch)
        }
    }

    // MARK: - Logic

    private func attemptSave() {
        withAnimation { errorMsg = "" }
        focus = nil

        guard newPwd.count >= 8 else {
            withAnimation { errorMsg = lm["password_too_short"] }
            return
        }
        guard newPwd == confirmPwd else {
            withAnimation { errorMsg = lm["password_mismatch"] }
            return
        }

        isSaving = true
        Task {
            do {
                try await BackendAPI.changePassword(current: currentPwd, new: newPwd)
                isSaving = false
                withAnimation(DS.Motion.smooth) { showSuccess = true }
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                withAnimation { showSuccess = false }
                currentPwd = ""
                newPwd     = ""
                confirmPwd = ""
                dismiss()
            } catch {
                isSaving = false
                withAnimation {
                    errorMsg = (error as? APIError)?.errorDescription ?? lm["password_incorrect"]
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PasswordSecurityView()
            .environmentObject(LocalizationManager())
    }
}
