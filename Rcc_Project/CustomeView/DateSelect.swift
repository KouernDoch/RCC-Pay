//
//  DateSelect.swift
//  Rcc_Project
//
//  Created by HRD on 12/31/25.
//
import SwiftUI

struct DateSelect: View {

    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var hasAppeared = false
    private let months = Array(1...12)
    
    let onMonthSelected: (Int) -> Void
    
    private var monthNames: [String] {
        let formatter = DateFormatter()
        //        formatter.locale = languageManager.currentLocale
        return formatter.shortMonthSymbols
    }
    
    var body: some View {
        GeometryReader { geometry in
            let rows = [GridItem(.fixed(geometry.size.height))]
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: geometry.size.width * 0.036) {
                        ForEach(months, id: \.self) { month in
                            MonthCard(
                                monthNumber: month,
                                monthName: monthNames[month - 1],
                                isSelected: month == selectedMonth,
                                cardWidth: geometry.size.width * 0.1,
                                cardHeight: geometry.size.width * 0.14,
                                geometry: geometry
                            ) {
                                withAnimation {
                                    selectedMonth = month
                                    scrollProxy.scrollTo(month, anchor: .center)
                                }
                                onMonthSelected(month)
                            }
                            .id(month)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)
                    
                }
                .onAppear {
                    // Only auto-select month on first appearance, not on every scroll
                    if !hasAppeared {
                        hasAppeared = true
                        onMonthSelected(selectedMonth)
                    }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scrollProxy.scrollTo(selectedMonth, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 90)
    }
}

struct MonthCard: View {
    let monthNumber: Int
    let monthName: String
    let isSelected: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let geometry: GeometryProxy
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
//        Text("Hello")
        Button(action: onTap){
            VStackLayout(spacing: cardHeight * 0.05){
                Text(String(format: "%02d", monthNumber))
                    .font(.system(size: cardWidth * 0.35))
                    .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white : .black))
                Text(monthName)
                    .font(.system(size: cardWidth * 0.25, weight: .semibold))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.9) : .black))
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(
                ZStack{
                    RoundedRectangle(cornerRadius: cardWidth * 0.2)
                        .fill(.ultraThinMaterial)
                    if colorScheme == .dark {
                                            RoundedRectangle(cornerRadius: cardWidth * 0.2)
                            .fill(isSelected ? Color.primary : Color.clear)
                                                .opacity(isSelected ? 1 : 0.5)
                                                .animation(.easeInOut(duration: 0.3), value: isSelected)
                                        } else if colorScheme == .light {
                                            RoundedRectangle(cornerRadius: cardWidth * 0.2)
                                                .fill(isSelected ? Color.primary : Color.white)
                                        }
                }
            )
            .overlay(
                    RoundedRectangle(cornerRadius: cardWidth * 0.2, style: .continuous)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3) ,lineWidth: isSelected ? 1.2 : 0.8)
                        )
                       .shadow(color: .gray.opacity(0.08), radius: 5, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
            DateSelect { selectedMonth in
                print("Selected month: \(selectedMonth)")
            }
        }
}
