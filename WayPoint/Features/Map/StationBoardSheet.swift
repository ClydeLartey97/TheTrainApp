//
//  StationBoardSheet.swift
//  WayPoint
//
//  Created on 08/07/2026.
//

import SwiftUI

/// Live departure board for a station tapped on the map. Same data path as
/// the Times tab (National Rail via Huxley2), including service details and
/// journey tracking.
struct StationBoardSheet: View {
    let station: Station

    @State private var trips: [RailTrip] = []
    @State private var metadata: LiveDataSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTrip: RailTrip?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if let metadata {
                        LiveFreshnessRow(
                            metadata: metadata,
                            isRefreshing: isLoading,
                            onRefresh: { Task { await load() } }
                        )
                    }

                    if isLoading && trips.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Fetching live departures…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let errorMessage, trips.isEmpty {
                        errorCard(errorMessage)
                    } else if trips.isEmpty {
                        emptyCard
                    } else {
                        let badges = RailTrip.badges(for: trips)
                        ForEach(trips) { trip in
                            TripCard(trip: trip, badges: badges[trip.id] ?? []) {
                                selectedTrip = trip
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background { WaypointGradient() }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedTrip) { trip in
                ServiceDetailSheet(trip: trip, metadata: metadata)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let board = try await DepartureService.shared.fetchDepartures(from: station.crs)
            trips = board.trips
            metadata = board.metadata
        } catch {
            errorMessage = error.localizedDescription
            // Keep any previous board visible but flag it as no longer live.
            if !trips.isEmpty {
                metadata = metadata?.asFallback()
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.statusMinorDelay)
            VStack(alignment: .leading, spacing: 4) {
                Text("Couldn't load departures")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var emptyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz")
                .foregroundStyle(Color.waypointTint)
            VStack(alignment: .leading, spacing: 4) {
                Text("No departures in the next two hours")
                    .font(.subheadline.weight(.semibold))
                Text("This board covers the next 120 minutes of scheduled services from \(station.name).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
