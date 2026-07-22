//
//  AuthScaffold.swift
//  RCC Pay
//
//  Shared chrome for Login, Sign Up and Forgot Password.
//
//  All three screens previously carried their own copy of the same layout — and three
//  byte-identical wave `Shape`s (`BottomWave`, `SUWave`, `FPBottomWave`) that differed
//  only in name. They now share this one scaffold, so the header treatment can never
//  drift between them again.
//
//  The visual change: the three-stop gradient wave with blurred decorative blobs is
//  replaced by a single flat brand panel with a rounded bottom edge. It renders the
//  same in both colour schemes, costs nothing to composite, and stops the auth flow
//  looking like it belongs to a different app than the dashboard.
//

import SwiftUI

struct AuthScaffold<Content: View, Accessory: View>: View {

    let systemImage: String
    var title: String? = nil
    var subtitle: String? = nil

    /// Collapses the header when the keyboard is up, so the fields keep their room.
    var isCompact: Bool = false

    /// Optional top-bar content: a back button, step pills.
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var scheme

    private var headerHeight: CGFloat { isCompact ? 150 : 280 }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dsBackground.ignoresSafeArea()

            header
                .ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer that lets the header show through above the card.
                    Color.clear
                        .frame(height: headerHeight - 56)
                        .animation(DS.Motion.smooth, value: isCompact)

                    content
                        .padding(DS.Space.lg)
                        .dsSurface(radius: DS.Radius.xl, elevation: .high, fill: Color(.systemBackground))
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.bottom, DS.Space.xl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(edges: .top)

            accessory
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.xs)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            UnevenRoundedRectangle(
                bottomLeadingRadius: 36,
                bottomTrailingRadius: 36,
                style: .continuous
            )
            .fill(Color.dsBrand)

            VStack(spacing: isCompact ? DS.Space.xs : DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: isCompact ? 52 : 84)
                    Image(systemName: systemImage)
                        .font(.system(size: isCompact ? 22 : 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }

                if !isCompact {
                    VStack(spacing: 3) {
                        if let title {
                            Text(title)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.dsSubtext)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            // Sits above the card overlap rather than centred in the whole panel.
            .padding(.bottom, isCompact ? DS.Space.md : DS.Space.xxl + DS.Space.md)
        }
        .frame(height: headerHeight, alignment: .top)
        .animation(DS.Motion.smooth, value: isCompact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title ?? "")
    }
}

// MARK: - Convenience initialisers

extension AuthScaffold where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String? = nil,
        subtitle: String? = nil,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            isCompact: isCompact,
            accessory: { EmptyView() },
            content: content)
    }
}

// MARK: - Top-bar pieces

/// The translucent back button used on the auth headers.
struct AuthBackButton: View {

    var title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xxs + 2) {
                Image(systemName: "chevron.left")
                    .font(.system(.footnote, weight: .semibold))
                Text(title)
                    .font(.system(.footnote, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Space.sm + 2)
            .padding(.vertical, DS.Space.xs)
            .background(Capsule().fill(Color.white.opacity(0.22)))
        }
        .buttonStyle(DSPressStyle(scale: 0.95))
        .accessibilityLabel(title)
    }
}

/// Step indicator pills for the multi-step reset flow.
struct AuthStepPills: View {

    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: DS.Space.xxs + 2) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(current >= index ? 1 : 0.35))
                    .frame(width: current == index ? 22 : 8, height: 8)
                    .animation(DS.Motion.quick, value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

/// The heading block that opens each auth card.
struct AuthHeading: View {

    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.xs + 2) {
            Capsule()
                .fill(Color.dsBrand)
                .frame(width: 4, height: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.dsSubtext)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The tiny "v1.0.0 · RCC Pay" line at the foot of each auth card.
struct AuthFooter: View {
    var body: some View {
        Text("v1.0.0 · RCC Pay")
            .font(.dsCaption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    AuthScaffold(
        systemImage: "creditcard.fill",
        title: "RCC Pay",
        subtitle: "Dormitory Payment System",
        accessory: {
            HStack {
                AuthBackButton(title: "Back") {}
                Spacer()
                AuthStepPills(current: 2, total: 3)
            }
        },
        content: {
            VStack(spacing: DS.Space.lg) {
                AuthHeading(title: "Welcome Back", subtitle: "Sign in to your account")
                DSButton(title: "Login", systemImage: "arrow.right.circle.fill") {}
                AuthFooter()
            }
        })
}
