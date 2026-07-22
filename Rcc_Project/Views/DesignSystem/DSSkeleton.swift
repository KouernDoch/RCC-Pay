//
//  DSSkeleton.swift
//  RCC Pay
//
//  Skeleton placeholders. Showing the *shape* of the incoming content reads as faster
//  than a spinner and stops the layout jumping when data lands.
//
//  Respects Reduce Motion: the shimmer sweep becomes a static fill.
//

import SwiftUI

// MARK: - Shimmer

private struct DSShimmer: ViewModifier {

    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing)
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width * 1.6)
                        .blendMode(.plusLighter)
                    }
                }
                .mask(content)
                .task {
                    // A single long repeating sweep; `.linear` keeps the pace even.
                    withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

extension View {
    func dsShimmer() -> some View { modifier(DSShimmer()) }
}

// MARK: - Primitives

/// A single grey bar standing in for a line of text.
struct DSSkeletonBar: View {

    var width: CGFloat? = nil
    var height: CGFloat = 12
    var radius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.dsHairline)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .dsShimmer()
    }
}

/// Circular placeholder for an avatar.
struct DSSkeletonCircle: View {
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(Color.dsHairline)
            .frame(width: size, height: size)
            .dsShimmer()
    }
}

// MARK: - Composed skeletons

/// Placeholder matching `DSPersonRow` — avatar, two lines, trailing pill.
struct DSSkeletonRow: View {

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            DSSkeletonCircle(size: 44)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                DSSkeletonBar(width: 130, height: 12)
                DSSkeletonBar(width: 80, height: 10)
            }
            Spacer()
            DSSkeletonBar(width: 58, height: 24, radius: 12)
        }
        .padding(.horizontal, DS.Space.sm + 2)
        .padding(.vertical, DS.Space.sm)
        .dsSurface(radius: DS.Radius.md, elevation: .low)
    }
}

/// Placeholder matching the monthly-bill card.
struct DSSkeletonCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    DSSkeletonBar(width: 84, height: 10)
                    DSSkeletonBar(width: 130, height: 16)
                }
                Spacer()
                DSSkeletonBar(width: 64, height: 24, radius: 12)
            }
            HStack(spacing: DS.Space.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: DS.Space.xs) {
                        DSSkeletonBar(height: 16)
                        DSSkeletonBar(height: 9)
                    }
                }
            }
            DSSkeletonBar(height: 46, radius: DS.Radius.md)
        }
        .padding(DS.Space.md)
        .dsSurface(radius: DS.Radius.lg, elevation: .low)
    }
}

/// A stack of row skeletons. `count` should match the list's typical page size so the
/// scroll height doesn't lurch when real rows replace it.
struct DSSkeletonList: View {

    var count: Int = 4

    var body: some View {
        VStack(spacing: DS.Space.xs) {
            ForEach(0..<count, id: \.self) { _ in DSSkeletonRow() }
        }
        // The whole stack is decorative — VoiceOver announces the loading state instead.
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

// MARK: - Preview

#Preview("Skeletons") {
    ScrollView {
        VStack(spacing: DS.Space.md) {
            DSSkeletonCard()
            DSSkeletonList(count: 3)
        }
        .padding(DS.Space.page)
    }
    .background(Color.dsBackground)
}
