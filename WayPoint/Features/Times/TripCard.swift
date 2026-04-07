//
//  TripCard.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct TripCard: View {
    let trip: RailTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(trip.departureTime) → \(trip.arrivalTime)")
                        .font(.headline)

                    Text("\(trip.origin) to \(trip.destination)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(trip.price)
                        .font(.title3.weight(.bold))

                    Text(trip.changeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label(trip.operatorName, systemImage: "tram.fill")
                Spacer()
                Text(trip.duration)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                } label: {
                    Text("View service")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                } label: {
                    Text("Buy ticket")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard()
    }
}

#Preview {
    TripCard(trip: RailNetwork.ukNationalRail.sampleTrips[0])
}
