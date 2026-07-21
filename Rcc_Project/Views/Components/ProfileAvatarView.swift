//
//  ProfileAvatarView.swift
//  RCC Pay
//
//  The signed-in user's avatar, sourced from the backend's `profileImage`.
//  Single render path for every screen that shows the current user's photo.
//

import SwiftUI

/// In-memory cache for avatars fetched from `/api/files/view/...`.
///
/// The backend serves these with `Cache-Control: no-store` (Spring Security's default),
/// so `URLSession`'s own cache never keeps them and every render would otherwise hit the
/// network. Caching here is safe regardless: each upload gets a fresh UUID filename, so a
/// given URL always maps to the same immutable image.
@MainActor
final class ProfileImageCache {
    static let shared = ProfileImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() { cache.countLimit = 32 }

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

/// Circular avatar for *any* user, loaded from a backend `profileImage` URL.
///
/// Use this wherever a photo belongs to someone other than the signed-in user (resident lists,
/// payment feeds). For the current user, prefer ``ProfileAvatarView``, which resolves the URL
/// from the session.
struct RemoteAvatarView: View {

    /// Backend `profileImage` value. Nil/empty renders the placeholder asset.
    let urlString: String?
    let size: CGFloat

    /// A just-picked photo that hasn't finished uploading yet. Outranks the remote URL,
    /// which still resolves to the *old* image until the profile refresh lands.
    var localOverride: UIImage? = nil

    /// Asset shown while nothing has loaded.
    var placeholder: String = "Profile"

    @State private var loaded: UIImage?
    @State private var isLoading = false

    private var remoteURL: URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    var body: some View {
        Group {
            if let shown = localOverride ?? loaded {
                Image(uiImage: shown).resizable().scaledToFill()
            } else if isLoading {
                ZStack { Color.gray.opacity(0.15); ProgressView().scaleEffect(0.6) }
            } else {
                Image(placeholder).resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: remoteURL) { await load() }
    }

    private func load() async {
        guard let url = remoteURL else {
            loaded = nil
            return
        }
        if let cached = ProfileImageCache.shared.image(for: url) {
            loaded = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else {
            // Leave `loaded` alone: a failed refetch shouldn't blank an avatar we already have.
            return
        }
        ProfileImageCache.shared.insert(image, for: url)
        loaded = image
    }
}

/// The signed-in user's avatar. Thin wrapper over ``RemoteAvatarView`` that resolves the URL
/// from the session.
struct ProfileAvatarView: View {

    @EnvironmentObject private var session: SessionStore
    @AppStorage("profileImageURL") private var profileImageURLString: String = ""

    let size: CGFloat

    var localOverride: UIImage? = nil

    /// Prefer the backend's persisted `profileImage`; fall back to the URL cached from
    /// the last upload so the avatar survives a cold launch before the profile arrives.
    private var resolvedURLString: String? {
        if let remote = session.currentUser?.profileImage, !remote.isEmpty {
            return remote
        }
        return profileImageURLString.isEmpty ? nil : profileImageURLString
    }

    var body: some View {
        RemoteAvatarView(urlString: resolvedURLString, size: size, localOverride: localOverride)
    }
}
