//
//  DateSelect.swift
//  Rcc_Project
//
//  The horizontal month rail under the dashboard header.
//
//  Behaviour is unchanged — it still owns the selected month and reports it upward via
//  `onMonthSelected`, firing once on first appearance. The layout no longer derives its
//  sizes from `GeometryReader` proportions (which produced different metrics on every
//  device); month pills are now a fixed, legible size that scrolls.
//

import SwiftUI

struct DateSelect: View {

    @EnvironmentObject private var lm: LocalizationManager

    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var hasAppeared = false

    private let months = Array(1...12)

    let onMonthSelected: (Int) -> Void

    /// Short month names in the app's current language, not the device's.
    private var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lm.language)
        return formatter.shortMonthSymbols
    }

    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.xs) {
                    ForEach(months, id: \.self) { month in
                        DSMonthPill(
                            number: month,
                            name: monthNames[safe: month - 1] ?? "",
                            isSelected: month == selectedMonth,
                            isCurrent: month == currentMonth
                        ) {
                            select(month, proxy: proxy)
                        }
                        .id(month)
                    }
                }
                .padding(.horizontal, DS.Space.page)
                .padding(.vertical, DS.Space.xs)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onAppear {
                // Only report on the very first appearance — re-reporting on every scroll
                // would re-trigger the parent's summary reload.
                if !hasAppeared {
                    hasAppeared = true
                    onMonthSelected(selectedMonth)
                }
                proxy.scrollTo(selectedMonth, anchor: .center)
            }
        }
        .frame(height: 74)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Month")
    }

    private func select(_ month: Int, proxy: ScrollViewProxy) {
        withAnimation(DS.Motion.quick) {
            selectedMonth = month
            proxy.scrollTo(month, anchor: .center)
        }
        onMonthSelected(month)
    }
}

// MARK: - Month pill

private struct DSMonthPill: View {

    let number: Int
    let name: String
    let isSelected: Bool
    /// The real-world current month gets a marker dot so "today" stays findable
    /// after the user has browsed away from it.
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(name.uppercased())
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .kerning(0.4)

                Text(String(format: "%02d", number))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .monospacedDigit()

                Circle()
                    .fill(isSelected ? Color.white.opacity(0.9) : Color.dsBrand)
                    .frame(width: 4, height: 4)
                    .opacity(isCurrent ? 1 : 0)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(width: 52, height: 58)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(Color.dsBrand)
                } else {
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(Color.dsSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                .strokeBorder(Color.dsHairline, lineWidth: 1)
                        )
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        }
        .buttonStyle(DSPressStyle(scale: 0.93))
        .dsDenseLayout()
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Safe index

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DateSelect { print("Selected month: \($0)") }
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.dsBackground)
    .environmentObject(LocalizationManager())
}
