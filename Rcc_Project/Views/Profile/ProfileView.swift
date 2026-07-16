//
//  ProfileView.swift
//  RCC Pay
//
//  Created by HRD on 1/8/26.
//

import SwiftUI
import PhotosUI
import UserNotifications
import UniformTypeIdentifiers

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

// MARK: - Reusable Row

struct ProfileMenuRow: View {
    let item: ProfileMenuItem
    var valueLabel: String? = nil
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(item.iconBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.iconColor)
                }

                Text(item.title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                if let valueLabel {
                    Text(valueLabel)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())

            if showDivider {
                Divider().padding(.leading, 66)
            }
        }
    }
}

// MARK: - Toggle Row

struct ProfileToggleRow: View {
    let item: ProfileMenuItem
    @Binding var isOn: Bool
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isOn ? item.iconBg : Color(.tertiarySystemFill))
                        .frame(width: 36, height: 36)
                        .animation(.easeInOut(duration: 0.2), value: isOn)
                    Image(systemName: isOn ? item.icon : "bell.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isOn ? item.iconColor : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isOn)
                }

                Text(item.title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(item.iconBg)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())

            if showDivider {
                Divider().padding(.leading, 66)
            }
        }
    }
}

// MARK: - Section Card

struct ProfileSectionCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            .padding(.horizontal)
    }
}

// MARK: - Amount Edit Row

struct ProfileAmountEditRow: View {
    let title: String
    let icon: String
    let iconBg: Color
    @Binding var amount: String
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("$")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 72)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if showDivider {
                Divider().padding(.leading, 66)
            }
        }
    }
}

// MARK: - Theme Picker Sheet

struct ThemePickerSheet: View {
    @AppStorage("appTheme") var appTheme: String = "system"
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    private var options: [(id: String, icon: String, labelKey: String, preview: AnyView)] {[
        ("light",  "sun.max.fill",           "light",  AnyView(Self.lightPreview)),
        ("dark",   "moon.fill",              "dark",   AnyView(Self.darkPreview)),
        ("system", "circle.lefthalf.filled", "system", AnyView(Self.systemPreview)),
    ]}

