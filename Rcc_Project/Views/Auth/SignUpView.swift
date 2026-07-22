//
//  SignUpView.swift
//  RCC Pay
//
//  Create an account.
//
//  Validation order, the `RegisterRequestDTO` payload, the `onAccountCreated` hand-back
//  and the success state are all unchanged. Rebuilt on `AuthScaffold` plus the shared
//  field components, which removed its private wave shape, its private button style and
//  its own copy of the field-row builder.
//

import SwiftUI

struct SignUpView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    /// Reports the new account's email back to the login screen, so it can greet the user
    /// with the address already filled in.
    var onAccountCreated: (String) -> Void = { _ in }

    // Fields
    @State private var username        = ""
    @State private var email           = ""
    @State private var selectedGender: Gender? = nil
    @State private var password        = ""
    @State private var confirmPassword = ""

    // UI state
    @State private var errorMsg    = ""
    @State private var isLoading   = false
    @State private var shakeNonce  = 0
    @State private var showSuccess = false

    @FocusState private var focused: SUField?
    enum SUField { case username, email, password, confirm }

    enum Gender: String, CaseIterable, Identifiable {
        case male, female
        var id: String { rawValue }
        var emoji: String { self == .male ? "👨" : "👩" }
    }

    private var isKeyboardUp: Bool { focused != nil }

    // MARK: - Body

    var body: some View {
        AuthScaffold(
            systemImage: showSuccess ? "checkmark.seal.fill" : "person.badge.plus.fill",
            title: showSuccess ? nil : "RCC Pay",
            subtitle: showSuccess ? nil : lm["su_subtitle"],
            isCompact: isKeyboardUp || showSuccess,
            accessory: {
                HStack {
                    AuthBackButton(title: lm["back"]) { dismiss() }
                    Spacer()
                }
            },
            content: {
                Group {
                    if showSuccess {
                        successContent
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                    } else {
                        formContent
                            .transition(.opacity)
                    }
                }
                .animation(DS.Motion.smooth, value: showSuccess)
            })
        .navigationBarHidden(true)
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: DS.Space.lg) {

            AuthHeading(title: lm["su_title"], subtitle: lm["su_subtitle"])

            DSFieldGroup {
                DSTextField(
                    placeholder: lm["ph_username"],
                    text: $username,
                    systemImage: "person.fill",
                    focus: $focused,
                    field: SUField.username,
                    contentType: .name,
                    capitalization: .words,
                    showsValidTick: username.trimmingCharacters(in: .whitespaces).count >= 3,
                    onSubmit: { focused = .email })

                DSFieldDivider()

                DSTextField(
                    placeholder: lm["ph_email"],
                    text: $email,
                    systemImage: "envelope.fill",
                    focus: $focused,
                    field: SUField.email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress,
                    showsValidTick: isValidEmail(email),
                    onSubmit: { focused = .password })

                DSFieldDivider()

                genderRow

                DSFieldDivider()

                DSTextField(
                    placeholder: lm["ph_new_password"],
                    text: $password,
                    systemImage: "lock.fill",
                    focus: $focused,
                    field: SUField.password,
                    isSecure: true,
                    contentType: .newPassword,
                    onSubmit: { focused = .confirm })

                DSFieldDivider()

                DSTextField(
                    placeholder: lm["ph_confirm_password"],
                    text: $confirmPassword,
                    systemImage: "lock.shield.fill",
                    focus: $focused,
                    field: SUField.confirm,
                    isSecure: true,
                    contentType: .newPassword,
                    submitLabel: .done,
                    isInvalid: !confirmPassword.isEmpty && password != confirmPassword,
                    onSubmit: { focused = nil; attemptSignUp() })
            }

            passwordHints

            if !errorMsg.isEmpty {
                DSCallout(message: errorMsg, tone: .danger)
                    .dsShake(on: shakeNonce)
            }

            DSButton(
                title: lm["create_account"],
                systemImage: "arrow.right.circle.fill",
                isLoading: isLoading
            ) {
                attemptSignUp()
            }
            .disabled(!isFormValid)

            HStack(spacing: DS.Space.xxs) {
                Text(lm["have_account"])
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                Button { dismiss() } label: {
                    Text(lm["login"])
                        .font(.system(.footnote, weight: .bold))
                        .foregroundStyle(Color.dsBrand)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            AuthFooter()
        }
        .animation(DS.Motion.fade, value: errorMsg)
    }

    // MARK: - Gender

    private var genderRow: some View {
        DSFieldRow(systemImage: "person.2.fill", isActive: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(Gender.allCases) { option in
                    genderChip(option)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func genderChip(_ option: Gender) -> some View {
        let isSelected = selectedGender == option

        return Button {
            withAnimation(DS.Motion.quick) { selectedGender = option }
        } label: {
            HStack(spacing: DS.Space.xxs + 1) {
                Text(option.emoji).font(.system(.footnote))
                Text(lm[option.rawValue])
                    .font(.system(.footnote, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, DS.Space.sm + 2)
            .padding(.vertical, DS.Space.xs)
            .background {
                if isSelected {
                    Capsule().fill(Color.dsBrand)
                } else {
                    Capsule()
                        .fill(Color.dsSurfaceSunken)
                        .overlay(Capsule().strokeBorder(Color.dsHairline, lineWidth: 1))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(DSPressStyle(scale: 0.95))
        .accessibilityLabel(lm[option.rawValue])
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Password hints

    @ViewBuilder
    private var passwordHints: some View {
        if !password.isEmpty || !confirmPassword.isEmpty {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                if !password.isEmpty {
                    let s = strength(password)
                    DSStrengthMeter(
                        label: lm[s.key],
                        fraction: s.fraction,
                        tone: s.tone,
                        caption: lm["password_strength"])
                }

                if !confirmPassword.isEmpty {
                    let matched = password == confirmPassword
                    HStack(spacing: DS.Space.xxs + 2) {
                        Image(systemName: matched ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(.caption))
                        Text(matched ? lm["fp_passwords_match"] : lm["password_mismatch"])
                            .font(.dsCaption)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(matched ? Color.dsSuccess : Color.dsDanger)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(DS.Motion.fade, value: password)
            .animation(DS.Motion.fade, value: confirmPassword)
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.dsSuccess)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: DS.Space.xs) {
                Text(lm["su_success_title"])
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(lm["su_success_subtitle"])
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DSButton(title: lm["go_to_login"], systemImage: "arrow.right.circle.fill") {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.md)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Validation & logic

    private var isFormValid: Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 3 &&
        isValidEmail(email) &&
        selectedGender != nil &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func isValidEmail(_ e: String) -> Bool {
        e.range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
                options: .regularExpression) != nil
    }

    private func attemptSignUp() {
        focused = nil
        withAnimation { errorMsg = "" }

        let u = username.trimmingCharacters(in: .whitespaces)
        if u.count < 3                 { fire(lm["su_username_short"]);  return }
        if !isValidEmail(email)        { fire(lm["email_invalid"]);      return }
        if selectedGender == nil       { fire(lm["su_select_gender"]);   return }
        if password.count < 6          { fire(lm["password_too_short"]); return }
        if password != confirmPassword { fire(lm["password_mismatch"]);  return }

        isLoading = true
        let body = RegisterRequestDTO(
            name: u,
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            gender: selectedGender == .male ? "MALE" : "FEMALE",
            password: password)
        Task {
            do {
                // Creates the account without signing in, so the flow can end on the
                // login screen rather than dropping the user straight into the app.
                try await session.signUp(body)
                onAccountCreated(body.email)
                isLoading = false
                withAnimation(DS.Motion.smooth) { showSuccess = true }
            } catch {
                isLoading = false
                fire((error as? APIError)?.errorDescription ?? lm["email_invalid"])
            }
        }
    }

    private func fire(_ msg: String) {
        withAnimation { errorMsg = msg }
        shakeNonce += 1
    }

    // MARK: - Password strength

    private struct Strength { let key: String; let tone: DSTone; let fraction: CGFloat }

    private func strength(_ p: String) -> Strength {
        let has8   = p.count >= 8
        let hasSym = p.rangeOfCharacter(from: .punctuationCharacters) != nil
                  || p.rangeOfCharacter(from: .symbols) != nil
        let hasNum = p.rangeOfCharacter(from: .decimalDigits) != nil
        let hasUp  = p.rangeOfCharacter(from: .uppercaseLetters) != nil
        let score  = [has8, hasSym, hasNum, hasUp].filter { $0 }.count
        if score <= 1 { return Strength(key: "strength_weak",   tone: .danger,  fraction: 0.33) }
        if score <= 2 { return Strength(key: "strength_medium", tone: .warning, fraction: 0.66) }
        return Strength(key: "strength_strong", tone: .success, fraction: 1)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(LocalizationManager())
            .environmentObject(SessionStore())
    }
}
