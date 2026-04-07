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
        HStack(spacing: 14) {
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
                    .foregroundStyle(selectedTab == tab ? Color.white : Color.primary.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(selectedTab == tab ? Color.accentColor : Color.white.opacity(0.2))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 20, y: 12)
    }
}
