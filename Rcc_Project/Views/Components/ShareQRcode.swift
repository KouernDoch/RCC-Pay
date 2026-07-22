//
//  ShareQRcode.swift
//  RCC Pay
//
//  Share the rendered KHQR image. The label was a hard-coded Khmer literal, so English
//  users saw Khmer here regardless of their language setting; it now reads from
//  Localizable.strings like everything else.
//

import SwiftUI

struct ShareQRcode: View {

    var image: UIImage

    @EnvironmentObject private var lm: LocalizationManager
    @State private var isShowingShareSheet = false

    var body: some View {
        Button {
            isShowingShareSheet = true
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(.subheadline, weight: .semibold))
                Text(lm["qr_share"])
                    .font(.dsButton)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.sm)
            .background(Capsule().fill(Color.white.opacity(0.16)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(DSPressStyle(scale: 0.95))
        .sheet(isPresented: $isShowingShareSheet) {
            ActivityView(activityItems: [image])
        }
        .accessibilityLabel(lm["qr_share"])
    }
}
