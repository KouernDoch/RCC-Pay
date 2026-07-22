//
//  ProfileView.swift
//  RCC Pay
//
//  Account and settings.
//
//  Every piece of behaviour is carried over unchanged: the photo upload pipeline
//  (normalise → upload → attach → refresh session), the notification authorisation
//  sync, the admin payment-amount drafts, and all four alerts. What moved is the
//  chrome — the theme and language pickers now live in ProfileSheets.swift, and the
//  bespoke row types were replaced by the shared `DSSettingsRow` family.
//

import SwiftUI
import PhotosUI
import UserNotifications

// MARK: - Upload helpers

private extension UIImage {
    /// Downscales to `maxDimension` (avatars never need more) and bakes in the EXIF
    /// orientation, which `jpegData` would otherwise carry as a flag the backend drops.
    func normalizedForUpload(maxDimension: CGFloat = 1024) -> UIImage {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: (size.width * scale).rounded(),
                            height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Main view

struct ProfileView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appTheme")             var appTheme:             String = "system"
    @AppStorage("appLanguage")          var appLanguage:          String = "en"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool   = true
    @AppStorage("userRole")             var userRole:             String = "user"

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @AppStorage("profileImageURL") private var profileImageURLString: String = ""
    @State private var isUploadingProfileImage = false
    @State private var uploadErrorMsg: String?
    @State private var showThemePicker      = false
    @State private var showLanguagePicker   = false
    @State private var showNotifDeniedAlert = false
    @State private var showSignOutConfirm   = false

    @AppStorage(AdminPaymentSettings.fullAmountKey) private var storedFullAmount: String = AdminPaymentSettings.defaultFull
    @AppStorage(AdminPaymentSettings.halfAmountKey) private var storedHalfAmount: String = AdminPaymentSettings.defaultHalf
    @State private var draftFullAmount: String = AdminPaymentSettings.defaultFull
    @State private var draftHalfAmount: String = AdminPaymentSettings.defaultHalf
    @State private var showPaymentSavedAlert = false
    @State private var showPaymentInvalidAlert = false

    private var themeLabel: String {
        switch appTheme {
        case "light": return lm["light"]
        case "dark":  return lm["dark"]
        default:      return lm["system"]
        }
    }

    private var languageLabel: String {
        appLanguage == "km" ? "ខ្មែរ" : "English"
    }

    private var isAdmin: Bool { userRole == "admin" }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Space.lg) {
                    profileCard
                    settingsSection
                    if isAdmin { adminPaymentSettingsSection }
                    preferenceSection
                    signOutButton
                    versionFooter
                }
                .padding(.horizontal, DS.Space.page)
                .padding(.top, DS.Space.sm)
                .padding(.bottom, DS.Space.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showThemePicker) { ThemePickerSheet() }
        .sheet(isPresented: $showLanguagePicker) { LanguagePickerSheet() }
        .onAppear {
            Task { await syncNotificationStatus() }
            loadPaymentAmountDrafts()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await syncNotificationStatus() } }
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            if newValue { Task { await handleNotificationEnable() } }
        }
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }
            Task { await uploadProfileImage(newValue) }
        }
        // Signing out drops every screen behind this one, so it now asks first.
        .confirmationDialog(
            lm["sign_out"],
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(lm["sign_out"], role: .destructive) {
                withAnimation(DS.Motion.smooth) { session.signOut() }
            }
            Button(lm["cancel"], role: .cancel) { }
        }
        .alert(
            "Photo Upload Failed",
            isPresented: Binding(
                get: { uploadErrorMsg != nil },
                set: { if !$0 { uploadErrorMsg = nil } })
        ) {
            Button("OK", role: .cancel) { uploadErrorMsg = nil }
        } message: {
            Text(uploadErrorMsg ?? "")
        }
        .modifier(NotificationsDeniedAlertModifier(show: $showNotifDeniedAlert))
        .modifier(PaymentAlertsModifier(
            saved: $showPaymentSavedAlert,
            invalid: $showPaymentInvalidAlert,
            message: lm["admin_payment_amounts_saved_message"],
            titleSaved: lm["admin_payment_amounts_saved"],
            titleInvalid: lm["admin_payment_amounts_invalid"]))
    }

    // MARK: - Identity card

    /// The old header was a full-bleed blue gradient with white text. It looked loud
    /// next to the rest of the app and needed its own contrast rules; this reads as
    /// part of the same product and adapts to dark mode for free.
    private var profileCard: some View {
        VStack(spacing: DS.Space.sm) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // `selectedImage` is the photo the user just picked: it shows straight
                    // away and is cleared on failure, so we never display an image the
                    // backend didn't actually store.
                    DSSelfAvatar(size: .xl, localOverride: selectedImage, ring: .dsBrand.opacity(0.25))

                    if isUploadingProfileImage {
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: DSAvatarSize.xl.points, height: DSAvatarSize.xl.points)
                            .overlay(ProgressView().tint(.white))
                    }

                    Image(systemName: "camera.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.dsBrand))
                        .overlay(Circle().strokeBorder(Color.dsSurface, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .disabled(isUploadingProfileImage)
            .accessibilityLabel("Change profile photo")

            VStack(spacing: DS.Space.xxs) {
                Text(session.displayName.isEmpty ? "RCC Member" : session.displayName)
                    .font(.dsTitle2)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                HStack(spacing: DS.Space.xs) {
                    DSStatusBadge(
                        text: isAdmin ? lm["admin_user"] : lm["normal_user"],
                        tone: isAdmin ? .brand : .neutral,
                        showsDot: false)

                    DSStatusBadge(
                        text: lm["rcc_member"],
                        tone: .success,
                        showsDot: false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.lg)
        .padding(.horizontal, DS.Space.md)
        .dsSurface(radius: DS.Radius.lg, elevation: .low)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            DSGroupCaption(text: lm["settings"])
                .padding(.horizontal, DS.Space.xxs)

            DSGroupedCard {
                NavigationLink(destination: EditProfileView()) {
                    DSSettingsRow(
                        title: lm["edit_profile"],
                        systemImage: "person.text.rectangle.fill",
                        iconTint: .dsBrand)
                }
                .buttonStyle(.plain)

                DSRowDivider()

                NavigationLink(destination: PasswordSecurityView()) {
                    DSSettingsRow(
                        title: lm["password_security"],
                        systemImage: "lock.fill",
                        iconTint: .dsBrand)
                }
                .buttonStyle(.plain)

                DSRowDivider()

                DSToggleRow(
                    title: lm["notification_menu"],
                    systemImage: "bell.fill",
                    iconTint: .dsDanger,
                    offImage: "bell.slash.fill",
                    isOn: $notificationsEnabled)

                DSRowDivider()

                Button { showLanguagePicker = true } label: {
                    DSSettingsRow(
                        title: lm["language"],
                        systemImage: "globe",
                        iconTint: .dsSuccess,
                        value: languageLabel)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Admin payment amounts

    private var adminPaymentSettingsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            DSGroupCaption(text: lm["admin_payment_amounts"])
                .padding(.horizontal, DS.Space.xxs)

            DSGroupedCard {
                DSAmountRow(
                    title: lm["admin_full_amount"],
                    systemImage: "dollarsign.circle.fill",
                    iconTint: .dsSuccess,
                    amount: $draftFullAmount)

                DSRowDivider()

                DSAmountRow(
                    title: lm["admin_half_amount"],
                    systemImage: "dollarsign.circle.fill",
                    iconTint: .dsWarning,
                    amount: $draftHalfAmount)

                DSRowDivider()

                Button { savePaymentAmounts() } label: {
                    HStack {
                        Spacer()
                        Text(lm["admin_save_payment_amounts"])
                            .font(.dsButton)
                            .foregroundStyle(hasUnsavedAmounts ? Color.dsBrand : Color.secondary)
                        Spacer()
                    }
                    .padding(.vertical, DS.Space.sm + 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!hasUnsavedAmounts)
            }
        }
    }

    /// Keeps the save row inert until something actually changed.
    private var hasUnsavedAmounts: Bool {
        draftFullAmount != storedFullAmount || draftHalfAmount != storedHalfAmount
    }

    // MARK: - Preferences

    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            DSGroupCaption(text: lm["preference"])
                .padding(.horizontal, DS.Space.xxs)

            DSGroupedCard {
                NavigationLink(destination: AboutUsView()) {
                    DSSettingsRow(
                        title: lm["about_us"],
                        systemImage: "info.circle.fill",
                        iconTint: .dsBrand)
                }
                .buttonStyle(.plain)

                DSRowDivider()

                Button { showThemePicker = true } label: {
                    DSSettingsRow(
                        title: lm["theme"],
                        systemImage: "paintbrush.fill",
                        iconTint: .dsWarning,
                        value: themeLabel)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        DSButton(
            title: lm["sign_out"],
            systemImage: "rectangle.portrait.and.arrow.right",
            role: .destructive
        ) {
            showSignOutConfirm = true
        }
    }

    private var versionFooter: some View {
        Text("RCC Pay · v1.0.0")
            .font(.dsCaption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Notifications

    private func syncNotificationStatus() async {
        // Query current notification settings and reflect them in the toggle
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                // Keep the user's toggle value as-is
                break
            case .denied:
                // If denied by system, force toggle off and offer to open Settings when user tries to enable
                notificationsEnabled = false
            case .notDetermined:
                // Not determined yet; don't change the toggle automatically
                break
            @unknown default:
                break
            }
        }
    }

    private func handleNotificationEnable() async {
        // Request authorization if needed when user enables the toggle
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                await MainActor.run {
                    notificationsEnabled = granted
                    if !granted { showNotifDeniedAlert = true }
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                    showNotifDeniedAlert = true
                }
            }
        } else if settings.authorizationStatus == .denied {
            await MainActor.run {
                notificationsEnabled = false
                showNotifDeniedAlert = true
            }
        }
    }

    // MARK: - Profile image upload

    /// Picked photo → upload → attach to profile → refresh session, so the new avatar
    /// survives relaunch and reaches every screen reading `session.currentUser`.
    @MainActor
    private func uploadProfileImage(_ item: PhotosPickerItem) async {
        uploadErrorMsg = nil
        isUploadingProfileImage = true
        // Let the same photo be re-picked later: PhotosPickerItem is Equatable, so leaving
        // this set would make onChange skip an identical re-selection.
        defer {
            isUploadingProfileImage = false
            selectedItem = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else {
                uploadErrorMsg = "That photo could not be read. Please try another."
                return
            }

            // Normalize to JPEG: camera photos arrive as HEIC, which the backend serves back
            // as application/octet-stream (FileController only maps png/jpg/pdf/gif/mp4).
            // Re-encoding also strips the orientation quirk and keeps uploads small.
            let normalized = picked.normalizedForUpload()
            guard let jpeg = normalized.jpegData(compressionQuality: 0.85) else {
                uploadErrorMsg = "That photo could not be prepared for upload."
                return
            }

            // Show it immediately — this outranks the still-stale remote URL.
            selectedImage = normalized

            // 1. POST /api/files/upload — store the image, get its served URL.
            let urlString = try await BackendAPI.uploadProfileImage(
                data: jpeg, filename: "profile.jpg", mimeType: "image/jpeg")
            profileImageURLString = urlString

            // 2. PUT /api/users/me — save that URL onto the user's profile.
            _ = try await BackendAPI.updateCurrentUser(
                UserUpdateRequestDTO(profileImage: urlString))

            // 3. Re-read the profile so `session.currentUser` carries the new URL.
            await session.refreshCurrentUser()

            // The refresh swallows its own errors, so confirm it actually landed rather
            // than leaving the old URL pinned until the next launch.
            if session.currentUser?.profileImage != urlString {
                uploadErrorMsg = "Your photo was saved, but the profile could not be refreshed."
            }
        } catch {
            // Drop the optimistic image so we never show a photo the backend didn't store.
            selectedImage = nil
            uploadErrorMsg = (error as? APIError)?.errorDescription
                ?? "Uploading your photo failed. Please try again."
        }
    }

    // MARK: - Admin payment amounts

    private func loadPaymentAmountDrafts() {
        draftFullAmount = storedFullAmount
        draftHalfAmount = storedHalfAmount
    }

    private func savePaymentAmounts() {
        if AdminPaymentSettings.save(full: draftFullAmount, half: draftHalfAmount) {
            storedFullAmount = AdminPaymentSettings.fullAmountString
            storedHalfAmount = AdminPaymentSettings.halfAmountString
            draftFullAmount = storedFullAmount
            draftHalfAmount = storedHalfAmount
            showPaymentSavedAlert = true
        } else {
            showPaymentInvalidAlert = true
        }
    }
}

// MARK: - Alert modifiers

private struct NotificationsDeniedAlertModifier: ViewModifier {
    @Binding var show: Bool
    func body(content: Content) -> some View {
        content.alert("Notifications Disabled", isPresented: $show) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Notifications are turned off in iOS Settings. Tap \"Open Settings\" to enable them.")
        }
    }
}

private struct PaymentAlertsModifier: ViewModifier {
    @Binding var saved: Bool
    @Binding var invalid: Bool
    let message: String
    let titleSaved: String
    let titleInvalid: String

    func body(content: Content) -> some View {
        content
            .alert(titleSaved, isPresented: $saved) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message)
            }
            .alert(titleInvalid, isPresented: $invalid) {
                Button("OK", role: .cancel) { }
            }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(LocalizationManager())
            .environmentObject(SessionStore())
    }
}
