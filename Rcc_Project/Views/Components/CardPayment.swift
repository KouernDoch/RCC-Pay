//
//  CardPayment.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct Item: Identifiable {
    let id = UUID()
    var title: String
}

struct CardPayment: View {
    var name   = "Leng Chinmony"
    /// Placeholder asset, used when `profileImage` is nil or fails to load.
    var image  = "Profile"
    /// Backend `profileImage` URL for this person.
    var profileImage: String? = nil
    var date   = "01 Jan, 2026"
    var amount = "38.00"

    @Environment(\.colorScheme) private var colorScheme
    private let mint = Color(red: 0.18, green: 0.75, blue: 0.48)

    var body: some View {
        HStack(spacing: 12) {

            // Profile image
            RemoteAvatarView(urlString: profileImage, size: 44, placeholder: image)
                .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))

            // Name + date
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(date)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text("$\(amount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(mint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(mint.opacity(colorScheme == .dark ? 0.18 : 0.1)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 12) {
        CardPayment()
        CardPayment(name: "Kouern Doch", date: "15 Mar, 2026", amount: "45.00")
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}
