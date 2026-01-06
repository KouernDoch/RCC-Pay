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
    @State private var shareImage : UIImage?
    @State private var didCallOnAppearForTheFirstTime = false

        var body: some View {
                ZStack {
                    Color.black.opacity(1)
                        .edgesIgnoringSafeArea(.all)
                    VStack{
                        HStack{
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
                        
                        makeBody()
                        if let shareImage {
                            let imageAsswiftUIImage = Image(uiImage: shareImage)
                                ShareLink(item: imageAsswiftUIImage,preview: SharePreview("RCC Pay",image: imageAsswiftUIImage)){
                                    VStack{
                                        Circle()
                                            .frame(width: 40)
                                            .foregroundColor(Color(red: 0.206, green: 0.215, blue: 0.22))
                                            .overlay(
                                                Image(systemName: "square.and.arrow.up")
                                                    .foregroundColor(.white)
                                            )
                                        Text("ផ្ញើរ Qr")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                 
   }
                                }
                        }
                                        
//                        HStack{
//                            ShapeinQR()
//                        }
                        Spacer()
                    }
                    .onAppear{
                        guard didCallOnAppearForTheFirstTime == false else{
                            return
                        }
                        didCallOnAppearForTheFirstTime = true
                        renderImage()
                    }
                }
            
        }
    func makeBody() -> some View {
        QRImage()
            .cornerRadius(50)
    }
    func renderImage(){
        let body = makeShareableView()
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: body)
            guard let image = renderer.uiImage else {
                return
            }
            shareImage = image
        } else {
            // Fallback on earlier versions
        }
    }

    private func makeShareableView() -> some View {
        VStack {
            makeBody()
                .padding()
        }
    }
    
    }
#Preview {
    ContentView()
}
