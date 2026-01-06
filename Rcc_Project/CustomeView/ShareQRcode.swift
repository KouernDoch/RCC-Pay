//
//  ShareQRcode.swift
//  RCC Pay
//
//  Created by HRD on 1/6/26.
//

import SwiftUI

struct ShareQRcode: View {
        @State private var shareImage : UIImage?
        @State private var didCallOnAppearForTheFirstTime = false
        var body: some View {
            VStack{
                makeBody()
                if let shareImage {
                    let imageAsswiftUIImage = Image(uiImage: shareImage)
                    if #available(iOS 16.0, *) {
                        ShareLink(item: imageAsswiftUIImage,preview: SharePreview("Achievement!",image: imageAsswiftUIImage)){
                            Text("Share")
                        }
                    } else {
                        Button("Click Me") {
                            
                        }

                    }
                }
            }
            .onAppear{
                guard didCallOnAppearForTheFirstTime == false else{
                    return
                }
                didCallOnAppearForTheFirstTime = true
                renderImage()
            }
            .padding()
            
        }
        
        func makeBody() -> some View {
            QRImage()
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
            .background(Color.white)
        }
    }

#Preview {
    ShareQRcode()
}
