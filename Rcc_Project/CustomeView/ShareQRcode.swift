//
//  ShareQRcode.swift
//  RCC Pay
//
//  Created by HRD on 1/6/26.
//

import SwiftUI

struct ShareQRcode: View {
    var image: UIImage

        @State private var isShowingShareSheet = false

        var body: some View {
            Button(action: {
                isShowingShareSheet = true
            }) {
                VStack {
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
            .sheet(isPresented: $isShowingShareSheet) {
                ActivityView(activityItems: [image])
            }
        }
    }
