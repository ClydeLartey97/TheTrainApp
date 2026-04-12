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
    var suggestions: [Station] = []
    var isShowingSuggestions: Bool = false
    var onTextChange: (() -> Void)? = nil
    var onSelect: ((Station) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .foregroundStyle(Color.waypointTint)

                    TextField("Station name", text: $value)
                        .textInputAutocapitalization(.words)
                        .onChange(of: value) {
                            onTextChange?()
                        }
                }
                .padding(14)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if isShowingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { station in
                        Button {
                            onSelect?(station)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "train.side.front.car")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(station.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Text(station.crs)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if station.id != suggestions.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 6)
            }
        }
    }
}
