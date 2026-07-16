//
//  EditProfileView.swift
//  RCC Pay
//
//  Edit the signed-in user's own profile (display name & gender).
//  Persists via PUT /api/users/me and refreshes the shared session.
//

import SwiftUI

struct EditProfileView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var name       = ""
    @State private var gender: UserGender = .unspecified

    @State private var errorMsg    = ""
    @State private var showSuccess = false
    @State private var isSaving    = false

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    /// Gender options offered in the UI (mirrors the sign-up screen).
    private let genderOptions: [(value: UserGender, key: String, emoji: String)] = [
        (.male,   "male",   "👨"),
        (.female, "female", "👩"),
        (.other,  "other",  "🧑"),
    ]

    private var isFormValid: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 3
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    banner
                    fieldsCard
                    saveButton
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            if showSuccess { successOverlay }
        }
        .navigationTitle(lm["edit_profile"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear(perform: loadCurrentValues)
    }

    // MARK: - Banner

    private var banner: some View {
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
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(lm["edit_profile"])
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(lm["edit_profile_subtitle"])
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 100)
    }

    // MARK: - Fields

    private var fieldsCard: some View {
        VStack(spacing: 18) {

            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text(lm["admin_name"])
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField(lm["ph_username"], text: $name)
                        .font(.system(size: 15))
                        .autocorrectionDisabled()
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

            // Gender
            VStack(alignment: .leading, spacing: 8) {
                Text(lm["gender"])
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    ForEach(genderOptions, id: \.value) { option in
                        genderChip(option)
                    }
                }
            }

            // Error
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: errorMsg)
    }

    private func genderChip(_ option: (value: UserGender, key: String, emoji: String)) -> some View {
        let selected = gender == option.value
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { gender = option.value }
        } label: {
            HStack(spacing: 5) {
                Text(option.emoji).font(.system(size: 14))
                Text(lm[option.key])
                    .font(.system(size: 13, weight: selected ? .bold : .medium))
                    .foregroundColor(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(selected
                               ? AnyShapeStyle(blue)
                               : AnyShapeStyle(Color(.secondarySystemBackground)))
            )
            .overlay(Capsule().stroke(selected ? Color.clear : blue.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private var saveButton: some View {
        Button { attemptSave() } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white).scaleEffect(0.85)
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

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea().transition(.opacity)
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.18, green: 0.75, blue: 0.48).opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(red: 0.18, green: 0.75, blue: 0.48))
                }
                Text(lm["profile_updated"])
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

    // MARK: - Logic

    private func loadCurrentValues() {
        name = session.currentUser?.name ?? session.displayName
        gender = session.currentUser?.gender ?? .unspecified
    }

    private func attemptSave() {
        withAnimation { errorMsg = "" }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            withAnimation { errorMsg = lm["su_username_short"] }
            return
        }

        isSaving = true
        let body = UserUpdateRequestDTO(name: trimmed, gender: gender.rawValue)
        Task {
            do {
                _ = try await BackendAPI.updateCurrentUser(body)
                await session.refreshCurrentUser()
                isSaving = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { showSuccess = true }
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                withAnimation { showSuccess = false }
                dismiss()
            } catch {
                isSaving = false
                withAnimation {
                    errorMsg = (error as? APIError)?.errorDescription ?? lm["profile_update_failed"]
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(LocalizationManager())
            .environmentObject(SessionStore())
    }
}
