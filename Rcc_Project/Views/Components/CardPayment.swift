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
    var image  = "Profile"
    var date   = "01 Jan, 2026"
    var amount = "38.00"

    @Environment(\.colorScheme) private var colorScheme
    private let mint = Color(red: 0.18, green: 0.75, blue: 0.48)

    var body: some View {
        HStack(spacing: 14) {

            // Profile image
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [mint.opacity(0.6), mint.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white, mint)
                        .background(Circle().fill(Color(.systemBackground)))
                        .offset(x: 2, y: 2)
                }

            // Name + date
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .medium))
                    Text(date)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(amount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(mint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(mint.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    )

                Text("Paid")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.04),
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark ? .clear : mint.opacity(0.08),
            radius: 10, x: 0, y: 4
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 14) {
        CardPayment()
        CardPayment(name: "Kouern Doch", date: "15 Mar, 2026", amount: "45.00")
    }
    .padding(.vertical)
    .frame(maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
