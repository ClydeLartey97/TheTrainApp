//
//  GlassCardModifier.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: cardShape)
            .overlay {
                cardShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.05),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                cardShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .clipShape(cardShape)
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.35)
                    : .black.opacity(0.06),
                radius: colorScheme == .dark ? 20 : 10,
                y: colorScheme == .dark ? 12 : 5
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
