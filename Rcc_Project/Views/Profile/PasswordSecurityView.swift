//
//  PasswordSecurityView.swift
//  RCC Pay
//

import SwiftUI

// MARK: - Password Strength

private enum PasswordStrength {
    case empty, weak, medium, strong

    init(_ password: String) {
        guard password.count >= 6 else { self = password.isEmpty ? .empty : .weak; return }
        var score = 0
        if password.count >= 8                                      { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        switch score {
        case 0...1: self = .weak
        case 2:     self = .medium
        default:    self = .strong
        }
    }

    var bars: Int   { switch self { case .empty: 0; case .weak: 1; case .medium: 2; case .strong: 3 } }
    var color: Color {
        switch self {
        case .empty:  return .gray.opacity(0.2)
        case .weak:   return Color(red: 1.0,  green: 0.3,  blue: 0.3)
        case .medium: return Color(red: 1.0,  green: 0.65, blue: 0.0)
        case .strong: return Color(red: 0.18, green: 0.75, blue: 0.48)
        }
    }
    var labelKey: String {
        switch self { case .empty: ""; case .weak: "strength_weak"; case .medium: "strength_medium"; case .strong: "strength_strong" }
    }
}

// MARK: - Secure Field

private struct SecureInputField: View {
    let titleKey: String
    let placeholderKey: String
    let icon: String
    @Binding var text: String
    @State private var isVisible = false
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lm[titleKey])
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Group {
                    if isVisible {
                        TextField(lm[placeholderKey], text: $text)
                    } else {
                        SecureField(lm[placeholderKey], text: $text)
                    }
                }
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { isVisible.toggle() }
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

// MARK: - Main View

struct PasswordSecurityView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var currentPwd  = ""
    @State private var newPwd      = ""
    @State private var confirmPwd  = ""

    @State private var errorMsg    = ""
    @State private var showSuccess = false
    @State private var isSaving    = false

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)
    private var strength: PasswordStrength { PasswordStrength(newPwd) }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // ── Lock icon banner ──────────────────────────
                    lockBanner

                    // ── Fields card ───────────────────────────────
                    fieldsCard

                    // ── Save button ───────────────────────────────
                    saveButton
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            // ── Success overlay ───────────────────────────────────
            if showSuccess { successOverlay }
        }
        .navigationTitle(lm["password_security"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Lock Banner

    private var lockBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.25, green: 0.55, blue: 1.0),
                                 Color(red: 0.18, green: 0.46, blue: 0.98)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Circle().fill(Color.white.opacity(0.06)).frame(width: 120).offset(x: 90, y: -40)
            Circle().fill(Color.white.opacity(0.06)).frame(width: 80).offset(x: -90, y: 20)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(lm["password_security"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Keep your account safe")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 100)
    }

    // MARK: - Fields Card

    private var fieldsCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                SecureInputField(titleKey: "current_password", placeholderKey: "ph_current_password", icon: "lock",           text: $currentPwd)
                SecureInputField(titleKey: "new_password",     placeholderKey: "ph_new_password",     icon: "lock.rotation", text: $newPwd)
                SecureInputField(titleKey: "confirm_password", placeholderKey: "ph_confirm_password", icon: "checkmark.gobackward", text: $confirmPwd)

                // Strength bar
                if !newPwd.isEmpty {
                    strengthBar
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Error message
                if !errorMsg.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                        Text(errorMsg)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: errorMsg)
        .animation(.easeInOut(duration: 0.2), value: newPwd.isEmpty)
    }

    // MARK: - Strength Bar

    private var strengthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(bar <= strength.bars ? strength.color : Color(.tertiarySystemFill))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.25), value: strength.bars)
                }
            }
            if !strength.labelKey.isEmpty {
                Text(lm[strength.labelKey])
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(strength.color)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button { attemptSave() } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                }
                Text(lm["save_changes"])
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFormValid ? blue : Color.gray.opacity(0.4))
            )
        }
        .disabled(!isFormValid || isSaving)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.18, green: 0.75, blue: 0.48).opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(red: 0.18, green: 0.75, blue: 0.48))
                }
                Text(lm["password_changed"])
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 50)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !currentPwd.isEmpty && newPwd.count >= 8 && !confirmPwd.isEmpty
    }

    private func attemptSave() {
        withAnimation { errorMsg = "" }

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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showSuccess = true
                }
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
