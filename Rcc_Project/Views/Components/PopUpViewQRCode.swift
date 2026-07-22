//
//  PopUpViewQRCode.swift
//  RCC Pay
//
//  Full-screen KHQR payment code.
//
//  The QR payload, the KHQR card artwork and the `ImageRenderer` share pipeline are all
//  untouched — that string encodes real bank routing data and is not a presentation
//  concern. What changed around it:
//
//   • The instruction text and the share label were hard-coded Khmer literals, so an
//     English user saw Khmer on this one screen. They now come from Localizable.strings.
//   • The screen stays dark in both appearances on purpose: a QR code needs maximum
//     contrast, and a scanning surface that inverts with the system theme is worse at
//     the one job it has.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct PopUpViewQRCode: View {

    @Binding var isShowingSheet: Bool
    /// Amount still owed for the selected month; shown above the code.
    var payAmount: Double = 0
    /// Called when the user confirms they've paid. When nil, no confirm button is shown.
    var onConfirmPaid: (() -> Void)? = nil

    @EnvironmentObject private var lm: LocalizationManager

    @State private var shareImage: UIImage?
    @State private var didCallOnAppearForTheFirstTime = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: DS.Space.lg) {
                topBar
                instructions
                makeBody(payAmount: payAmount)

                if let shareImage {
                    ShareQRcode(image: shareImage)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, DS.Space.lg)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard didCallOnAppearForTheFirstTime == false else { return }
            didCallOnAppearForTheFirstTime = true
            renderImage()
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text(lm["qr_title"])
                .font(.dsHeadline)
                .foregroundStyle(.white)

            HStack {
                Spacer()
                Button {
                    isShowingSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.16)))
                }
                .buttonStyle(DSPressStyle(scale: 0.9))
                .accessibilityLabel(lm["qr_close"])
            }
        }
        .padding(.horizontal, DS.Space.page)
        .padding(.top, DS.Space.sm)
    }

    // MARK: - Instructions

    private var instructions: some View {
        VStack(spacing: DS.Space.xs) {
            Text(lm["qr_instruction"])
                .font(.dsSubtext)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if payAmount > 0 {
                VStack(spacing: 0) {
                    Text(lm["qr_amount_due"].uppercased())
                        .font(.system(.caption2, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(String(format: "$%.2f", payAmount))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.top, DS.Space.xs)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, DS.Space.xl)
    }

    // MARK: - QR card

    func makeBody(payAmount: Double) -> some View {
        QRImage(payamount: payAmount)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
    }

    // MARK: - Sharing

    func saveToTemporaryDirectory(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("RCC_QR.png")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    func renderImage() {
        let renderer = ImageRenderer(content: makeShareableView())
        // Render at device scale — the previous version shipped a soft 1x bitmap.
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }
        shareImage = image
    }

    private func makeShareableView() -> some View {
        VStack {
            makeBody(payAmount: payAmount)
                .padding()
        }
    }
}

// MARK: - Activity sheet

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    PopUpViewQRCode(isShowingSheet: .constant(true), payAmount: 38)
        .environmentObject(LocalizationManager())
}
