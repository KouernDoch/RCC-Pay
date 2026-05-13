//
//  PaymentModel.swift
//  RCC Pay
//

import Foundation

struct PaymentModel: Identifiable {
    let id = UUID()
    var image: String
    var name: String
    var date: String
    var amount: String
}
