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

struct ProfileAvatarView: View {

    @EnvironmentObject private var session: SessionStore
    @AppStorage("profileImageURL") private var profileImageURLString: String = ""

    let size: CGFloat

    /// A just-picked photo that hasn't finished uploading yet. Outranks the remote URL,
    /// which still resolves to the *old* image until the profile refresh lands.
    var localOverride: UIImage? = nil

    @State private var loaded: UIImage?
    @State private var isLoading = false

    /// Prefer the backend's persisted `profileImage`; fall back to the URL cached from
    /// the last upload so the avatar survives a cold launch before the profile arrives.
    private var remoteURL: URL? {
        if let remote = session.currentUser?.profileImage, !remote.isEmpty {
            return URL(string: remote)
        }
        return profileImageURLString.isEmpty ? nil : URL(string: profileImageURLString)
    }

    var body: some View {
        Group {
            if let shown = localOverride ?? loaded {
                Image(uiImage: shown).resizable().scaledToFill()
            } else if isLoading {
                ZStack { Color.gray.opacity(0.15); ProgressView().scaleEffect(0.6) }
            } else {
                Image("Profile").resizable().scaledToFill()
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
