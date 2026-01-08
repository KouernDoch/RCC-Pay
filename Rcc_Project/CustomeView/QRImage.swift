//
//  QRImage.swift
//  RCC Pay
//
//  Created by HRD on 1/5/26.
//
import SwiftUI

struct QRImage: View {
    var qrcodeImage = QrCodeImage()
    @State private var text = "00020101021129450016abaakhppxxx@abaa01090024902990208ABA Bank40390006abaP2P01129B44C11C847502090024902995204000053038405802KH5911KOUERN DOCH6010Phnom Penh630414D3"
    var body: some View {
        Image("KHQR")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 250)
            .overlay(
                VStack{
                    HStack{
                        VStack(alignment: .leading){
                            Text("KOUERN DOCH")
                                .foregroundColor(.black)
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .padding(.top,20)
                            Text("$ 0.00")
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                            
                        }
                        .padding()
                        Spacer()
                    }
                    .padding(.leading, 20.0)
                    Image(uiImage: qrcodeImage.generateQRCode(from: text))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180)
                }
            )
        
    }
}


struct QrCodeImage {
    let context = CIContext()
    
    func generateQRCode(from text: String) -> UIImage {
        var qrImage = UIImage(systemName: "xmark.circle") ?? UIImage()
        let data = Data(text.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            if let image = context.createCGImage(
                outputImage,
                from: outputImage.extent) {
                qrImage = UIImage(cgImage: image)
            }
        }
        return qrImage
    }
}
