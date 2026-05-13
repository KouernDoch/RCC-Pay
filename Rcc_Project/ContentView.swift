//
//  ContentView.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct PaymentModel : Identifiable {
    let id = UUID()
    var image: String
    var name : String
    var date : String
    var amount : String
}
struct ContentView: View {

    @EnvironmentObject private var lm: LocalizationManager

    @State var paymentModels : [PaymentModel] = [
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00"),
        PaymentModel(image: "Profile", name: "Leng Chingmony", date: "01 Jan, 2026", amount: "38.00")
    ]
    @State var selectedmonth = ""
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    let months = Calendar.current.monthSymbols
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    DashboardChromeView(
                        displayName: "Kouern Doch",
                        roleSubtitle: lm["normal_user"],
                        onMonthSelected: { selectedDate in
                            selectedmonth = months[selectedDate - 1]
                        }
                    )

                    // ── Scrollable content ────────────────────────
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            CardViewMonthlyBill(
                                selectedmonth: $selectedmonth,
                                selectedYear: $selectedYear
                            )
                            .padding(.top, 4)

                            // Section header
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(Color(red: 0.22, green: 0.50, blue: 0.98))
                                    .frame(width: 3, height: 14)
                                    .clipShape(Capsule())
                                Text(lm["daily_payment"])
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(lm["see_all"])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(red: 0.22, green: 0.50, blue: 0.98))
                            }
                            .padding(.horizontal)
                            .padding(.top, 14)
                            .padding(.bottom, 6)

                            // Cards
                            VStack(spacing: 8) {
                                ForEach(paymentModels) { paymentModel in
                                    CardPayment(
                                        name: paymentModel.name,
                                        image: paymentModel.image,
                                        date: paymentModel.date,
                                        amount: paymentModel.amount
                                    )
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
                .onChange(of: selectedYear)  { _, _ in }
                .onChange(of: selectedmonth) { _, _ in }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager())
}
