//
//  GlassCardModifier.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
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
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.03),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                cardShape
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            }
            .overlay {
                cardShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.52),
                                Color.white.opacity(0.12),
                                Color.black.opacity(0.10),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(cardShape)
            .shadow(color: .black.opacity(0.16), radius: 22, y: 14)
            .shadow(color: .white.opacity(0.12), radius: 10, y: -2)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
