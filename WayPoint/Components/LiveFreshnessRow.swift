//
//  LiveFreshnessRow.swift
//  WayPoint
//
//  Created on 03/07/2026.
//

import SwiftUI

/// Shows when live data was fetched, where it came from, and whether it has gone stale,
/// with a refresh affordance. Used by every live surface (Phase 2 trust layer).
struct LiveFreshnessRow: View {
    let metadata: LiveDataSnapshot
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let isStale = metadata.isStale(at: context.date) || metadata.isFallback

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: isStale ? "clock.badge.exclamationmark" : "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isStale ? Color.statusMinorDelay : Color.statusOnTime)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(metadata.updatedText(at: context.date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isStale ? Color.statusMinorDelay : .primary)
                        Text(metadata.sourceName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.bold))
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.waypointTint)
                    .disabled(isRefreshing)
                }

                if isStale {
                    Text(metadata.isFallback
                        ? "Showing the last successful results — the live feed could not be reached. Refresh to try again."
                        : "This data may be out of date. Refresh for the latest.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                (isStale ? Color.statusMinorDelay.opacity(0.10) : Color.primary.opacity(0.045)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
    }
}
