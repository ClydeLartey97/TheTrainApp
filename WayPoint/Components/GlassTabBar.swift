//
//  GlassTabBar.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.60), Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 116, height: 4)
                .padding(.top, 8)

            HStack(spacing: 12) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: tab.symbol)
                                .font(.subheadline.weight(.bold))
                            Text(tab.title)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? Color.white : Color.primary.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(.regularMaterial)
                                    .overlay(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.24),
                                                        Color.waypointTint.opacity(0.50),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                                    )
                                    .shadow(color: Color.waypointTint.opacity(0.28), radius: 18, y: 8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.24),
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.04),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.60),
                            Color.white.opacity(0.20),
                            Color.black.opacity(0.14),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 28, y: 16)
    }
}
