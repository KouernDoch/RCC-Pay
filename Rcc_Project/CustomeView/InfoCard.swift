//
//  InfoCard.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct InfoCard: View {
    @State var title = ""
    @State var value = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
//                .font(.title3)
            Text("$ \(value)")
                .foregroundColor(.blue)
                .bold()
        }
        .frame(maxWidth: .infinity, minHeight: 100)

        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
    }
}

#Preview {
    InfoCard()
}
