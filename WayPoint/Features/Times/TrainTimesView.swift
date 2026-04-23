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
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                networkCard
                if selectedNetwork.hasLiveDepartures {
                    searchCard
                    resultsSection
                    if viewModel.hasSearched {
                        liveSnapshotCard
                    }
                } else {
                    comingSoonCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
        .background { WaypointGradient() }
        .onChange(of: selectedNetwork) { _, _ in
            viewModel.reset()
            departureDate = viewModel.departureDate
        }
        .sheet(isPresented: $viewModel.isShowingServiceDetail) {
            if let trip = viewModel.selectedTrip {
                ServiceDetailSheet(trip: trip)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("One train app,\nwherever you are.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("WayPoint keeps train times familiar as you move between rail networks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Network Card

    private var networkCard: some View {
        Menu {
            ForEach(RailNetwork.allCases) { network in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedNetwork = network
                    }
                } label: {
                    Label(
                        network.displayName,
                        systemImage: network == selectedNetwork ? "checkmark.circle.fill" : "circle"
                    )
                }
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.waypointTint.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: "train.side.front.car")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.waypointTint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(selectedNetwork.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if selectedNetwork.hasLiveDepartures {
                            Text("LIVE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.statusOnTime, in: Capsule())
                        }
                    }

                    Text(selectedNetwork.locationSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(9)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .padding(18)
            .glassCard()
        }
    }

    // MARK: - Search Card (UK Rail only)

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Train Times")
                    .font(.headline)
                Spacer()
                Label("Live", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.statusOnTime)
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
                        .padding(9)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.vertical, -8)

            RouteField(
                label: "To (optional)",
                value: $viewModel.destination,
                symbol: "mappin.and.ellipse",
                suggestions: viewModel.destinationSuggestions,
                isShowingSuggestions: viewModel.isShowingDestinationSuggestions,
                onTextChange: { viewModel.updateDestinationSuggestions() },
                onSelect: { viewModel.selectDestination($0) }
            )

            // Date & time picker
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.subheadline)
                    .foregroundStyle(Color.waypointTint)

                Text("Departing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                DatePicker(
                    "Departing",
                    selection: $departureDate,
                    in: startOfToday...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.waypointTint)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                viewModel.isShowingOriginSuggestions = false
                viewModel.isShowingDestinationSuggestions = false
                viewModel.departureDate = departureDate
                Task { await viewModel.searchDepartures() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSearching {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(viewModel.isSearching ? "Searching…" : "Search Trains")
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
        .onAppear {
            viewModel.departureDate = departureDate
        }
        .onChange(of: departureDate) { _, newValue in
            viewModel.departureDate = newValue
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Departures")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.searchResults.count) found")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.searchResults) { trip in
                    TripCard(trip: trip) {
                        viewModel.showServiceDetail(for: trip)
                    }
                }
            }
        }
    }

    // MARK: - Live Snapshot

    private var liveSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Journey snapshot")
                    .font(.headline)
                Spacer()
                if !viewModel.searchResults.isEmpty {
                    Text("\(snapshotOnTimePct)% on time")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(snapshotOnTimePct >= 80 ? Color.statusOnTime : Color.statusMinorDelay)
                }
            }

            Text(snapshotSummaryText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    private var snapshotOnTimePct: Int {
        let total = viewModel.searchResults.count
        guard total > 0 else { return 0 }
        let onTime = viewModel.searchResults.filter { $0.status == "On time" }.count
        return Int(Double(onTime) / Double(total) * 100)
    }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private var snapshotSummaryText: String {
        let results = viewModel.searchResults
        guard !results.isEmpty else {
            return "No services matched your search."
        }
        let operators = Array(Set(results.map { $0.operatorName }))
        let label = operators.count == 1 ? operators[0] : selectedNetwork.displayName
        let cancelled = results.filter { $0.isCancelled }.count
        let delayed = results.filter {
            guard let s = $0.status else { return false }
            return s == "Delayed" || s.hasPrefix("Exp.")
        }.count
        if cancelled > 0 {
            return "\(label): \(cancelled) cancellation\(cancelled == 1 ? "" : "s") and \(delayed) delay\(delayed == 1 ? "" : "s") in current results."
        }
        if delayed > 0 {
            return "\(label): \(delayed) delayed service\(delayed == 1 ? "" : "s") in current results."
        }
        return "All \(results.count) \(label) services shown are currently running on time."
    }

    // MARK: - Coming Soon (non-UK networks)

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.waypointTint.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(Color.waypointTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedNetwork.displayName) — Coming Soon")
                        .font(.headline)
                    Text("Live departures not yet integrated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(selectedNetwork.displayName) live departures are on the roadmap. Official ticket purchase links are available while search and fares are connected market by market.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let bookingURL = selectedNetwork.bookingURL {
                Button {
                    openURL(bookingURL)
                } label: {
                    Label("Open official ticket site", systemImage: "ticket.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.waypointTint.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Color.waypointTint)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Live UK departures via National Rail", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.statusOnTime)

                Label("Map and region explorer for all networks", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.statusOnTime)

                Label("\(selectedNetwork.displayName) live search (coming soon)", systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassCard()
    }
}

#Preview {
    TrainTimesView(
        selectedNetwork: .constant(.ukNationalRail),
        departureDate: .constant(.now)
    )
}
