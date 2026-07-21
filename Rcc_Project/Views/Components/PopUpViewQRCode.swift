//
//  PopUpViewQRCode.swift
//  RCC Pay
//
//  Created by HRD on 12/31/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct PopUpViewQRCode: View {
    @Binding var isShowingSheet: Bool
    /// Amount still owed for the selected month; shown on the confirm button.
    var payAmount: Double = 0
    /// Called when the user confirms they've paid. When nil, no confirm button is shown.
    var onConfirmPaid: (() -> Void)? = nil
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
                
                makeBody(payAmount: payAmount)
                if let shareImage = shareImage{
                    ShareQRcode(image: shareImage)
                }

                // if let onConfirmPaid, payAmount > 0 {
                //     Button {
                //         onConfirmPaid()
                //         isShowingSheet = false
                //     } label: {
                //         HStack(spacing: 8) {
                //             Image(systemName: "checkmark.circle.fill")
                //             Text("I've paid $\(String(format: "%.2f", payAmount))")
                //                 .fontWeight(.semibold)
                //         }
                //         .foregroundColor(.white)
                //         .padding(.horizontal, 24)
                //         .padding(.vertical, 14)
                //         .background(
                //             RoundedRectangle(cornerRadius: 14)
                //                 .fill(Color(red: 0.18, green: 0.75, blue: 0.48)))
                //     }
                //     .padding(.top, 18)
                // }
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
    
    
    func saveToTemporaryDirectory(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("RCC_QR.png")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func makeBody(payAmount: Double) -> some View {
        QRImage(payamount: payAmount)
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
            makeBody(payAmount: payAmount)
                .padding()
        }
    }
    
}


struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}



#Preview {
    ContentView()
}
