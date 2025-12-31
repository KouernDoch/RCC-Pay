//
//  ButtonQRCode.swift
//  RCC Pay
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct ButtonQRCode: View {
    var body: some View {
        Button(action: {
            
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
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    ContentView()
}
