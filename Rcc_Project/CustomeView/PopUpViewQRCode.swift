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
                    Button(action: {
                        isShowingSheet = false
                    }){
                    HStack{
                        Spacer()
                        VStack{
                           
                                Circle()
                                    .frame(width: 30)
                                    .foregroundColor(Color(red: 0.206, green: 0.215, blue: 0.22))
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .foregroundColor(.white)
                                    )
                                    .padding(.trailing, 20.0)
                                Spacer()
                            }
                        }
                    }
                    VStack{
                        HStack{
                            Image("ABALogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50,height: 50)
                            Text("QR")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
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
                        
//                        Button(action:{}) {
//                            HStack{
//                                Image(systemName: "plus.circle").foregroundColor(Color(red: 0.354, green: 1.0, blue: 0.937))
//                                Text("បញ្ចូលចំនួនទឹកប្រាក់")
//                                    .foregroundColor(Color(red: 0.354, green: 1.0, blue: 0.937))
//                            }
//                        }
//                        .frame(width: 250,height: 40)
//                        .background(Color(red: 0.105, green: 0.119, blue: 0.119))
//                        .cornerRadius(5)
//
//                        HStack{
//                            Group{
//                                Text("ទទួលទៅ: ")
//                                    .foregroundColor(.white)
//                                Text("002 490 299 | USD")
//                                    .foregroundColor(Color(red: 0.354, green: 1.0, blue: 0.937))
//                            }.font(.system(size: 13))
//                        }
//                        .padding()
                        
                        HStack{
                            ShapeinQR()
//                            ShapeinQR(image: "dot.circle.viewfinder",title: "ថតអេក្រង់")
//                            ShapeinQR(image: "link",title: "ផ្ញើរលីង")
                        }
                        Spacer()
                    }
                }
                
            .gesture(
                DragGesture()
                    .onEnded({_ in
                        isShowingSheet = false
                    })
                )
        }
    }
//#Preview {
//    PopUpViewQRCode()
//}
