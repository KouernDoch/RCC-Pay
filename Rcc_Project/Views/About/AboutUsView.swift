//
//  AboutUsView.swift
//  RCC Pay
//

import SwiftUI

struct AboutUsView: View {

    @EnvironmentObject private var lm: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    private let blue   = Color(red: 0.22, green: 0.50, blue: 0.98)
    private let purple = Color(red: 0.47, green: 0.42, blue: 0.96)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    appHeroCard
                    creatorCard
                    appInfoCard
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(lm["about_us"])
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - App Hero

    private var appHeroCard: some View {
        VStack(spacing: 0) {
            // Gradient banner
            ZStack {
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

                Circle().fill(Color.white.opacity(0.06)).frame(width: 160).offset(x: 110, y: -50)
                Circle().fill(Color.white.opacity(0.06)).frame(width: 100).offset(x: -110, y: 30)

                VStack(spacing: 10) {
                    // App icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 72, height: 72)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)

                    Text("RCC Pay")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(lm["version"]) 1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 32)
            }
            .frame(height: 200)
        }
        .padding(.horizontal)
    }

    // MARK: - App Description Card

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(lm["about_the_app"].uppercased())

            cardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        iconBadge(icon: "house.fill", color: blue)
                        Text("RCC Pay")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(lm["rcc_pay_description"])
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Creator Card

    private var creatorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(lm["creator"].uppercased())

            cardContainer {
                VStack(spacing: 0) {
                    // Profile banner
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [purple, blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            Text("KD")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Kouern Doch")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("IT Instructor")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Age badge
                        VStack(spacing: 2) {
                            Text("24")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(blue)
                            Text("yrs")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(blue.opacity(colorScheme == .dark ? 0.18 : 0.08))
                        )
                    }
                    .padding(16)

                    Divider().padding(.horizontal, 16)

                    // Detail rows
            creatorInfoRow(icon: "building.2.fill", color: purple, label: lm["organization"], value: "Korea Software HRD")
            Divider().padding(.horizontal, 16)
            creatorInfoRow(icon: "envelope.fill",   color: blue,   label: lm["email"],        value: "dochkouern@gmail.com")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Views

    private func creatorInfoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, color: color, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func iconBadge(icon: String, color: Color, size: CGFloat = 36) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(color.opacity(colorScheme == .dark ? 0.22 : 0.12))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundColor(color)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .kerning(1)
    }

    @ViewBuilder
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        AboutUsView()
            .environmentObject(LocalizationManager())
    }
}
