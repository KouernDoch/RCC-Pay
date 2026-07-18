//
//  FPSuccessStepView.swift
//  RCC Pay
//
//  Terminal screen — the password is changed; the only route out is back to login.
//

import SwiftUI

struct FPSuccessStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    let palette: FPPalette
    let onBackToLogin: () -> Void

    @State private var badgeScale = 0.4

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FPPalette.blue.opacity(0.12), FPPalette.sky.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FPPalette.blue.opacity(0.18), FPPalette.sky.opacity(0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 82, height: 82)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [FPPalette.blue, FPPalette.sky],
                                       startPoint: .top, endPoint: .bottom))
            }
            .scaleEffect(badgeScale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                    badgeScale = 1.0
                }
            }

            VStack(spacing: 8) {
                Text(lm["fp_success_title"])
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.titleGradient)
                Text(lm["fp_success_subtitle"])
                    .font(.system(size: 14))
                    .foregroundColor(palette.subtitleColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FPPrimaryButton(
                title: lm["back_to_login"],
                systemImage: "arrow.right.circle.fill",
                isEnabled: true,
                palette: palette,
                action: onBackToLogin)
                .shadow(color: FPPalette.blue.opacity(0.35), radius: 14, x: 0, y: 6)
        }
        .padding(.bottom, 8)
    }
}
