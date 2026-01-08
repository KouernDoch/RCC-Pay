//
//  CardViewMonthlyBill.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

func generateYears(
    past: Int = 5,
    future: Int = 10
) -> [Int] {
    let currentYear = Calendar.current.component(.year, from: Date())
    return Array((currentYear - past)...(currentYear + future))
}

struct CardViewMonthlyBill: View {
    @Binding var selectedmonth : String
    @Binding var selectedYear : Int
    let years = generateYears()
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentColor)
                    HStack{
                        Text("Monthly Bill - \(selectedmonth) ")
                        //                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                        Spacer()
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                            
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Total Amount Card
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Amount")
                        //                            .font(.title3)
                        Text("$ 38.00")
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "dollarsign")
                        .foregroundColor(.blue)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                        )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                )
                
                // Bottom Cards (Responsive)
                HStack(spacing: 12) {
                    InfoCard(title:"Remain amount",value: "0.00")
                    InfoCard(title:"Paid amount",value: "38.00")
                }
                ButtonQRCode()
                Spacer()
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.8392156862745098, green: 0.9529411764705882, blue: 1.0))
                    .shadow(color: .gray.opacity(0.08), radius: 5, x: 0, y: 0)
            )
            .padding(.horizontal)
        }
        
    }
}


#Preview {
    ContentView()
    
}
