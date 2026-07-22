//
//  FPSuccessStepView.swift
//  RCC Pay
//
//  Terminal screen — the password is changed; the only route out is back to login.
//
//  Matches the sign-up success state exactly, so the two "you're done" moments in the
//  app read as the same moment.
//

import SwiftUI

struct FPSuccessStepView: View {

    @EnvironmentObject private var lm: LocalizationManager
    let palette: FPPalette
    let onBackToLogin: () -> Void

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.dsSuccess)
                .symbolEffect(.bounce, options: .nonRepeating)
                .accessibilityHidden(true)

            VStack(spacing: DS.Space.xs) {
                Text(lm["fp_success_title"])
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(lm["fp_success_subtitle"])
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DSButton(
                title: lm["back_to_login"],
                systemImage: "arrow.right.circle.fill",
                action: onBackToLogin)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.md)
        .accessibilityElement(children: .contain)
    }
}
