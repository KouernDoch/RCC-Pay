//
//  LoginView.swift
//  RCC Pay
//

import SwiftUI

// MARK: - Wave Shape

private struct BottomWave: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - 30))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 30),
            control: CGPoint(x: rect.width / 2, y: rect.height + 40)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Login View

struct LoginView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.colorScheme) private var scheme

    @State private var username           = ""   // holds the email address
    @State private var password           = ""
    @State private var showPassword       = false
    @State private var errorMsg           = ""
    @State private var isLoading          = false
    @State private var shake              = false
    @State private var appeared           = false
    @State private var showForgotPassword = false
    @State private var showSignUp         = false

    @FocusState private var focusedField: LoginField?
    private enum LoginField { case username, password }

    private var isKeyboardUp: Bool { focusedField != nil }

    // Use stable screen height – unaffected by keyboard safe-area changes
    private let screenH = UIScreen.main.bounds.height

    private let blue      = Color(red: 0.16, green: 0.44, blue: 0.96)
    private let blueMid   = Color(red: 0.26, green: 0.56, blue: 1.0)
    private let blueLight = Color(red: 0.48, green: 0.72, blue: 1.0)

    private var isDark: Bool { scheme == .dark }
    // Title gradient – legible on both light (dark navy→blue) and dark (sky→white) card
    private var titleGradient: LinearGradient {
        isDark
        ? LinearGradient(colors: [Color(red: 0.60, green: 0.82, blue: 1.00), .white],
                         startPoint: .leading, endPoint: .trailing)
        : LinearGradient(colors: [Color(red: 0.08, green: 0.20, blue: 0.60), blue],
                         startPoint: .leading, endPoint: .trailing)
    }
    // Secondary text under the title
    private var subtitleColor: Color { isDark ? Color(red: 0.55, green: 0.78, blue: 1.00) : blue.opacity(0.6) }
    // Tappable links (forgot password, sign up)
    private var linkColor: Color     { isDark ? blueLight : blue }
    // Footer tiny text
    private var footerColor: Color   { isDark ? blueLight.opacity(0.35) : blue.opacity(0.30) }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Page background – light blue in light mode, deep navy in dark mode
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.04, green: 0.07, blue: 0.16),
                       Color(red: 0.07, green: 0.11, blue: 0.24)]
                    : [Color(red: 0.88, green: 0.94, blue: 1.00),
                       Color(red: 0.94, green: 0.97, blue: 1.00)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── 1. Header (behind everything — form card overlays it) ──
            headerView
                .ignoresSafeArea(edges: .top)

            // ── 2. Scrollable form (on top of header) ─────────────────
            // The clear spacer lets the header show through;
            // the form card floats on top with a deep overlap.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: isKeyboardUp
                               ? screenH * 0.21
                               : screenH * 0.44)
                        .animation(.spring(response: 0.42, dampingFraction: 0.82),
                                   value: isKeyboardUp)

                    formCard
                        .padding(.top, -52)   // deep overlap over the wave
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)
        }
        .onTapGesture { focusedField = nil }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView().environmentObject(lm)
        }
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView().environmentObject(lm)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        let h = isKeyboardUp ? screenH * 0.21 : screenH * 0.44

        return ZStack {
            BottomWave()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.30, blue: 0.88),
                            Color(red: 0.22, green: 0.52, blue: 1.0),
                            blueLight
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative blobs
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 220)
                .offset(x: 90, y: -h * 0.22)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 150)
                .offset(x: -100, y: h * 0.05)

            // Logo + title
            VStack(spacing: isKeyboardUp ? 0 : 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: isKeyboardUp ? 50 : 96)
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: isKeyboardUp ? 38 : 76)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: isKeyboardUp ? 18 : 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                if !isKeyboardUp {
                    VStack(spacing: 5) {
                        Text("RCC Pay")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Dormitory Payment System")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.5)
                    }
                    .opacity(appeared ? 1 : 0)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, isKeyboardUp ? 20 : 50)
        }
        .frame(height: h, alignment: .top)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: isKeyboardUp)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 26) {

            // Heading with accent bar
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(colors: [blue, blueMid],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 4, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lm["welcome_back"])
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(titleGradient)
                    Text(lm["login_subtitle"])
                        .font(.system(size: 13))
                        .foregroundColor(subtitleColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

            // Grouped input card
            groupedInputCard
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

            // Forgot password
            HStack {
                Spacer()
                Button { showForgotPassword = true } label: {
                    Text(lm["forgot_password"])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(linkColor)
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

            // Error pill
            if !errorMsg.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                    Text(errorMsg)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.20), lineWidth: 1)
                        )
                )
                .offset(x: shake ? -6 : 0)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.97).combined(with: .opacity),
                    removal:   .opacity
                ))
            }

            // Login button
            loginButton
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

            // Sign Up link
            HStack(spacing: 4) {
                Text(lm["dont_have_account"])
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Button { showSignUp = true } label: {
                    Text(lm["sign_up"])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(linkColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)

            // Footer
            Text("v1.0.0  ·  RCC Pay")
                .font(.system(size: 11))
                .foregroundColor(footerColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 26)
        .padding(.top, 32)
        .padding(.bottom, 44)
        .background(
            ZStack(alignment: .top) {
                // Base white card
                Color(.systemBackground)
                // Blue gradient wash at top — connects form with the wave header
                LinearGradient(
                    colors: [
                        blue.opacity(isDark ? 0.22 : 0.10),
                        blue.opacity(isDark ? 0.08 : 0.04),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                // Decorative large circle in top-right corner
                Circle()
                    .fill(blue.opacity(0.05))
                    .frame(width: 220)
                    .offset(x: 80, y: -60)
                    .blur(radius: 2)
                // Small accent circle bottom-left
                Circle()
                    .fill(blueMid.opacity(0.06))
                    .frame(width: 120)
                    .offset(x: -50, y: 80)
                    .blur(radius: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [blue.opacity(0.25), blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: blue.opacity(0.18), radius: 20, x: 0, y: -10)
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 12)
    }

    // MARK: - Grouped Input Card

    private var groupedInputCard: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "envelope.fill",
                     placeholder: lm["ph_email"],
                     text: $username,
                     isSecure: false,
                     field: .username)

            Divider().padding(.leading, 52)

            fieldRow(icon: "lock.fill",
                     placeholder: lm["ph_login_password"],
                     text: $password,
                     isSecure: true,
                     field: .password)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [blue.opacity(0.20), blue.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: blue.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Field Row

    @ViewBuilder
    private func fieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        field: LoginField
    ) -> some View {
        // Derive focus from @FocusState directly so `.animation(value:)` works correctly
        let isFocused = (focusedField == field)

        HStack(spacing: 14) {
            // Circle icon badge
            ZStack {
                Circle()
                    .fill(isFocused ? blue.opacity(0.15) : blue.opacity(0.07))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isFocused ? blue : blue.opacity(0.5))
            }

            // Text input
            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: text)
                        .focused($focusedField, equals: field)
                } else {
                    TextField(placeholder, text: text)
                        .focused($focusedField, equals: field)
                }
            }
            .font(.system(size: 15))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(field == .username ? .emailAddress : .default)
            .textContentType(field == .username ? .username : .password)
            .submitLabel(field == .username ? .next : .done)
            .onSubmit {
                if field == .username { focusedField = .password }
                else { focusedField = nil; attemptLogin() }
            }

            // Trailing accessories
            HStack(spacing: 10) {
                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundColor(Color.secondary.opacity(0.5))
                    }
                    // Allow button tap without triggering outer .onTapGesture
                    .onTapGesture {}
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.7),
                       value: text.wrappedValue.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(isFocused ? blue.opacity(0.06) : Color.clear)
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button { attemptLogin() } label: {
            ZStack {
                if isFormValid && !isLoading {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [blue.opacity(0.45), blueMid.opacity(0.25)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .blur(radius: 14)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isFormValid
                        ? LinearGradient(colors: [blue, blueMid],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemFill), Color(.systemFill)],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 56)

                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    HStack(spacing: 10) {
                        Text(lm["login"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(isFormValid ? .white : Color.primary.opacity(0.25))
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!isFormValid || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    // MARK: - Logic

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private func attemptLogin() {
        withAnimation { errorMsg = "" }
        focusedField = nil          // Dismiss keyboard immediately on tap
        isLoading = true
        Task {
            do {
                try await session.login(email: username, password: password)
                // Routing is driven by SessionStore; no local navigation needed.
            } catch {
                isLoading = false
                let message = (error as? APIError)?.errorDescription ?? lm["invalid_credentials"]
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    errorMsg = message
                }
                triggerShake()
            }
        }
    }

    private func triggerShake() {
        withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { shake = false }
    }
}

// MARK: - Press-scale Button Style

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65),
                       value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(LocalizationManager())
        .environmentObject(SessionStore())
}
