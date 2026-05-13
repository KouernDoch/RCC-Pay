//
//  ForgotPasswordView.swift
//  RCC Pay
//

import SwiftUI

// MARK: - Forgot Password View

struct ForgotPasswordView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @AppStorage("rccUserPassword") private var storedPassword: String = "123"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    // Step flow: 1 = find account, 2 = set new password, 3 = success
    @State private var step            = 1
    @State private var usernameInput   = ""
    @State private var newPassword     = ""
    @State private var confirmPassword = ""
    @State private var showNew         = false
    @State private var showConfirm     = false
    @State private var errorMsg        = ""
    @State private var isLoading       = false
    @State private var appeared        = false
    @State private var shake           = false
    @State private var successScale    = 0.4

    @FocusState private var focusedField: FPField?
    private enum FPField { case username, newPassword, confirmPassword }

    private let validUsername = "doch"
    private let screenH = UIScreen.main.bounds.height

    private let navy  = Color(red: 0.05, green: 0.15, blue: 0.55)
    private let blue  = Color(red: 0.16, green: 0.44, blue: 0.96)
    private let sky   = Color(red: 0.48, green: 0.72, blue: 1.00)

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
            
            
            // 2. Form (overlays header)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: screenH * 0.36)
                    formCard
                        .padding(.top, -52)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)
            
            // Back button
            HStack {
                Button {
                    if step > 1 && step < 3 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            step -= 1
                            errorMsg = ""
                        }
                    } else {
                        dismiss()
                    }
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

                // Step indicator pills
                if step < 3 {
                    HStack(spacing: 6) {
                        ForEach(1...2, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(step >= i ? 1.0 : 0.3))
                                .frame(width: step == i ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
        }
        .onTapGesture { focusedField = nil }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            // Wave background
            BottomWaveFP()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.30, blue: 0.88),
                            Color(red: 0.22, green: 0.52, blue: 1.00),
                            sky
                        ],
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
                    Image(systemName: step == 3 ? "checkmark.shield.fill" : "lock.rotation")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
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
            // Card background with blue wash
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
                .fill(blue.opacity(0.05))
                .frame(width: 200)
                .offset(x: 80, y: -50)
                .blur(radius: 2)
            Circle()
                .fill(sky.opacity(0.05))
                .frame(width: 110)
                .offset(x: -50, y: 90)

            VStack(spacing: 28) {
                // ── Step content ──
                Group {
                    if step == 3 {
                        successContent
                    } else {
                        stepContent
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
            .padding(.horizontal, 26)
            .padding(.top, 32)
            .padding(.bottom, 44)
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

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 26) {
            // Heading
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [blue, sky], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4, height: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step == 1 ? lm["fp_step1_title"] : lm["fp_step2_title"])
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(titleGradient)
                        Text(step == 1 ? lm["fp_step1_subtitle"] : lm["fp_step2_subtitle"])
                            .font(.system(size: 13))
                            .foregroundColor(subtitleColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields
            inputSection

            // Error
            if !errorMsg.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 15))
                    Text(errorMsg).font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.18), lineWidth: 1)
                        )
                )
                .offset(x: shake ? -6 : 0)
                .transition(.scale(scale: 0.97).combined(with: .opacity))
            }

            // Action button
            actionButton
        }
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        if step == 1 {
            // Username field
            VStack(spacing: 0) {
                fieldRow(
                    icon: "person.fill",
                    placeholder: lm["ph_username"],
                    text: $usernameInput,
                    isSecure: false,
                    field: .username
                )
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

        } else {
            // New + Confirm password fields
            VStack(spacing: 0) {
                fieldRow(
                    icon: "lock.fill",
                    placeholder: lm["ph_new_password"],
                    text: $newPassword,
                    isSecure: true,
                    showToggle: $showNew,
                    field: .newPassword
                )
                Divider().padding(.leading, 52)
                fieldRow(
                    icon: "lock.shield.fill",
                    placeholder: lm["ph_confirm_password"],
                    text: $confirmPassword,
                    isSecure: true,
                    showToggle: $showConfirm,
                    field: .confirmPassword
                )
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

            // Password match indicator
            if !newPassword.isEmpty && !confirmPassword.isEmpty {
                let matched = newPassword == confirmPassword
                HStack(spacing: 6) {
                    Image(systemName: matched ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(matched ? .green : .red)
                    Text(matched ? lm["fp_passwords_match"] : lm["password_mismatch"])
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(matched ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Field Row

    @ViewBuilder
    private func fieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        showToggle: Binding<Bool> = .constant(false),
        field: FPField
    ) -> some View {
        let isFocused = focusedField == field

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
                        .focused($focusedField, equals: field)
                } else {
                    TextField(placeholder, text: text)
                        .focused($focusedField, equals: field)
                }
            }
            .font(.system(size: 15))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(field == .username || field == .newPassword ? .next : .done)
            .onSubmit {
                switch field {
                case .username:     focusedField = nil
                case .newPassword:  focusedField = .confirmPassword
                case .confirmPassword: focusedField = nil; handleAction()
                }
            }

            if isSecure {
                Button {
                    showToggle.wrappedValue.toggle()
                } label: {
                    Image(systemName: showToggle.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
                .onTapGesture {}
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(isFocused ? blue.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: focusedField)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        let isValid = step == 1
            ? !usernameInput.trimmingCharacters(in: .whitespaces).isEmpty
            : newPassword.count >= 6 && newPassword == confirmPassword

        return Button { handleAction() } label: {
            ZStack {
                if isValid && !isLoading {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [blue.opacity(0.45), sky.opacity(0.3)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .blur(radius: 14)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isValid
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
                        Text(step == 1 ? lm["find_account"] : lm["reset_password"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: step == 1 ? "magnifyingglass.circle.fill" : "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(isValid ? .white : Color.primary.opacity(0.25))
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(FPPressStyle())
        .disabled(!isValid || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    // MARK: - Success Content

    private var successContent: some View {
        VStack(spacing: 28) {
            // Animated success badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [blue.opacity(0.12), sky.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [blue.opacity(0.18), sky.opacity(0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)
                Image(systemName: "checkmark.circle.fill")
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
                Text(lm["fp_success_title"])
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(titleGradient)
                Text(lm["fp_success_subtitle"])
                    .font(.system(size: 14))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
            }

            // Back to login
            Button {
                dismiss()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(colors: [blue, sky],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(height: 56)
                    HStack(spacing: 10) {
                        Text(lm["back_to_login"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                }
                .frame(height: 56)
            }
            .buttonStyle(FPPressStyle())
            .shadow(color: blue.opacity(0.35), radius: 14, x: 0, y: 6)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Logic

    private func handleAction() {
        withAnimation { errorMsg = "" }
        focusedField = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            isLoading = false
            if step == 1 {
                let trimmed = usernameInput.trimmingCharacters(in: .whitespaces).lowercased()
                if trimmed == validUsername {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        step = 2
                    }
                } else {
                    withAnimation {
                        errorMsg = lm["fp_account_not_found"]
                    }
                    triggerShake()
                }
            } else {
                if newPassword.count < 6 {
                    withAnimation { errorMsg = lm["password_too_short"] }
                    triggerShake()
                } else if newPassword != confirmPassword {
                    withAnimation { errorMsg = lm["password_mismatch"] }
                    triggerShake()
                } else {
                    storedPassword = newPassword
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        step = 3
                    }
                }
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

// MARK: - Wave Shape

private struct BottomWaveFP: Shape {
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

// MARK: - Press Button Style

private struct FPPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
        .environmentObject(LocalizationManager())
}
