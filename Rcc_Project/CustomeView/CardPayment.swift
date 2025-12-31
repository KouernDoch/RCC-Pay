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
    @State var name = "Leng chinmony"
    @State var image = "Profile"
    @State var date = "01 Jan, 2026"
    @State var amount = "38.00"
    var body: some View {
        HStack{
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            VStack(alignment: .leading){
                Text(name)
                Text(date)
                    .foregroundColor(.gray)
                    .kerning(2)
            }
            Spacer()
            Text("$ \(amount)")
                .foregroundColor(Color(red: 0.3058823529411765, green: 0.803921568627451, blue: 0.5411764705882353))
                .bold()
                
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .gray.opacity(0.08), radius: 5, x: 0, y: 0)

        )
        .padding(.horizontal)
    }
}

#Preview {
    CardPayment()
}
