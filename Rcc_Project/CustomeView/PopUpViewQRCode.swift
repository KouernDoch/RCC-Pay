//
//  PopUpViewQRCode.swift
//  RCC Pay
//
//  Created by HRD on 12/31/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct PopUpViewQRCode: View {
    @Binding var isShowingSheet: Bool

        var body: some View {
                ZStack {
                    Color.black.opacity(1)
                        .edgesIgnoringSafeArea(.all)
            HStack{
                
            }
                    VStack{
                        HStack{
//                            Image("ABALogo")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 50,height: 50)
//                            Text("QR")
//                                .font(.title3)
//                                .fontWeight(.medium)
//                                .foregroundColor(.white)
                            // X BUTTON
                            Text("")
                                .padding()
                            Spacer()
                            Text("QR Code")
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                            Button(action: {
                                isShowingSheet.toggle()
                            }){
                                VStack{
                                        Circle()
                                            .frame(width: 30)
                                            .foregroundColor(Color(red: 0.206, green: 0.215, blue: 0.22))
                                            .overlay(
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.white)
                                            )
                                    }
                        
                            }
                            .padding()
                        }
                        Text("ប្រើ​ QR នេះ ដើម្បីបង់ប្រាក់សម្រាប់")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        HStack{
                            Text("ការស្នាក់នៅនិងថ្លៃម្ហូបរបស់លោកអ្នកនៅ RCC")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Button(action:{}){
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(hue: 0.527, saturation: 0.713, brightness: 0.745))
                            }
                        }
                        
                        QRImage()
                            .cornerRadius(50)
                                        
                        HStack{
                            ShapeinQR()
                        }
                        Spacer()
                    }
                }
        }
    }
//#Preview {
//    PopUpViewQRCode()
//}
