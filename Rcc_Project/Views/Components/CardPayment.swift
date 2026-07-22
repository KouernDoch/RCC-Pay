//
//  CardPayment.swift
//  Rcc_Project
//
//  A single row in the payment feed. Now a thin composition over `DSPersonCard`, so it
//  picks up the shared avatar, surface and amount-pill treatment automatically.
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
    /// Colours the amount pill. Payments read as settled money by default; the admin
    /// unpaid list passes `.warning` so the same row can carry the opposite meaning.
    var tone: DSTone = .success

    var body: some View {
        DSPersonCard(
            name: name,
            subtitle: date,
            imageURL: profileImage,
            placeholder: image
        ) {
            DSAmountPill(amount: amount, tone: tone)
        }
        .padding(.horizontal, DS.Space.page)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(date), $\(amount)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DS.Space.xs) {
        CardPayment()
        CardPayment(name: "Kouern Doch", date: "15 Mar, 2026", amount: "45.00")
        CardPayment(name: "Phan Sopheak", date: "Unpaid · March 2026", amount: "38.00", tone: .warning)
    }
    .padding(.vertical)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.dsBackground)
}
