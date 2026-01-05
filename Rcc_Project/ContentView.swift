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
        ZStack{
            Color(Color(red: 245/255, green: 249/255, blue: 255/255)).ignoresSafeArea(.all)
            VStack(alignment:.leading){
                HStack{
                    Image("Profile")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                    VStack(alignment: .leading){
                        Text("Kouern Doch")
                            .font(.system(size: 16))
                        Text("Normal User")
                            .foregroundStyle(.gray)
                            .font(.system(size: 14))
                        
                    }
                    
                    Spacer()
                    Image(systemName: "bell")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                        .padding(.horizontal)
                    Image(systemName: "gearshape")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                }
                .padding(.horizontal)
                
                DateSelect { selectedDate in
                    selectedmonth = months[selectedDate - 1]
                }
//                ScrollView(.vertical, showsIndicators: false) {
                    CardViewMonthlyBill(selectedmonth: $selectedmonth,selectedYear: $selectedYear)
                        Text("Daily Payment")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    // card Payment
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(paymentModels) { paymentModel in
                                CardPayment(name: paymentModel.name, image: paymentModel.image, date: paymentModel.date, amount: paymentModel.amount)
                            }
                        }
                    }
                    
                    
                    Spacer()
//                }
                
            }
            .onChange(of: selectedYear) { oldValue, newValue in
                print("Year:", selectedYear, "Month:", selectedmonth)
            }
            .onChange(of: selectedmonth) { oldValue, newValue in
                print("Year:", selectedYear, "Month:", selectedmonth)
            }
            
        }
        
    }
}

#Preview {
    ContentView()
}
