//
//  DSTheme.swift
//  RCC Pay
//
//  The single source of truth for the app's visual language: colour, type, spacing,
//  radius, elevation and motion. Screens should never hard-code a hex value, a point
//  size or a shadow again — reach for a token here instead.
//
//  Naming: everything is prefixed `DS` (design system) so it never collides with the
//  view types that already exist in the project.
//

import SwiftUI

// MARK: - Dynamic colour helper

extension Color {

    /// Builds a colour that resolves differently in light and dark mode.
    ///
    /// Using a `UIColor` dynamic provider (rather than reading `@Environment(\.colorScheme)`
    /// at every call site) means the colour is correct inside `UIKit`-backed surfaces too —
    /// share sheets, `UIActivityViewController`, widget snapshots — and it re-resolves for
    /// free when the user flips appearance.
    static func dsDynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex        & 0xFF) / 255,
            alpha: 1)
    }
}

// MARK: - Palette

extension Color {

    // ── Brand ────────────────────────────────────────────────────────────────
    /// Primary action colour. Slightly lifted in dark mode so it keeps a 4.5:1
    /// contrast ratio against the dark surface.
    static let dsBrand      = Color.dsDynamic(light: 0x2E6BF5, dark: 0x5C93FF)
    /// For large decorative fills and gradient partners — never for text.
    static let dsBrandSoft  = Color.dsDynamic(light: 0x6FA0FF, dark: 0x3A6BD6)

    // ── Status ───────────────────────────────────────────────────────────────
    static let dsSuccess    = Color.dsDynamic(light: 0x11A26B, dark: 0x3DD68C)
    static let dsWarning    = Color.dsDynamic(light: 0xC4780A, dark: 0xF5A83C)
    static let dsDanger     = Color.dsDynamic(light: 0xD92D33, dark: 0xFF6B70)
    static let dsNeutral    = Color.dsDynamic(light: 0x6B7280, dark: 0x9AA1AC)

    // ── Surfaces ─────────────────────────────────────────────────────────────
    /// Page background, behind every card.
    static let dsBackground        = Color(.systemGroupedBackground)
    /// Default card / row surface.
    static let dsSurface           = Color(.secondarySystemGroupedBackground)
    /// A surface sitting *on top* of `dsSurface` (a tile inside a card).
    static let dsSurfaceRaised     = Color(.tertiarySystemGroupedBackground)
    /// Input wells and other recessed areas.
    static let dsSurfaceSunken     = Color(.secondarySystemBackground)

    // ── Lines ────────────────────────────────────────────────────────────────
    static let dsSeparator  = Color(.separator)
    /// The hairline that defines a card's edge in dark mode, where shadows read poorly.
    static let dsHairline   = Color.dsDynamic(light: 0xE3E6EC, dark: 0x2E3238)
}

// MARK: - Design tokens

enum DS {

    // ── Spacing ──────────────────────────────────────────────────────────────
    /// A 4pt base scale. Every gap and inset in the app should come from here so
    /// rhythm stays consistent between screens.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 20
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32

        /// Standard leading/trailing page margin.
        static let page: CGFloat = 16
    }

    // ── Corner radius ────────────────────────────────────────────────────────
    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // ── Icon sizing ──────────────────────────────────────────────────────────
    enum IconSlot {
        static let sm: CGFloat = 28
        static let md: CGFloat = 34
        static let lg: CGFloat = 40
    }

    // ── Motion ───────────────────────────────────────────────────────────────
    /// Three speeds, used everywhere. Keeping the vocabulary this small is what
    /// makes the app feel like one product rather than a pile of screens.
    enum Motion {
        /// Taps, toggles, chip selection.
        static let quick  = Animation.spring(response: 0.28, dampingFraction: 0.78)
        /// Content appearing, cards expanding, list mutations.
        static let smooth = Animation.spring(response: 0.42, dampingFraction: 0.85)
        /// Cross-fades where movement would be noise.
        static let fade   = Animation.easeInOut(duration: 0.22)
    }

    // ── Elevation ────────────────────────────────────────────────────────────
    /// Shadows are a light-mode device. In dark mode a shadow on a dark surface is
    /// invisible, so `DSSurface` swaps it for a hairline border instead.
    enum Elevation {
        case none, low, medium, high

        var radius: CGFloat {
            switch self {
            case .none:   return 0
            case .low:    return 6
            case .medium: return 14
            case .high:   return 24
            }
        }

        var y: CGFloat {
            switch self {
            case .none:   return 0
            case .low:    return 2
            case .medium: return 6
            case .high:   return 12
            }
        }

        var opacity: Double {
            switch self {
            case .none:   return 0
            case .low:    return 0.05
            case .medium: return 0.07
            case .high:   return 0.10
            }
        }
    }
}

// MARK: - Typography

extension Font {

    // Every token is built on a *relative* text style, so the whole app honours
    // Dynamic Type. The previous design used fixed `.system(size:)` throughout,
    // which meant accessibility text sizes had no effect anywhere.

    /// Screen titles. Rounded, because the brand mark is rounded.
    static let dsTitle      = Font.system(.title, design: .rounded, weight: .bold)
    /// Section / card titles.
    static let dsTitle2     = Font.system(.title3, design: .rounded, weight: .bold)
    /// Large monetary figures.
    static let dsAmount     = Font.system(.title3, design: .rounded, weight: .bold)
    /// Row headline — a person's name, a setting's label.
    static let dsHeadline   = Font.system(.subheadline, weight: .semibold)
    /// Default reading text.
    static let dsBody       = Font.system(.subheadline)
    /// Supporting text under a headline.
    static let dsSubtext    = Font.system(.footnote)
    /// Metadata: timestamps, counts, units.
    static let dsCaption    = Font.system(.caption)
    /// Badges and other all-caps micro labels.
    static let dsMicro      = Font.system(.caption2, weight: .semibold)
    /// Button labels.
    static let dsButton     = Font.system(.subheadline, design: .rounded, weight: .semibold)
}

// MARK: - Dynamic Type guards

extension View {

    /// Caps growth on layouts that genuinely cannot reflow — a three-column figure
    /// strip, a horizontal month rail. Everything else scales the whole way up.
    ///
    /// This is the honest trade-off: unbounded scaling in a fixed-column layout
    /// produces clipped text, which is worse for a low-vision user than a slightly
    /// smaller but complete label.
    func dsDenseLayout() -> some View {
        dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// Numeric text that must stay on one line — amounts, counts, dates in a grid.
    func dsNumeric() -> some View {
        lineLimit(1).minimumScaleFactor(0.7)
    }
}
