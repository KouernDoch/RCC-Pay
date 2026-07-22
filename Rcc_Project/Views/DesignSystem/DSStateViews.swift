//
//  DSStateViews.swift
//  RCC Pay
//
//  Empty, error and loading states. Previously each screen invented its own — a bare
//  tray glyph here, a centred spinner there — so the app felt different depending on
//  which screen happened to have no data.
//

import SwiftUI

// MARK: - Empty state

struct DSEmptyState: View {

    let title: String
    var message: String? = nil
    var systemImage: String = "tray"
    var tone: DSTone = .neutral
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            ZStack {
                Circle()
                    .fill(tone.color.opacity(0.10))
                    .frame(width: 76, height: 76)
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(tone.color.opacity(0.7))
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                DSButton(title: actionTitle, role: .secondary, fullWidth: false, compact: true, action: action)
                    .padding(.top, DS.Space.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.xxl)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Error state

struct DSErrorState: View {

    let message: String
    var title: String = "Something went wrong"
    var retryTitle: String = "Retry"
    var onRetry: (() -> Void)? = nil

    var body: some View {
        DSEmptyState(
            title: title,
            message: message,
            systemImage: "exclamationmark.triangle.fill",
            tone: .danger,
            actionTitle: onRetry == nil ? nil : retryTitle,
            action: onRetry)
    }
}

// MARK: - Inline error banner

/// A dismissible strip for errors that shouldn't replace the whole screen — a failed
/// refresh when stale data is still worth showing.
struct DSInlineError: View {

    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(.subheadline))
                .accessibilityHidden(true)

            Text(message)
                .font(.dsSubtext)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: DS.Space.xs)

            if let onRetry {
                Button("Retry", action: onRetry)
                    .font(.system(.footnote, weight: .semibold))
            }
        }
        .foregroundStyle(Color.dsDanger)
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.sm)
        .dsAccentSurface(.dsDanger, radius: DS.Radius.sm)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Loading

/// Centred spinner with a label. Prefer a skeleton (see `DSSkeleton`) when the shape
/// of the incoming content is known — it reads as faster.
struct DSLoadingState: View {

    var message: String? = nil

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            ProgressView()
                .controlSize(.large)
            if let message {
                Text(message)
                    .font(.dsSubtext)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.xxl)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - Success confirmation

/// The modal tick shown after a save. Auto-dismissal stays with the caller — this
/// is presentation only.
struct DSSuccessOverlay: View {

    let message: String
    var systemImage: String = "checkmark.circle.fill"

    @State private var scale: CGFloat = 0.6

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: DS.Space.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 46))
                    .foregroundStyle(Color.dsSuccess)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text(message)
                    .font(.dsHeadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(DS.Space.xl)
            .frame(minWidth: 200)
            .dsSurface(radius: DS.Radius.xl, elevation: .high, fill: Color(.systemBackground))
            .padding(.horizontal, 50)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(DS.Motion.smooth) { scale = 1 }
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Preview

#Preview("States") {
    ScrollView {
        VStack(spacing: DS.Space.lg) {
            DSEmptyState(
                title: "No payments yet",
                message: "Payments you make will show up here.",
                systemImage: "tray")
            DSInlineError(message: "Couldn't refresh your bill.", onRetry: {})
            DSErrorState(message: "We couldn't reach the server.", onRetry: {})
            DSLoadingState(message: "Loading…")
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
}