    var body: some View {
        VStack(spacing: 0) {

            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Title
            HStack {
                Text(lm["appearance"])
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)

            // Theme tiles
            HStack(spacing: 14) {
                ForEach(options, id: \.id) { option in
                    themeTile(id: option.id, icon: option.icon,
                              label: lm[option.labelKey], preview: option.preview)
                }
            }
            .padding(.horizontal, 22)

            Spacer()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    @ViewBuilder
    private func themeTile(id: String, icon: String, label: String, preview: AnyView) -> some View {
        let selected = appTheme == id

        Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { appTheme = id } } label: {
            VStack(spacing: 10) {

                // Mini preview
                ZStack(alignment: .bottomTrailing) {
                    preview
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selected ? blue : Color.gray.opacity(0.15), lineWidth: selected ? 2 : 1)
                        )

                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(blue)
                            .background(Circle().fill(Color.white).padding(2))
                            .offset(x: 6, y: 6)
                    }
                }

                // Label + icon
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selected ? blue : .gray)
                    Text(label)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundColor(selected ? blue : .primary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // Mini theme previews

    static var lightPreview: some View {
        ZStack {
            Color.white
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)).frame(height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.1)).frame(height: 8).padding(.trailing, 20)
                RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.22, green: 0.50, blue: 0.98).opacity(0.25)).frame(height: 22)
            }
            .padding(10)
        }
    }

    static var darkPreview: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2)).frame(height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.12)).frame(height: 8).padding(.trailing, 20)
                RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.22, green: 0.50, blue: 0.98).opacity(0.5)).frame(height: 22)
            }
            .padding(10)
        }
    }

    static var systemPreview: some View {
        ZStack {
            HStack(spacing: 0) {
                Color.white.frame(maxWidth: .infinity)
                Color(red: 0.11, green: 0.11, blue: 0.12).frame(maxWidth: .infinity)
            }
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.25)).frame(height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.18)).frame(height: 8).padding(.trailing, 20)
                RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.22, green: 0.50, blue: 0.98).opacity(0.4)).frame(height: 22)
            }
            .padding(10)
        }
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let blue  = Color(red: 0.22, green: 0.50, blue: 0.98)
    private let green = Color(red: 0.25, green: 0.78, blue: 0.52)

    private struct LangOption {
        let id: String
        let flag: String
        let name: String
        let nativeName: String
        let color: Color
    }

    private var options: [LangOption] {[
        LangOption(id: "en", flag: "🇺🇸", name: "English",  nativeName: "English", color: blue),
        LangOption(id: "km", flag: "🇰🇭", name: "Khmer",    nativeName: "ខ្មែរ",   color: green),
    ]}

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack {
                Text(lm["language"])
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                ForEach(options, id: \.id) { option in
                    langRow(option)
                }
            }
            .padding(.horizontal, 22)

            Spacer()
        }
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    @ViewBuilder
    private func langRow(_ option: LangOption) -> some View {
        let selected = appLanguage == option.id

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                appLanguage = option.id
            }
        } label: {
            HStack(spacing: 14) {
                // Flag
                Text(option.flag)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(option.color.opacity(colorScheme == .dark ? 0.18 : 0.08))
                    )

                // Names
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.system(size: 15, weight: selected ? .semibold : .regular))
                        .foregroundColor(.primary)
                    Text(option.nativeName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(selected ? option.color : Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(option.color)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected
                          ? option.color.opacity(colorScheme == .dark ? 0.15 : 0.06)
                          : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? option.color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main View

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
    @State private var showThemePicker        = false
    @State private var showLanguagePicker     = false
    @State private var showNotifDeniedAlert   = false

    @AppStorage(AdminPaymentSettings.fullAmountKey) private var storedFullAmount: String = AdminPaymentSettings.defaultFull
    @AppStorage(AdminPaymentSettings.halfAmountKey) private var storedHalfAmount: String = AdminPaymentSettings.defaultHalf
    @State private var draftFullAmount: String = AdminPaymentSettings.defaultFull
    @State private var draftHalfAmount: String = AdminPaymentSettings.defaultHalf
    @State private var showPaymentSavedAlert = false
    @State private var showPaymentInvalidAlert = false

    private let blue = Color(red: 0.22, green: 0.50, blue: 0.98)

    private var themeLabel: String {
        switch appTheme {
        case "light":  return lm["light"]
        case "dark":   return lm["dark"]
        default:       return lm["system"]
        }
    }

    private var languageLabel: String {
        appLanguage == "km" ? "ខ្មែរ" : "English"
    }

    // MARK: - Notifications helpers
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

    // MARK: - Profile Card

    private var profileCard: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.46, blue: 0.98),
                            Color(red: 0.42, green: 0.68, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)

            Circle().fill(Color.white.opacity(0.06)).frame(width: 160).offset(x: 110, y: -80)
            Circle().fill(Color.white.opacity(0.06)).frame(width: 100).offset(x: -120, y: -10)

            VStack(spacing: 10) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        // `selectedImage` is the photo the user just picked: it shows straight
                        // away and is cleared on failure, so we never display an image the
                        // backend didn't actually store.
                        ProfileAvatarView(size: 90, localOverride: selectedImage)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)

                        if isUploadingProfileImage {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.45))
                                HStack(spacing: 6) {
                                    ProgressView().tint(.white)
                                    Text("Uploading...")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .fixedSize()
                            .padding(6)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        ZStack {
                            Circle().fill(Color(red: 0.18, green: 0.46, blue: 0.98))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 2, y: 2)
                    }
                }
                .buttonStyle(.plain)

                Text(session.displayName.isEmpty ? "RCC Member" : session.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(userRole == "admin" ? lm["admin_user"] : lm["normal_user"])
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                    Capsule().fill(Color.white.opacity(0.2)).frame(width: 1, height: 12)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 11)).foregroundColor(.white)
                        Text(lm["rcc_member"]).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm["settings"].uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(1)
                .padding(.horizontal, 20)

            ProfileSectionCard {
                // Edit Profile (name & gender)
                NavigationLink(destination: EditProfileView()) {
                    ProfileMenuRow(
                        item: ProfileMenuItem(
                            icon: "person.text.rectangle.fill",
                            iconColor: .white,
                            iconBg: Color(red: 0.47, green: 0.42, blue: 0.96),
                            title: lm["edit_profile"]
                        ),
                        showDivider: true
                    )
                }
                .buttonStyle(.plain)

                // Password & Security
                NavigationLink(destination: PasswordSecurityView()) {
                    ProfileMenuRow(
                        item: ProfileMenuItem(
                            icon: "lock.fill",
                            iconColor: .white,
                            iconBg: Color(red: 0.25, green: 0.55, blue: 1.0),
                            title: lm["password_security"]
                        ),
                        showDivider: true
                    )
                }
                .buttonStyle(.plain)

                // Notification toggle
                ProfileToggleRow(
                    item: ProfileMenuItem(
                        icon: "bell.fill",
                        iconColor: .white,
                        iconBg: Color(red: 1.0, green: 0.42, blue: 0.37),
                        title: lm["notification_menu"]
                    ),
                    isOn: $notificationsEnabled,
                    showDivider: true
                )

                // Language — tappable with current value shown
                Button { showLanguagePicker = true } label: {
                    ProfileMenuRow(
                        item: ProfileMenuItem(
                            icon: "globe",
                            iconColor: .white,
                            iconBg: Color(red: 0.25, green: 0.78, blue: 0.52),
                            title: lm["language"]
                        ),
                        valueLabel: languageLabel,
                        showDivider: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Admin Payment Settings

    private var adminPaymentSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm["admin_payment_amounts"].uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(1)
                .padding(.horizontal, 20)

            ProfileSectionCard {
                ProfileAmountEditRow(
                    title: lm["admin_full_amount"],
                    icon: "dollarsign.circle.fill",
                    iconBg: Color(red: 0.18, green: 0.75, blue: 0.48),
                    amount: $draftFullAmount,
                    showDivider: true
                )

                ProfileAmountEditRow(
                    title: lm["admin_half_amount"],
                    icon: "dollarsign.circle.fill",
                    iconBg: Color(red: 1.00, green: 0.60, blue: 0.15),
                    amount: $draftHalfAmount,
                    showDivider: true
                )

                Button {
                    savePaymentAmounts()
                } label: {
                    HStack {
                        Spacer()
                        Text(lm["admin_save_payment_amounts"])
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .foregroundColor(blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

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

    // MARK: - Preference Section

    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm["preference"].uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(1)
                .padding(.horizontal, 20)

            ProfileSectionCard {
                // About Us
                NavigationLink(destination: AboutUsView()) {
                    ProfileMenuRow(
                        item: ProfileMenuItem(icon: "info.circle.fill", iconColor: .white, iconBg: Color(red: 0.47, green: 0.42, blue: 0.96), title: lm["about_us"]),
                        showDivider: true
                    )
                }
                .buttonStyle(.plain)

                // Theme — tappable with current value shown
                Button { showThemePicker = true } label: {
                    ProfileMenuRow(
                        item: ProfileMenuItem(icon: "paintbrush.fill", iconColor: .white, iconBg: Color(red: 1.0, green: 0.65, blue: 0.15), title: lm["theme"]),
                        valueLabel: themeLabel,
                        showDivider: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Sign Out

    @Environment(\.colorScheme) private var colorScheme

    private var signOutButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                session.signOut()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text(lm["sign_out"])
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 1.0, green: 0.3, blue: 0.3)
                        .opacity(colorScheme == .dark ? 0.18 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark
                            ? Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.3)
                            : Color.clear,
                            lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Body

    var body: some View {
        let rootStack: AnyView = AnyView(
            VStack(spacing: 0) {
                let z: AnyView = AnyView(
                    ZStack(alignment: .center) {
                        backgroundLayer
                        contentScroll
                    }
                )
                z
            }
        )

        return rootStack
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showThemePicker) { ThemePickerSheet() }
            .sheet(isPresented: $showLanguagePicker) { LanguagePickerSheet() }
            .onAppear {
                Task { await syncNotificationStatus() }
                loadPaymentAmountDrafts()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await syncNotificationStatus() }
                }
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                if newValue { Task { await handleNotificationEnable() } }
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let newValue else { return }
                Task { await uploadProfileImage(newValue) }
            }
            .alert(
                "Photo Upload Failed",
                isPresented: Binding(get: { uploadErrorMsg != nil },
                                     set: { if !$0 { uploadErrorMsg = nil } })
            ) {
                Button("OK", role: .cancel) { uploadErrorMsg = nil }
            } message: {
                Text(uploadErrorMsg ?? "")
            }
            .modifier(NotificationsDeniedAlertModifier(show: $showNotifDeniedAlert))
            .modifier(PaymentAlertsModifier(saved: $showPaymentSavedAlert, invalid: $showPaymentInvalidAlert, message: lm["admin_payment_amounts_saved_message"], titleSaved: lm["admin_payment_amounts_saved"], titleInvalid: lm["admin_payment_amounts_invalid"]))
    }

    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }

    private var contentScroll: some View {
        ScrollView(showsIndicators: false) {
            contentStack
                .padding(.top, 12)
                .padding(.bottom, 40)
        }
    }

    private var contentStack: some View {
        VStack(spacing: 24) {
            profileCard
            settingsSection
            if userRole == "admin" {
                adminPaymentSettingsSection
            }
            preferenceSection
            signOutButton
        }
    }
}

private struct NotificationsDeniedAlertModifier: ViewModifier {
    @Binding var show: Bool
    func body(content: Content) -> some View {
        content.alert("Notifications Disabled", isPresented: $show) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
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

