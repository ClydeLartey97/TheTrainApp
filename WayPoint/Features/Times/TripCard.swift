//
//  TripCard.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct TripCard: View {
    let trip: RailTrip
    var onViewService: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("\(trip.departureTime) → \(trip.arrivalTime)")
                            .font(.headline)

                        if trip.isCancelled {
                            Text("CANCELLED")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.statusSevereDelay, in: Capsule())
                        }
                    }

                    Text("\(trip.origin) to \(trip.destination)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    if let price = trip.price {
                        Text(price)
                            .font(.title3.weight(.bold))
                    }

                    Text(trip.changeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label(trip.operatorName, systemImage: "tram.fill")

                Spacer()

                if let platform = trip.platform {
                    Label("Plat. \(platform)", systemImage: "rectangle.split.3x1")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.waypointTint)
                }

                if !trip.duration.isEmpty {
                    Text(trip.duration)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

            if let status = trip.status {
                HStack(spacing: 6) {
                    Circle()
                        .fill(trip.tripStatus.color)
                        .frame(width: 8, height: 8)
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trip.tripStatus.color)

                    if let reason = trip.delayReason ?? trip.cancelReason {
                        Text("— \(reason)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    onViewService?()
                } label: {
                    Text("View service")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Service Detail Sheet

struct ServiceDetailSheet: View {
    let trip: RailTrip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Route header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(trip.origin) → \(trip.destination)")
                            .font(.title3.weight(.bold))

                        HStack(spacing: 14) {
                            Label(trip.departureTime, systemImage: "clock")
                            if !trip.duration.isEmpty {
                                Label(trip.duration, systemImage: "hourglass")
                            }
                            if let platform = trip.platform {
                                Label("Platform \(platform)", systemImage: "rectangle.split.3x1")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    // Status
                    if let status = trip.status {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(trip.tripStatus.color)
                                .frame(width: 10, height: 10)
                            Text(status)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(trip.tripStatus.color)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(trip.tripStatus.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Delay / cancel reason
                    if let reason = trip.cancelReason ?? trip.delayReason {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.statusMinorDelay)
                            Text(reason)
                                .font(.subheadline)
                        }
                    }

                    // Operator
                    HStack(spacing: 10) {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(Color.waypointTint)
                        Text(trip.operatorName)
                            .font(.subheadline.weight(.medium))
                    }

                    // Calling points
                    if !trip.callingPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Calling points")
                                .font(.headline)
                                .padding(.bottom, 12)

                            ForEach(Array(trip.callingPoints.enumerated()), id: \.element.id) { index, point in
                                HStack(alignment: .top, spacing: 14) {
                                    VStack(spacing: 0) {
                                        Circle()
                                            .fill(point.isOnTime ? Color.waypointTint : Color.statusMinorDelay)
                                            .frame(width: 10, height: 10)

                                        if index < trip.callingPoints.count - 1 {
                                            Rectangle()
                                                .fill(Color.waypointTint.opacity(0.3))
                                                .frame(width: 2)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(point.stationName)
                                                .font(.subheadline.weight(.medium))

                                            Spacer()

                                            Text(point.displayTime)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(point.isOnTime ? .primary : Color.statusMinorDelay)
                                        }

                                        if !point.isOnTime, let est = point.estimatedTime {
                                            Text("Expected \(est)")
                                                .font(.caption)
                                                .foregroundStyle(Color.statusMinorDelay)
                                        }

                                        Text(point.crs)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calling points")
                                .font(.headline)
                            Text("Detailed calling point data is not available for this service.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let price = trip.price {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Indicative fare")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(price)
                                    .font(.title2.weight(.bold))
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.waypointTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Service details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

}

#Preview {
    TripCard(trip: RailNetwork.ukNationalRail.sampleTrips[0])
}
