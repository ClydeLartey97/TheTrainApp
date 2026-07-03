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
    @State private var routeStore = RouteStore()
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                networkCard
                if selectedNetwork.hasLiveDepartures {
                    commuterBoard
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
        .refreshable {
            guard viewModel.hasSearched else { return }
            await viewModel.searchDepartures()
        }
        .onAppear { runDebugAutosearchIfNeeded() }
        .onChange(of: selectedNetwork) { _, _ in
            viewModel.reset()
            departureDate = viewModel.departureDate
        }
        .sheet(isPresented: $viewModel.isShowingServiceDetail) {
            if let trip = viewModel.selectedTrip {
                ServiceDetailSheet(trip: trip, metadata: viewModel.boardMetadata)
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

    // MARK: - Commuter Board

    @ViewBuilder
    private var commuterBoard: some View {
        let favorites = routeStore.favoriteRoutes(for: selectedNetwork)
        let recents = routeStore.recentRoutes(for: selectedNetwork)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Commuter board")
                        .font(.headline)
                    Text(selectedNetwork.shortLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.waypointTint)
            }

            if favorites.isEmpty && recents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundStyle(Color.waypointTint)
                        .frame(width: 38, height: 38)
                        .background(Color.waypointTint.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your regular routes will live here")
                            .font(.subheadline.weight(.semibold))
                        Text("Run a search once, then save the routes you use most.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                if !favorites.isEmpty {
                    routeSection(title: "Saved", routes: favorites)
                }

                if !recents.isEmpty {
                    routeSection(title: "Recent", routes: recents)
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    private func routeSection(title: String, routes: [SavedRoute]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(routes) { route in
                commuterRouteRow(route)
            }
        }
    }

    private func commuterRouteRow(_ route: SavedRoute) -> some View {
        let isFavorite = routeStore.isFavorite(route)

        return HStack(spacing: 12) {
            Image(systemName: isFavorite ? "star.fill" : "clock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(isFavorite ? Color.statusMinorDelay : Color.waypointTint)
                .frame(width: 30, height: 30)
                .background(Color.primary.opacity(0.06), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(route.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(route.stationCodeSummary) / \(route.lastUsedText())")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        if isFavorite {
                            routeStore.removeFavorite(route)
                        } else {
                            _ = routeStore.saveFavorite(route)
                        }
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.slash" : "star")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(isFavorite ? Color.statusMinorDelay : Color.waypointTint)

                Button {
                    runReversedRoute(route)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(route.canReverse ? Color.waypointTint : .secondary)
                .disabled(!route.canReverse)
                .opacity(route.canReverse ? 1 : 0.45)

                Button {
                    runRoute(route)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 34)
                        .background(Color.waypointTint, in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

            if let selection = viewModel.currentRouteSelection {
                currentRouteAction(selection)
            }

            Button {
                searchCurrentRoute()
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

    private func currentRouteAction(_ selection: RouteStationSelection) -> some View {
        let isFavorite = routeStore.isFavorite(selection, network: selectedNetwork)
        let actionBackground: Color = Color(.label).opacity(0.045)

        return HStack(spacing: 10) {
            Label(
                isFavorite ? "Saved route" : "Known route",
                systemImage: isFavorite ? "star.fill" : "checkmark.circle.fill"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(isFavorite ? Color.statusMinorDelay : Color.statusOnTime)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    _ = routeStore.saveFavorite(selection, network: selectedNetwork)
                }
            } label: {
                Label(isFavorite ? "Saved" : "Save", systemImage: isFavorite ? "star.fill" : "star")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? Color.statusMinorDelay : Color.waypointTint)
            .disabled(isFavorite)
        }
        .padding(12)
        .background(actionBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func searchCurrentRoute() {
        viewModel.isShowingOriginSuggestions = false
        viewModel.isShowingDestinationSuggestions = false
        viewModel.departureDate = departureDate

        Task {
            await viewModel.searchDepartures()
            if let selection = viewModel.lastCompletedRouteSelection {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    routeStore.recordSearch(selection, network: selectedNetwork)
                }
            }
        }
    }

    private func runRoute(_ route: SavedRoute) {
        departureDate = .now
        viewModel.departureDate = departureDate
        viewModel.applyRoute(route)
        routeStore.touch(route)
        searchCurrentRoute()
    }

    /// Launch-environment hook so automated simulator runs can exercise the
    /// full search flow (DEBUG only): WAYPOINT_DEBUG_AUTOSEARCH = "EUS>MAN" or "EUS".
    private func runDebugAutosearchIfNeeded() {
        #if DEBUG
        guard let spec = ProcessInfo.processInfo.environment["WAYPOINT_DEBUG_AUTOSEARCH"],
              !spec.isEmpty, !viewModel.hasSearched else { return }

        let codes = spec.split(separator: ">").map { String($0).uppercased() }
        guard let originCode = codes.first,
              let origin = StationRepository.shared.resolveStation(query: originCode) else { return }
        let destination = codes.dropFirst().first.flatMap {
            StationRepository.shared.resolveStation(query: $0)
        }

        viewModel.applyRoute(
            SavedRoute(origin: origin, destination: destination, network: selectedNetwork)
        )
        searchCurrentRoute()
        #endif
    }

    private func runReversedRoute(_ route: SavedRoute) {
        guard let reversedRoute = route.reversedForSearch() else { return }
        departureDate = .now
        viewModel.departureDate = departureDate
        viewModel.applyRoute(reversedRoute)
        searchCurrentRoute()
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            let badges = RailTrip.badges(for: viewModel.searchResults)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Departures")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.searchResults.count) found")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let metadata = viewModel.boardMetadata {
                    LiveFreshnessRow(
                        metadata: metadata,
                        isRefreshing: viewModel.isSearching,
                        onRefresh: { searchCurrentRoute() }
                    )
                }

                ForEach(viewModel.searchResults) { trip in
                    TripCard(trip: trip, badges: badges[trip.id] ?? []) {
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
