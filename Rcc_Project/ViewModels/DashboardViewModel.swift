//
//  DashboardViewModel.swift
//  RCC Pay
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var paymentModels: [PaymentModel] = [
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00")
    ]

    @Published var selectedMonth: String = ""
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    let months = Calendar.current.monthSymbols
}
