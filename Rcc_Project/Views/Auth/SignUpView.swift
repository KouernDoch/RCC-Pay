//
//  SignUpView.swift
//  RCC Pay
//

import SwiftUI

// MARK: - Sign Up View

struct SignUpView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    // Fields
    @State private var username        = ""
    @State private var email           = ""
    @State private var selectedGender: Gender? = nil
    @State private var password        = ""
    @State private var confirmPassword = ""

    // UI state
    @State private var showPassword  = false
    @State private var showConfirm   = false
    @State private var errorMsg      = ""
    @State private var isLoading     = false
    @State private var shake         = false
    @State private var appeared      = false
    @State private var showSuccess   = false
    @State private var successScale  = 0.4

    @FocusState private var focused: SUField?
    private enum SUField { case username, email, password, confirm }

    enum Gender: String, CaseIterable {
        case male, female
        var emoji: String { self == .male ? "👨" : "👩" }
    }

    private let screenH = UIScreen.main.bounds.height
    private let navy    = Color(red: 0.05, green: 0.15, blue: 0.55)
    private let blue    = Color(red: 0.16, green: 0.44, blue: 0.96)
    private let sky     = Color(red: 0.48, green: 0.72, blue: 1.00)

    private var isDark: Bool { scheme == .dark }
    private var titleGradient: LinearGradient {
        isDark
        ? LinearGradient(colors: [Color(red: 0.60, green: 0.82, blue: 1.00), .white],
                         startPoint: .leading, endPoint: .trailing)
        : LinearGradient(colors: [Color(red: 0.08, green: 0.20, blue: 0.60), blue],
                         startPoint: .leading, endPoint: .trailing)
    }
    private var subtitleColor: Color { isDark ? Color(red: 0.55, green: 0.78, blue: 1.00) : blue.opacity(0.6) }
    private var linkColor: Color     { isDark ? sky : blue }
    private var footerColor: Color   { isDark ? sky.opacity(0.35) : blue.opacity(0.25) }

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
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 1. Header (behind form)
            headerView.ignoresSafeArea(edges: .top)

            // 2. Scrollable form (overlays header)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: screenH * 0.36)
                    formCard.padding(.top, -52)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)

            // 3. Back button (always on top, respects safe area naturally)
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text(lm["back"])
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onTapGesture { focused = nil }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            // Wave background – same shape as ForgotPasswordView
            SUWave()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.30, blue: 0.88),
                                 Color(red: 0.22, green: 0.52, blue: 1.00),
                                 sky],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative blobs
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 220)
                .offset(x: 90, y: -screenH * 0.36 * 0.22)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 150)
                .offset(x: -100, y: screenH * 0.36 * 0.05)

            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 76)
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 58)
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 6)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.bottom, 44)
        }
        .frame(height: screenH * 0.36, alignment: .top)
    }

    // MARK: - Form Card

    private var formCard: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(.systemBackground))
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [blue.opacity(isDark ? 0.20 : 0.08),
                                 blue.opacity(isDark ? 0.06 : 0.02),
                                 Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                )
            // Decorative circles
            Circle()
                .fill(blue.opacity(0.05)).frame(width: 200)
                .offset(x: 80, y: -50).blur(radius: 2)
            Circle()
                .fill(sky.opacity(0.05)).frame(width: 110)
                .offset(x: -50, y: 90)

            if showSuccess {
                successContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                formContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [blue.opacity(0.22), blue.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: blue.opacity(0.16), radius: 20, x: 0, y: -10)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 12)
    }

    // MARK: - Form Content

    private var formContent: some View {
        VStack(spacing: 26) {

            // Heading – same style as ForgotPasswordView
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [blue, sky],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 4, height: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lm["su_title"])
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(titleGradient)
                        Text(lm["su_subtitle"])
                            .font(.system(size: 13))
                            .foregroundColor(subtitleColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // All input fields in one grouped card
            inputSection

            // Password strength + match hints
            passwordHints

            // Error pill
            if !errorMsg.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 15))
                    Text(errorMsg).font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.18), lineWidth: 1))
                )
                .offset(x: shake ? -6 : 0)
                .transition(.scale(scale: 0.97).combined(with: .opacity))
            }

            // Create account button
            createButton

            // Login link
            HStack(spacing: 4) {
                Text(lm["have_account"])
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Button { dismiss() } label: {
                    Text(lm["login"])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(linkColor)
                }
            }

            Text("v1.0.0  ·  RCC Pay")
                .font(.system(size: 11))
                .foregroundColor(footerColor)
        }
        .padding(.horizontal, 26)
        .padding(.top, 32)
        .padding(.bottom, 44)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 0) {
            // Username
            fieldRow(icon: "person.fill", placeholder: lm["ph_username"],
                     text: $username, isSecure: false, field: .username, showCheck: true)

            Divider().padding(.leading, 52)

            // Email
            fieldRow(icon: "envelope.fill", placeholder: lm["ph_email"],
                     text: $email, keyboard: .emailAddress, isSecure: false,
                     field: .email, showCheck: true)

            Divider().padding(.leading, 52)

            // Gender picker (inline row)
            genderRow

            Divider().padding(.leading, 52)

            // Password
            fieldRow(icon: "lock.fill", placeholder: lm["ph_new_password"],
                     text: $password, isSecure: true, showToggle: $showPassword,
                     field: .password)

            Divider().padding(.leading, 52)

            // Confirm password
            fieldRow(icon: "lock.shield.fill", placeholder: lm["ph_confirm_password"],
                     text: $confirmPassword, isSecure: true, showToggle: $showConfirm,
                     field: .confirm)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [blue.opacity(0.20), blue.opacity(0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: blue.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    // MARK: - Gender Row

    private var genderRow: some View {
        let isFocused = false
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(blue.opacity(0.07))
                    .frame(width: 34, height: 34)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(blue.opacity(0.5))
            }
            HStack(spacing: 10) {
                ForEach(Gender.allCases, id: \.self) { g in
                    let sel = selectedGender == g
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGender = g
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(g.emoji).font(.system(size: 14))
                            Text(lm[g.rawValue])
                                .font(.system(size: 13, weight: sel ? .bold : .medium))
                                .foregroundColor(sel ? .white : blue.opacity(0.75))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(sel
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [blue, sky],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color(.secondarySystemBackground))
                            )
                        )
                        .overlay(Capsule().stroke(sel ? Color.clear : blue.opacity(0.15), lineWidth: 1))
                        .shadow(color: sel ? blue.opacity(0.28) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    // MARK: - Password Hints

    @ViewBuilder
    private var passwordHints: some View {
        if !password.isEmpty || !confirmPassword.isEmpty {
            VStack(spacing: 8) {
                if !password.isEmpty {
                    let s = strength(password)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(lm["password_strength"])
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(lm[s.key])
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(s.color)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color(.systemFill)).frame(height: 5)
                                RoundedRectangle(cornerRadius: 4).fill(s.color)
                                    .frame(width: g.size.width * s.fraction, height: 5)
                                    .animation(.spring(response: 0.4), value: s.fraction)
                            }
                        }
                        .frame(height: 5)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !confirmPassword.isEmpty {
                    let matched = password == confirmPassword
                    HStack(spacing: 6) {
                        Image(systemName: matched ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 13))
                        Text(matched ? lm["fp_passwords_match"] : lm["password_mismatch"])
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(matched ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: password)
            .animation(.easeInOut(duration: 0.2), value: confirmPassword)
        }
    }

    // MARK: - Field Row (mirrors ForgotPasswordView exactly)

    @ViewBuilder
    private func fieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        isSecure: Bool,
        showToggle: Binding<Bool> = .constant(false),
        field: SUField,
        showCheck: Bool = false
    ) -> some View {
        let isFocused = focused == field

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isFocused ? blue.opacity(0.15) : blue.opacity(0.07))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isFocused ? blue : blue.opacity(0.5))
            }

            Group {
                if isSecure && !showToggle.wrappedValue {
                    SecureField(placeholder, text: text)
                        .focused($focused, equals: field)
                } else {
                    TextField(placeholder, text: text)
                        .focused($focused, equals: field)
                }
            }
            .font(.system(size: 15))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(keyboard)
            .submitLabel(field == .confirm ? .done : .next)
            .onSubmit {
                switch field {
                case .username: focused = .email
                case .email:    focused = .password
                case .password: focused = .confirm
                case .confirm:  focused = nil; attemptSignUp()
                }
            }

            if isSecure {
                Button { showToggle.wrappedValue.toggle() } label: {
                    Image(systemName: showToggle.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
                .onTapGesture {}
            } else if showCheck && !text.wrappedValue.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.green.opacity(0.75))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(isFocused ? blue.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: focused)
    }

    // MARK: - Create Account Button (mirrors ForgotPasswordView's actionButton)

    private var createButton: some View {
        Button { attemptSignUp() } label: {
            ZStack {
                if isFormValid && !isLoading {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [blue.opacity(0.45), sky.opacity(0.3)],
                                             startPoint: .leading, endPoint: .trailing))
                        .blur(radius: 14)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                }
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isFormValid
                        ? LinearGradient(colors: [blue, sky],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemFill), Color(.systemFill)],
                                         startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 56)

                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else {
                    HStack(spacing: 10) {
                        Text(lm["create_account"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(isFormValid ? .white : Color.primary.opacity(0.25))
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(SUPressStyle())
        .disabled(!isFormValid || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
    }

    // MARK: - Success Content (mirrors ForgotPasswordView's successContent)

    private var successContent: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [blue.opacity(0.12), sky.opacity(0.08)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(LinearGradient(colors: [blue.opacity(0.18), sky.opacity(0.14)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 82, height: 82)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [blue, sky], startPoint: .top, endPoint: .bottom)
                    )
            }
            .scaleEffect(successScale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                    successScale = 1.0
                }
            }

            VStack(spacing: 8) {
                Text(lm["su_success_title"])
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(titleGradient)
                Text(lm["su_success_subtitle"])
                    .font(.system(size: 14))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
            }

            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [blue, sky],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 56)
                    HStack(spacing: 10) {
                        Text(lm["go_to_login"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill").font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                }
                .frame(height: 56)
            }
            .buttonStyle(SUPressStyle())
            .shadow(color: blue.opacity(0.35), radius: 14, x: 0, y: 6)
        }
        .padding(.horizontal, 26)
        .padding(.top, 32)
        .padding(.bottom, 44)
    }

    // MARK: - Validation & Logic

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
        if u.count < 3           { fire(lm["su_username_short"]);  return }
        if !isValidEmail(email)  { fire(lm["email_invalid"]);      return }
        if selectedGender == nil { fire(lm["su_select_gender"]);   return }
        if password.count < 6    { fire(lm["password_too_short"]); return }
        if password != confirmPassword { fire(lm["password_mismatch"]); return }

        isLoading = true
        let body = RegisterRequestDTO(
            name: u,
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            gender: selectedGender == .male ? "MALE" : "FEMALE",
            password: password)
        Task {
            do {
                try await session.register(body)
                // Registration signs the user in; show the success screen briefly before
                // SessionStore routing swaps in the main app.
                isLoading = false
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showSuccess = true
                }
            } catch {
                isLoading = false
                fire((error as? APIError)?.errorDescription ?? lm["email_invalid"])
            }
        }
    }

    private func fire(_ msg: String) {
        withAnimation { errorMsg = msg }
        withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { shake = false }
    }

    // MARK: - Password Strength

    private struct Strength { let key: String; let color: Color; let fraction: CGFloat }
    private func strength(_ p: String) -> Strength {
        let has8  = p.count >= 8
        let hasSym = p.rangeOfCharacter(from: .punctuationCharacters) != nil
                  || p.rangeOfCharacter(from: .symbols) != nil
        let hasNum = p.rangeOfCharacter(from: .decimalDigits) != nil
        let hasUp  = p.rangeOfCharacter(from: .uppercaseLetters) != nil
        let score  = [has8, hasSym, hasNum, hasUp].filter { $0 }.count
        if score <= 1 { return Strength(key: "strength_weak",   color: .red,    fraction: 0.33) }
        if score <= 2 { return Strength(key: "strength_medium", color: .orange, fraction: 0.66) }
        return Strength(key: "strength_strong", color: .green, fraction: 1.0)
    }
}

// MARK: - Wave Shape (same geometry as ForgotPasswordView)

private struct SUWave: Shape {
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

// MARK: - Button Style (same as ForgotPasswordView)

private struct SUPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
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
