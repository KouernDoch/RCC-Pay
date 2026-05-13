//
//  InfoCard.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//

import SwiftUI

struct InfoCard: View {
    var title: String = ""
    var value: String = ""
    var icon: String  = "creditcard.fill"
    var iconColor: Color = .blue

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack {
                Circle()
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("$ \(value)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        InfoCard(title: "Remain Amount", value: "0.00",  icon: "clock.fill",             iconColor: .orange)
        InfoCard(title: "Paid Amount",   value: "38.00", icon: "checkmark.circle.fill",  iconColor: Color(red: 0.18, green: 0.75, blue: 0.48))
    }
    .padding()
}
