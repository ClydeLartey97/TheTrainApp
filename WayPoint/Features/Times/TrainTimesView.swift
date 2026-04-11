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
    @State private var viewModel = SearchViewModel()

    private var nearbyNetworks: [RailNetwork] {
        RailNetwork.allCases
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                locationCard
                searchCard
                resultsSection
                liveSnapshotCard
                if viewModel.searchResults.isEmpty {
                    sampleDeparturesSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $viewModel.isShowingServiceDetail) {
            if let trip = viewModel.selectedTrip {
                ServiceDetailSheet(trip: trip)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("One train app, wherever you are.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("WayPoint keeps train times familiar as you move between rail networks.")
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedNetwork = network
                            }
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
                                    .fill(network == selectedNetwork ? Color.waypointTint.opacity(0.22) : Color.white.opacity(0.48))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(network == selectedNetwork ? Color.waypointTint.opacity(0.45) : Color.white.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Train Times")
                    .font(.headline)

                Spacer()

                if selectedNetwork == .ukNationalRail {
                    Label("Live", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.statusOnTime)
                } else {
                    Image(systemName: "train.side.front.car")
                        .foregroundStyle(Color.waypointTint)
                }
            }

            RouteField(
                label: "From",
                value: $viewModel.origin,
                symbol: "circle.fill",
                suggestions: viewModel.originSuggestions,
                isShowingSuggestions: viewModel.isShowingOriginSuggestions,
                onTextChange: { viewModel.updateOriginSuggestions() },
                onSelect: { viewModel.selectOrigin($0) }
            )

            // Swap button
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.swapStations()
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.waypointTint)
                        .padding(8)
                        .background(Color.white.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.vertical, -8)

            RouteField(
                label: "To",
                value: $viewModel.destination,
                symbol: "mappin.and.ellipse",
                suggestions: viewModel.destinationSuggestions,
                isShowingSuggestions: viewModel.isShowingDestinationSuggestions,
                onTextChange: { viewModel.updateDestinationSuggestions() },
                onSelect: { viewModel.selectDestination($0) }
            )

            if selectedNetwork == .ukNationalRail {
                Button {
                    viewModel.isShowingOriginSuggestions = false
                    viewModel.isShowingDestinationSuggestions = false
                    Task {
                        await viewModel.searchDepartures()
                    }
                } label: {
                    HStack {
                        if viewModel.isSearching {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(viewModel.isSearching ? "Searching..." : "Search Trains")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.waypointTint, Color.waypointTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSearching)
            } else {
                Text("Live departures are only available for UK Rail. Showing sample data below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusMinorDelay)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.statusMinorDelay.opacity(0.12))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Live departures")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(viewModel.searchResults.count) found")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                ForEach(viewModel.searchResults) { trip in
                    TripCard(trip: trip) {
                        viewModel.showServiceDetail(for: trip)
                    }
                }
            }
        }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    private var sampleDeparturesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sample departures")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(selectedNetwork.sampleTrips) { trip in
                TripCard(trip: trip) {
                    viewModel.showServiceDetail(for: trip)
                }
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
