//
//  PaymentModel.swift
//  RCC Pay
//

import Foundation

struct PaymentModel: Identifiable {
    let id = UUID()
    /// Local asset used as the placeholder when the payer has no uploaded photo.
    var image: String
    /// Backend `profileImage` URL for the payer. Nil when they never uploaded one.
    var profileImage: String? = nil
    var name: String
    var date: String
    var amount: String
}
