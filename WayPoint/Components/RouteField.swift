//
//  RouteField.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct RouteField: View {
    let label: String
    @Binding var value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(.accentColor)

                TextField("", text: $value)
                    .textInputAutocapitalization(.words)
            }
            .padding(14)
            .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
