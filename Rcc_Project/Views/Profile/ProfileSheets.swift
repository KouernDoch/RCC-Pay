//
//  ProfileSheets.swift
//  RCC Pay
//
//  The appearance and language pickers. Split out of ProfileView, which had grown to
//  nearly a thousand lines with three unrelated screens inside it.
//
//  Both still write straight to the same `@AppStorage` keys, so the app-wide observers
//  (`LocalizationManager`, `preferredScheme`) pick the change up unchanged.
//

import SwiftUI

// MARK: - Appearance

struct ThemePickerSheet: View {

    @AppStorage("appTheme") var appTheme: String = "system"
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    private struct ThemeOption: Identifiable {
        let id: String
        let icon: String
        let labelKey: String
    }

    private let options: [ThemeOption] = [
        ThemeOption(id: "light",  icon: "sun.max.fill",           labelKey: "light"),
        ThemeOption(id: "dark",   icon: "moon.fill",              labelKey: "dark"),
        ThemeOption(id: "system", icon: "circle.lefthalf.filled", labelKey: "system"),
    ]

    var body: some View {
        DSSheetScaffold(title: lm["appearance"]) {
            HStack(spacing: DS.Space.sm) {
                ForEach(options) { option in
                    themeTile(option)
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DS.Radius.xl)
    }

    private func themeTile(_ option: ThemeOption) -> some View {
        let isSelected = appTheme == option.id

        return Button {
            withAnimation(DS.Motion.quick) { appTheme = option.id }
        } label: {
            VStack(spacing: DS.Space.xs) {
                ZStack(alignment: .bottomTrailing) {
                    themePreview(for: option.id)
                        .frame(height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.dsBrand : Color.dsHairline,
                                    lineWidth: isSelected ? 2 : 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(.body))
                            .foregroundStyle(Color.dsBrand, Color(.systemBackground))
                            .offset(x: 6, y: 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                HStack(spacing: DS.Space.xxs) {
                    Image(systemName: option.icon)
                        .font(.system(.caption2, weight: .semibold))
                    Text(lm[option.labelKey])
                        .font(.system(.footnote, weight: isSelected ? .semibold : .regular))
                }
                .foregroundStyle(isSelected ? Color.dsBrand : Color.primary)
            }
        }
        .buttonStyle(DSPressStyle(scale: 0.96))
        .frame(maxWidth: .infinity)
        .accessibilityLabel(lm[option.labelKey])
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// A miniature of the app rendered in the candidate scheme, so the choice is
    /// previewed rather than described.
    @ViewBuilder
    private func themePreview(for id: String) -> some View {
        switch id {
        case "light": miniature(dark: false)
        case "dark":  miniature(dark: true)
        default:
            ZStack {
                HStack(spacing: 0) {
                    miniature(dark: false).frame(maxWidth: .infinity)
                    miniature(dark: true).frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func miniature(dark: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            (dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white)

            VStack(alignment: .leading, spacing: DS.Space.xxs + 1) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(dark ? Color.white.opacity(0.22) : Color.black.opacity(0.14))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(dark ? Color.white.opacity(0.13) : Color.black.opacity(0.08))
                    .frame(height: 7)
                    .padding(.trailing, 18)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.dsBrand.opacity(dark ? 0.55 : 0.30))
                    .frame(height: 20)
            }
            .padding(DS.Space.xs)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Language

struct LanguagePickerSheet: View {

    @AppStorage("appLanguage") var appLanguage: String = "en"
    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    private struct LangOption: Identifiable {
        let id: String
        let flag: String
        let name: String
        let nativeName: String
        let tone: DSTone
    }

    private let options: [LangOption] = [
        LangOption(id: "en", flag: "🇺🇸", name: "English", nativeName: "English", tone: .brand),
        LangOption(id: "km", flag: "🇰🇭", name: "Khmer",   nativeName: "ខ្មែរ",   tone: .success),
    ]

    var body: some View {
        DSSheetScaffold(title: lm["language"]) {
            VStack(spacing: DS.Space.xs) {
                ForEach(options) { langRow($0) }
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DS.Radius.xl)
    }

    private func langRow(_ option: LangOption) -> some View {
        let isSelected = appLanguage == option.id

        return Button {
            withAnimation(DS.Motion.quick) { appLanguage = option.id }
        } label: {
            HStack(spacing: DS.Space.sm + 2) {
                Text(option.flag)
                    .font(.system(size: 26))
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                            .fill(option.tone.color.opacity(0.12))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(option.name)
                        .font(.system(.subheadline, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)
                    Text(option.nativeName)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: DS.Space.xs)

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? option.tone.color : Color.secondary.opacity(0.35),
                            lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(option.tone.color).frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(DS.Motion.quick, value: isSelected)
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(isSelected ? option.tone.color.opacity(0.08) : Color.dsSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? option.tone.color.opacity(0.35) : Color.dsHairline,
                        lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        }
        .buttonStyle(DSPressStyle(scale: 0.98))
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Shared sheet chrome

/// Title row plus a close button, used by both pickers so they open identically.
struct DSSheetScaffold<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.dsTitle2)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(.secondary, Color(.tertiarySystemFill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.top, DS.Space.lg)
            .padding(.bottom, DS.Space.md)

            content
                .padding(.horizontal, DS.Space.lg)

            Spacer(minLength: 0)
        }
        .background(Color.dsBackground)
    }
}

// MARK: - Previews

#Preview("Appearance") {
    Color.dsBackground
        .sheet(isPresented: .constant(true)) {
            ThemePickerSheet().environmentObject(LocalizationManager())
        }
}

#Preview("Language") {
    Color.dsBackground
        .sheet(isPresented: .constant(true)) {
            LanguagePickerSheet().environmentObject(LocalizationManager())
        }
}
