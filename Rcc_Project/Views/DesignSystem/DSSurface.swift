//
//  DSSurface.swift
//  RCC Pay
//
//  Card and panel surfaces. Every raised rectangle in the app goes through here, which
//  is what keeps corner radii, borders and shadows identical across screens.
//

import SwiftUI

// MARK: - Surface modifier

private struct DSSurfaceModifier: ViewModifier {

    let radius: CGFloat
    let elevation: DS.Elevation
    let fill: Color
    let strokeColor: Color?

    @Environment(\.colorScheme) private var scheme

    /// In dark mode a drop shadow on a dark card is invisible, so the card is defined
    /// by a hairline border instead. In light mode the border would be redundant with
    /// the shadow, so it's dropped. Same call site, correct result in both.
    private var isDark: Bool { scheme == .dark }

    private var resolvedStroke: Color {
        if let strokeColor { return strokeColor }
        return isDark ? Color.dsHairline : Color.clear
    }

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(resolvedStroke, lineWidth: 1)
            )
            .shadow(
                color: isDark ? .clear : Color.black.opacity(elevation.opacity),
                radius: elevation.radius,
                x: 0,
                y: elevation.y)
    }
}

extension View {

    /// The standard card surface: rounded, filled, subtly raised.
    func dsSurface(
        radius: CGFloat = DS.Radius.lg,
        elevation: DS.Elevation = .low,
        fill: Color = .dsSurface,
        stroke: Color? = nil
    ) -> some View {
        modifier(DSSurfaceModifier(radius: radius, elevation: elevation, fill: fill, strokeColor: stroke))
    }

    /// A surface tinted by an accent — used for tiles that carry a status colour.
    func dsAccentSurface(
        _ accent: Color,
        radius: CGFloat = DS.Radius.md,
        intensity: Double = 0.10
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent.opacity(intensity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(accent.opacity(intensity * 1.8), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Card container

/// A padded card. Use when the content should sit inside the standard inset;
/// use `.dsSurface()` directly when the content manages its own padding
/// (a list of full-bleed rows, for example).
struct DSCard<Content: View>: View {

    var padding: CGFloat = DS.Space.md
    var radius: CGFloat = DS.Radius.lg
    var elevation: DS.Elevation = .low
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsSurface(radius: radius, elevation: elevation)
    }
}

// MARK: - Grouped rows

/// A card whose children are edge-to-edge rows separated by inset hairlines —
/// the Apple Settings pattern. Handles the separators so callers don't each
/// re-implement "divider on all but the last row".
struct DSGroupedCard<Content: View>: View {

    var radius: CGFloat = DS.Radius.lg
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .dsSurface(radius: radius, elevation: .low)
    }
}

/// The inset hairline used between rows inside a `DSGroupedCard`.
struct DSRowDivider: View {
    /// Matches the leading edge of the row's text, not the card — the Settings look.
    var inset: CGFloat = 60

    var body: some View {
        Rectangle()
            .fill(Color.dsSeparator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

// MARK: - Icon badge

/// The rounded-square icon tile that leads a settings row or a card header.
struct DSIconBadge: View {

    let systemName: String
    var tint: Color = .dsBrand
    var size: CGFloat = DS.IconSlot.md
    /// `filled` paints the tint as the background with a white glyph (settings rows);
    /// `soft` uses a tinted wash with a tinted glyph (card headers, status).
    var style: Style = .soft

    enum Style { case soft, filled }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            .fill(style == .filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(style == .filled ? Color.white : tint)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Surfaces") {
    ScrollView {
        VStack(spacing: DS.Space.md) {
            DSCard {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Card").font(.dsTitle2)
                    Text("Standard raised surface with low elevation.")
                        .font(.dsSubtext).foregroundStyle(.secondary)
                }
            }

            DSGroupedCard {
                ForEach(["Profile", "Security", "Language"], id: \.self) { title in
                    HStack(spacing: DS.Space.sm) {
                        DSIconBadge(systemName: "person.fill", style: .filled)
                        Text(title).font(.dsBody)
                        Spacer()
                    }
                    .padding(DS.Space.md)
                    if title != "Language" { DSRowDivider() }
                }
            }

            HStack(spacing: DS.Space.sm) {
                Text("Success").font(.dsMicro).padding(DS.Space.sm)
                    .dsAccentSurface(.dsSuccess)
                Text("Warning").font(.dsMicro).padding(DS.Space.sm)
                    .dsAccentSurface(.dsWarning)
                Text("Danger").font(.dsMicro).padding(DS.Space.sm)
                    .dsAccentSurface(.dsDanger)
            }
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
}
