//
//  ShapeinQR.swift
//  RCC Pay
//
//  Created by HRD on 1/5/26.
//

import SwiftUI

struct ShapeinQR: View {
    var image : String = "square.and.arrow.down"
    var title : String = "ទាញយក"
    @State var isShowShare = false
    var body: some View {
        VStack{
            Button(action: {
                isShowShare.toggle()
            }){
                Circle()
                    .frame(width: 40)
                    .foregroundColor(Color(red: 0.206, green: 0.215, blue: 0.22))
                    .overlay(
                        Image(systemName: image)
                            .foregroundColor(.white)
                     )
            }
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .padding(.top,20)
        .padding([.leading, .bottom, .trailing], 30)
    }
}

#Preview {
    ShapeinQR()
}
