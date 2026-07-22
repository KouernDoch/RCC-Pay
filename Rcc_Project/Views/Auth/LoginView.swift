//
//  LoginView.swift
//  RCC Pay
//
//  Sign in.
//
//  The login call, the reset-confirmation hand-back and the sign-up prefill are all
//  unchanged. The screen is now built on `AuthScaffold` and the shared field/button
//  components, which removed roughly 300 lines of bespoke chrome — the wave shape,
//  the gradient stack, the decorative blobs, the hand-rolled field rows and its own
//  copy of the press-scale button style.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore

    @State private var username = ""   // holds the email address
    @State private var password = ""
    @State private var errorMsg = ""
    @State private var isLoading = false
    @State private var shakeNonce = 0
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    @State private var showResetConfirmation = false

    @FocusState private var focusedField: LoginField?
    enum LoginField { case username, password }

    private var isKeyboardUp: Bool { focusedField != nil }

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    // MARK: - Body

    var body: some View {
        AuthScaffold(
            systemImage: "creditcard.fill",
            title: "RCC Pay",
            subtitle: "Dormitory Payment System",
            isCompact: isKeyboardUp
        ) {
            formContent
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showForgotPassword) {
            // Carry the typed address forward, and let the flow report back so the
            // confirmation lands on the screen the user returns to.
            ForgotPasswordView(
                prefilledEmail: username,
                onPasswordReset: {
                    withAnimation(DS.Motion.smooth) { showResetConfirmation = true }
                })
                .environmentObject(lm)
        }
        .navigationDestination(isPresented: $showSignUp) {
            // Sign-up no longer signs the user in, so it lands back here — prefill the
            // address they just registered with.
            SignUpView(onAccountCreated: { newEmail in username = newEmail })
                .environmentObject(lm)
        }
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: DS.Space.lg) {

            AuthHeading(title: lm["welcome_back"], subtitle: lm["login_subtitle"])

            DSFieldGroup {
                DSTextField(
                    placeholder: lm["ph_email"],
                    text: $username,
                    systemImage: "envelope.fill",
                    focus: $focusedField,
                    field: LoginField.username,
                    keyboard: .emailAddress,
                    contentType: .username,
                    submitLabel: .next,
                    onSubmit: { focusedField = .password })

                DSFieldDivider()

                DSTextField(
                    placeholder: lm["ph_login_password"],
                    text: $password,
                    systemImage: "lock.fill",
                    focus: $focusedField,
                    field: LoginField.password,
                    isSecure: true,
                    contentType: .password,
                    submitLabel: .go,
                    onSubmit: {
                        focusedField = nil
                        if isFormValid { attemptLogin() }
                    })
            }

            HStack {
                Spacer()
                Button {
                    showForgotPassword = true
                } label: {
                    Text(lm["forgot_password"])
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(Color.dsBrand)
                }
                .buttonStyle(.plain)
            }

            // Confirmation after returning from a completed password reset.
            if showResetConfirmation {
                DSCallout(message: lm["fp_login_reset_success"], tone: .success)
            }

            if !errorMsg.isEmpty {
                DSCallout(message: errorMsg, tone: .danger)
                    .dsShake(on: shakeNonce)
            }

            DSButton(
                title: lm["login"],
                systemImage: "arrow.right.circle.fill",
                isLoading: isLoading
            ) {
                attemptLogin()
            }
            .disabled(!isFormValid)

            HStack(spacing: DS.Space.xxs) {
                Text(lm["dont_have_account"])
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                Button {
                    showSignUp = true
                } label: {
                    Text(lm["sign_up"])
                        .font(.system(.footnote, weight: .bold))
                        .foregroundStyle(Color.dsBrand)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            AuthFooter()
        }
        .animation(DS.Motion.fade, value: errorMsg)
        .animation(DS.Motion.fade, value: showResetConfirmation)
    }

    // MARK: - Logic

    private func attemptLogin() {
        // The reset confirmation has served its purpose once they try the new password.
        withAnimation { errorMsg = ""; showResetConfirmation = false }
        focusedField = nil          // Dismiss keyboard immediately on tap
        isLoading = true
        Task {
            do {
                try await session.login(email: username, password: password)
                // Routing is driven by SessionStore; no local navigation needed.
            } catch {
                isLoading = false
                let message = (error as? APIError)?.errorDescription ?? lm["invalid_credentials"]
                withAnimation(DS.Motion.quick) { errorMsg = message }
                shakeNonce += 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(LocalizationManager())
            .environmentObject(SessionStore())
    }
}
