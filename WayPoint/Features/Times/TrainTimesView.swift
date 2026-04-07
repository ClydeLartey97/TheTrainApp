//
//  TrainTimesView.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

struct TrainTimesView: View {
    @Binding var selectedNetwork: RailNetwork
    @Binding var departureDate: Date
    @State private var origin = "London Paddington"
    @State private var destination = "Oxford"

    private var nearbyNetworks: [RailNetwork] {
        RailNetwork.allCases
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                locationCard
                searchCard
                liveSnapshotCard
                departuresSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("One train app, wherever you are.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Waypoint adapts to your location, so the same experience can surface UK rail now and regional rail later.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active network")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(selectedNetwork.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(selectedNetwork.locationSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("Auto", systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.58), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(nearbyNetworks) { network in
                        Button {
                            selectedNetwork = network
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(network.shortLabel)
                                    .font(.subheadline.weight(.semibold))
                                Text(network.regionLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(width: 138, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(network == selectedNetwork ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.48))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(network == selectedNetwork ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Train Times & Tickets")
                    .font(.headline)

                Spacer()

                Image(systemName: "train.side.front.car")
                    .foregroundStyle(.accentColor)
            }

            RouteField(label: "From", value: $origin, symbol: "circle.fill")
            RouteField(label: "To", value: $destination, symbol: "mappin.and.ellipse")

            DatePicker("Departure", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .tint(.accentColor)

            Button {
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search Trains")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.17, green: 0.47, blue: 0.95), Color(red: 0.08, green: 0.72, blue: 0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .glassCard()
    }

    private var liveSnapshotCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Live network status")
                    .font(.headline)

                Text("Most Great Western Railway services are running on time. One delay affecting Reading-bound trains.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("92%")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)

                Text("On time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassCard()
    }

    private var departuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sample departures")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(selectedNetwork.sampleTrips) { trip in
                TripCard(trip: trip)
            }
        }
    }
}

#Preview {
    TrainTimesView(
        selectedNetwork: .constant(.ukNationalRail),
        departureDate: .constant(.now)
    )
}
