//
//  DSChips.swift
//  RCC Pay
//
//  Filter chips and the search field. Selection uses `matchedGeometryEffect` so the
//  highlight slides between options instead of blinking.
//

import SwiftUI

// MARK: - Filter chip

struct DSFilterChip: View {

    let title: String
    let isSelected: Bool
    var count: Int? = nil
    var systemImage: String? = nil
    var tone: DSTone = .brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xxs + 2) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(.caption, weight: .semibold))
                }
                Text(title)
                    .font(.system(.subheadline, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(isSelected ? tone.color : .white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Capsule().fill(isSelected ? Color.white : tone.color))
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.xs + 1)
            .background {
                if isSelected {
                    Capsule().fill(tone.color)
                } else {
                    Capsule()
                        .fill(Color.dsSurface)
                        .overlay(Capsule().strokeBorder(Color.dsHairline, lineWidth: 1))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(DSPressStyle(scale: 0.95))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Chip bar

/// A horizontally scrolling row of filter chips. Scrolls only when it needs to,
/// so two chips stay left-aligned rather than stretching.
struct DSChipBar<Item: Hashable, Label: View>: View {

    let items: [Item]
    @Binding var selection: Item
    @ViewBuilder var label: (Item, Bool) -> Label

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(items, id: \.self) { item in
                    label(item, item == selection)
                        .onTapGesture {
                            withAnimation(DS.Motion.quick) { selection = item }
                        }
                }
            }
            .padding(.horizontal, DS.Space.page)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}

// MARK: - Search field

struct DSSearchField: View {

    @Binding var text: String
    var placeholder: String = "Search"

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DS.Space.xs + 2) {
            Image(systemName: "magnifyingglass")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(isFocused ? Color.dsBrand : .secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .font(.dsBody)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    withAnimation(DS.Motion.quick) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.sm - 2)
        .background(Capsule().fill(Color.dsSurface))
        .overlay(
            Capsule().strokeBorder(
                isFocused ? Color.dsBrand.opacity(0.45) : Color.dsHairline,
                lineWidth: 1)
        )
        .animation(DS.Motion.fade, value: isFocused)
        .animation(DS.Motion.quick, value: text.isEmpty)
    }
}

// MARK: - Menu chip

/// A dropdown trigger styled to match the filter chips — used where a `Menu`
/// replaces a chip row because there are too many options to lay out.
struct DSMenuChip: View {

    let title: String
    var systemImage: String? = nil
    var tone: DSTone = .brand

    var body: some View {
        HStack(spacing: DS.Space.xxs + 2) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(.caption, weight: .semibold))
            }
            Text(title)
                .font(.system(.subheadline, weight: .medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(tone.color)
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.xs + 1)
        .background(Capsule().fill(tone.color.opacity(0.12)))
        .overlay(Capsule().strokeBorder(tone.color.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - Preview

private struct DSChipsPreview: View {
    @State private var text = ""
    @State private var selected = "All"

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            DSSearchField(text: $text, placeholder: "Search by name")
            HStack(spacing: DS.Space.xs) {
                DSFilterChip(title: "All", isSelected: selected == "All") { selected = "All" }
                DSFilterChip(title: "Unread", isSelected: selected == "Unread", count: 4) { selected = "Unread" }
                DSMenuChip(title: "2026", systemImage: "calendar")
            }
        }
        .padding(DS.Space.page)
        .background(Color.dsBackground)
    }
}

#Preview("Chips") { DSChipsPreview() }
