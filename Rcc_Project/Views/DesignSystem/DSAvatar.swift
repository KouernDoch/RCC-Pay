//
//  DSAvatar.swift
//  RCC Pay
//
//  Presentation wrapper around the existing `RemoteAvatarView` / `ProfileAvatarView`.
//  The image loading and caching in those types is untouched — this only adds the ring,
//  the optional status dot and a consistent size scale.
//

import SwiftUI

// MARK: - Size scale

enum DSAvatarSize {
    case xs, sm, md, lg, xl

    var points: CGFloat {
        switch self {
        case .xs: return 32
        case .sm: return 40
        case .md: return 46
        case .lg: return 56
        case .xl: return 92
        }
    }

    var ringWidth: CGFloat {
        switch self {
        case .xl: return 3
        case .lg: return 2
        default:  return 1
        }
    }
}

// MARK: - Any user's avatar

struct DSAvatar: View {

    /// Backend `profileImage` URL.
    let urlString: String?
    var size: DSAvatarSize = .md
    var placeholder: String = "Profile"
    /// Coloured ring — used to carry payment status on a resident row.
    var ring: Color? = nil
    /// Small dot at the bottom-trailing corner (unread, online, paid).
    var statusTone: DSTone? = nil

    var body: some View {
        RemoteAvatarView(urlString: urlString, size: size.points, placeholder: placeholder)
            .overlay(
                Circle().strokeBorder(
                    ring ?? Color.primary.opacity(0.08),
                    lineWidth: ring == nil ? 1 : size.ringWidth)
            )
            .overlay(alignment: .bottomTrailing) {
                if let statusTone {
                    Circle()
                        .fill(statusTone.color)
                        .frame(width: size.points * 0.26, height: size.points * 0.26)
                        .overlay(Circle().strokeBorder(Color.dsSurface, lineWidth: 2))
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Signed-in user's avatar

struct DSSelfAvatar: View {

    var size: DSAvatarSize = .md
    /// A just-picked photo that hasn't finished uploading; outranks the remote URL.
    var localOverride: UIImage? = nil
    var ring: Color? = nil

    var body: some View {
        ProfileAvatarView(size: size.points, localOverride: localOverride)
            .overlay(
                Circle().strokeBorder(
                    ring ?? Color.primary.opacity(0.10),
                    lineWidth: ring == nil ? 1 : size.ringWidth)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Monogram fallback

/// Initials on a tinted disc, for people with no photo where a generic silhouette
/// would read as an error.
struct DSMonogram: View {

    let name: String
    var size: DSAvatarSize = .md
    var tone: DSTone = .brand

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let text = String(parts).uppercased()
        return text.isEmpty ? "?" : text
    }

    var body: some View {
        Circle()
            .fill(tone.color.opacity(0.15))
            .frame(width: size.points, height: size.points)
            .overlay(
                Text(initials)
                    .font(.system(size: size.points * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(tone.color)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Avatars") {
    HStack(spacing: DS.Space.md) {
        DSAvatar(urlString: nil, size: .sm)
        DSAvatar(urlString: nil, size: .md, ring: .dsSuccess, statusTone: .success)
        DSMonogram(name: "Kouern Doch", size: .lg)
        DSMonogram(name: "Leng Chingmony", size: .xl, tone: .success)
    }
    .padding(DS.Space.page)
    .background(Color.dsBackground)
}
