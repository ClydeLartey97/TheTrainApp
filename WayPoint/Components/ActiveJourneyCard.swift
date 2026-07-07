//
//  ActiveJourneyCard.swift
//  WayPoint
//
//  Created on 07/07/2026.
//

import SwiftUI

/// The pinned card for the journey the user is tracking (Phase 4).
struct ActiveJourneyCard: View {
    @Environment(JourneyTracker.self) private var tracker

    var body: some View {
        if let journey = tracker.journey {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Tracking", systemImage: "location.fill.viewfinder")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.waypointTint)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            tracker.stopTracking()
                        }
                    } label: {
                        Label("Stop", systemImage: "xmark")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(journey.scheduledDeparture) → \(journey.scheduledArrival)")
                            .font(.headline)
                            .strikethrough(journey.isCancelled, color: .statusSevereDelay)

                        Text("\(journey.originName) to \(journey.destinationName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(journey.operatorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(journey.platform.map { "Platform \($0)" } ?? "Platform pending")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(journey.platform == nil ? Color.secondary : Color.waypointTint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            (journey.platform == nil ? Color.primary.opacity(0.06) : Color.waypointTint.opacity(0.14)),
                            in: Capsule()
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(TripStatus(journey.status).color)
                            .frame(width: 8, height: 8)
                        Text(journey.status)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TripStatus(journey.status).color)

                        Spacer()

                        if tracker.isRefreshing {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Button {
                                Task { await tracker.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2.weight(.bold))
                                    .frame(width: 28, height: 28)
                                    .background(Color.primary.opacity(0.06), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.waypointTint)
                        }
                    }

                    if let reason = journey.disruptionReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(updateFooter(for: journey))
                        .font(.caption2)
                        .foregroundStyle(journey.lastUpdateFailed ? Color.statusMinorDelay : .secondary)
                }

                if tracker.notificationsDenied {
                    Label("Notifications are off — enable them in Settings to get cancellation and platform alerts.", systemImage: "bell.slash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .glassCard()
        }
    }

    private func updateFooter(for journey: TrackedJourney) -> String {
        let time = journey.lastUpdatedAt.formatted(date: .omitted, time: .shortened)
        if journey.lastUpdateFailed {
            return "Last update failed — showing details from \(time). Retrying automatically."
        }
        return "Updated \(time) · National Rail via Huxley2 · auto-refreshes every minute"
    }
}
