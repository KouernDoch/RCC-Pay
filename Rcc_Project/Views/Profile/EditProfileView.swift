//
//  EditProfileView.swift
//  RCC Pay
//
//  Edit the signed-in user's own profile (display name & gender).
//  Persists via PUT /api/users/me and refreshes the shared session.
//
//  Validation, saving and the success/dismiss sequence are unchanged. The gradient
//  banner is gone — it repeated the screen title the navigation bar already shows —
//  and the save button now reports *why* it's disabled instead of just greying out.
//

import SwiftUI

struct EditProfileView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var gender: UserGender = .unspecified

    @State private var errorMsg    = ""
    @State private var showSuccess = false
    @State private var isSaving    = false
    /// Suppresses the "too short" hint until the user has actually typed something.
    @State private var hasEdited   = false

    /// Gender options offered in the UI (mirrors the sign-up screen).
    private let genderOptions: [(value: UserGender, key: String, emoji: String)] = [
        (.male,   "male",   "👨"),
        (.female, "female", "👩"),
        (.other,  "other",  "🧑"),
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isFormValid: Bool { trimmedName.count >= 3 }

    private var showsLengthHint: Bool { hasEdited && !trimmedName.isEmpty && !isFormValid }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Space.md) {
                    identityPreview
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
                .animation(DS.Motion.fade, value: showsLengthHint)
            }

            if showSuccess {
                DSSuccessOverlay(message: lm["profile_updated"])
            }
        }
        .navigationTitle(lm["edit_profile"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: loadCurrentValues)
    }

    // MARK: - Identity preview

    /// Shows the change as it will appear elsewhere in the app, so the field isn't
    /// editing an abstraction.
    private var identityPreview: some View {
        VStack(spacing: DS.Space.xs) {
            DSSelfAvatar(size: .lg)
            Text(trimmedName.isEmpty ? (session.displayName.isEmpty ? "RCC Member" : session.displayName) : trimmedName)
                .font(.dsHeadline)
                .foregroundStyle(.primary)
                .contentTransition(.opacity)
            Text(lm["edit_profile_subtitle"])
                .font(.dsCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.md)
        .animation(DS.Motion.fade, value: trimmedName)
    }

    // MARK: - Fields

    private var fieldsCard: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Space.md) {

                VStack(alignment: .leading, spacing: DS.Space.xxs + 2) {
                    DSLabeledField(
                        label: lm["admin_name"],
                        systemImage: "person.fill",
                        isInvalid: showsLengthHint
                    ) {
                        TextField(lm["ph_username"], text: $name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { _, _ in hasEdited = true }
                    }

                    if showsLengthHint {
                        Text(lm["su_username_short"])
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsDanger)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(lm["gender"])
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: DS.Space.xs) {
                        ForEach(genderOptions, id: \.value) { option in
                            genderChip(option)
                        }
                    }
                }
            }
        }
    }

    private func genderChip(_ option: (value: UserGender, key: String, emoji: String)) -> some View {
        let isSelected = gender == option.value

        return Button {
            withAnimation(DS.Motion.quick) { gender = option.value }
        } label: {
            HStack(spacing: DS.Space.xxs + 1) {
                Text(option.emoji).font(.system(.footnote))
                Text(lm[option.key])
                    .font(.system(.footnote, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.xs + 2)
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
        .buttonStyle(DSPressStyle(scale: 0.96))
        .accessibilityLabel(lm[option.key])
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Logic

    private func loadCurrentValues() {
        name = session.currentUser?.name ?? session.displayName
        gender = session.currentUser?.gender ?? .unspecified
    }

    private func attemptSave() {
        withAnimation { errorMsg = "" }
        let trimmed = trimmedName
        guard trimmed.count >= 3 else {
            hasEdited = true
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
                withAnimation(DS.Motion.smooth) { showSuccess = true }
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
