//
//  ButtonQRCode.swift
//  RCC Pay
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct ButtonQRCode: View {
    @State private var isShowingSheet = false
    var body: some View {
        Button(action: {
            isShowingSheet.toggle()
        }){
            HStack{
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("Pay via QR Code")
                    .bold()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .fullScreenCover(isPresented: $isShowingSheet){
            PopUpViewQRCode(isShowingSheet: $isShowingSheet)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    ContentView()
}
