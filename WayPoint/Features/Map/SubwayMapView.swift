//
//  SubwayMapView.swift
//  WayPoint
//
//  Created by Codex on 22/04/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct SubwayMapView: View {
    @Binding var selectedNetwork: RailNetwork
    @State private var selectedSystem: MetroSystem
    @State private var mapPosition: MapCameraPosition
    @State private var networkSnapshot: MetroNetworkSnapshot?
    @State private var isLoadingNetwork = false
    @State private var networkError: String?
    @State private var liveStatuses: [MetroLineLiveStatus] = []
    @State private var arrivals: [MetroArrivalPrediction] = []
    @State private var isRefreshing = false
    @State private var liveError: String?
    @State private var selectedLineID: String?
    @State private var isMapExpanded = false
    @State private var locationManager = LocationManager()
    @State private var fromQuery = ""
    @State private var toQuery = ""
    @State private var fromPlace: MetroJourneyPlace?
    @State private var toPlace: MetroJourneyPlace?
    @State private var fromSuggestions: [MetroJourneySuggestion] = []
    @State private var toSuggestions: [MetroJourneySuggestion] = []
    @State private var fromSearchTask: Task<Void, Never>?
    @State private var toSearchTask: Task<Void, Never>?
    @State private var didManuallySetFrom = false
    @FocusState private var focusedJourneyField: JourneyField?
    @Environment(\.openURL) private var openURL

    init(selectedNetwork: Binding<RailNetwork>) {
        let initialSystem = MetroSystem.preferred(for: selectedNetwork.wrappedValue)
        _selectedNetwork = selectedNetwork
        _selectedSystem = State(initialValue: initialSystem)
        _mapPosition = State(initialValue: .region(initialSystem.defaultRegion))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                systemPicker

                if selectedSystem.isMapReady {
                    routePlanner
                    metroMapCard
                    linesSection
                    nextArrivalsSection
                } else {
                    comingSoonCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
        .background { WaypointGradient() }
        .sheet(isPresented: $isMapExpanded) {
            expandedMapSheet
        }
        .onAppear {
            configureDefaults()
            locationManager.requestOnce()
        }
        .task(id: selectedSystem.id) {
            configureDefaults()
            await loadNetwork()
            await refreshLiveData()
        }
        .onChange(of: selectedNetwork) { _, newValue in
            setSystem(MetroSystem.preferred(for: newValue))
        }
        .onChange(of: locationManager.locationRevision) { _, _ in
            applyCurrentLocationIfAvailable()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedSystem.localModeName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("\(selectedSystem.displayName) / \(selectedSystem.cityName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var systemPicker: some View {
        Menu {
            ForEach(MetroSystem.allCases) { system in
                Button {
                    setSystem(system)
                } label: {
                    Label(system.displayName, systemImage: system == selectedSystem ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "tram.fill")
                    .font(.headline)
                    .foregroundStyle(Color.waypointTint)
                    .frame(width: 42, height: 42)
                    .background(Color.waypointTint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedSystem.displayName)
                        .font(.headline)
                    Text(systemDataStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private var routePlanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("Select journey")
                    .font(.headline)

                Spacer()

                Button {
                    useCurrentLocation()
                } label: {
                    Label("Use current location", systemImage: "location.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.waypointTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(Color.waypointTint)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                journeySearchField(
                    title: "From",
                    field: .from,
                    icon: "location.fill",
                    color: Color.waypointTint,
                    place: fromPlace,
                    suggestions: fromSuggestions
                )

                Button {
                    swapJourneyEndpoints()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 34)
                        .background(Color.primary.opacity(0.07), in: Circle())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                journeySearchField(
                    title: "To",
                    field: .to,
                    icon: "mappin.circle.fill",
                    color: Color.statusSevereDelay,
                    place: toPlace,
                    suggestions: toSuggestions
                )
            }

            if let journeyPlan {
                journeyPlanCard(journeyPlan)
            } else if fromPlace != nil && toPlace != nil {
                Label("No mapped route found for those points.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassCard()
    }

    private func journeySearchField(
        title: String,
        field: JourneyField,
        icon: String,
        color: Color,
        place: MetroJourneyPlace?,
        suggestions: [MetroJourneySuggestion]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.14), in: Circle())
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Search station or place", text: journeyQueryBinding(for: field))
                        .font(.subheadline.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($focusedJourneyField, equals: field)
                        .onSubmit {
                            selectTopSuggestion(for: field)
                        }
                }

                if place != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.statusOnTime)
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if focusedJourneyField == field && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        Button {
                            selectSuggestion(suggestion, for: field)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: suggestion.icon)
                                    .font(.caption.weight(.bold))
                                    .frame(width: 28, height: 28)
                                    .background(Color.primary.opacity(0.07), in: Circle())
                                    .foregroundStyle(suggestion.tint)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if suggestion.id != suggestions.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func journeyPlanCard(_ plan: MetroJourneyPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best route")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(plan.totalMinutes) min")
                        .font(.title2.weight(.bold))
                    Text("\(plan.fromPlace.name) to \(plan.toPlace.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(plan.summary)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.waypointTint.opacity(0.14), in: Capsule())
                    .foregroundStyle(Color.waypointTint)
            }

            ForEach(journeySteps(for: plan)) { step in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(step.color)
                        .frame(width: 7, height: 42)

                    Image(systemName: step.icon)
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                        .background(step.color.opacity(0.13), in: Circle())
                        .foregroundStyle(step.color)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var metroMapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network map")
                        .font(.headline)
                    Text(mapCoverageLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isMapExpanded = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.bold))
                        .frame(width: 34, height: 34)
                        .background(Color.primary.opacity(0.07), in: Circle())
                        .foregroundStyle(Color.waypointTint)
                }
                .buttonStyle(.plain)
            }

            if isLoadingNetwork {
                ProgressView("Loading official TfL network")
                    .font(.caption)
            } else if let networkError {
                Label(networkError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            mapPreview
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onTapGesture {
                    isMapExpanded = true
                }
        }
        .padding(20)
        .glassCard()
    }

    private var mapPreview: some View {
        Map(position: $mapPosition, bounds: mapCameraBounds) {
            subwayMapContent(allowsStationSelection: false)
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .allowsHitTesting(false)
    }

    private var expandedMapSheet: some View {
        NavigationStack {
            MapReader { mapProxy in
                Map(position: $mapPosition, bounds: mapCameraBounds) {
                    subwayMapContent(allowsStationSelection: true)
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coordinate = mapProxy.convert(value.location, from: .local) else { return }
                            setDestinationFromMap(coordinate)
                        }
                )
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Network map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isMapExpanded = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    @MapContentBuilder
    private func subwayMapContent(allowsStationSelection: Bool) -> some MapContent {
        ForEach(activeLines.filter { $0.coordinates.count > 1 }) { line in
            MapPolyline(coordinates: line.coordinates)
                .stroke(line.color.opacity(0.72), lineWidth: 5)
        }

        if let journeyPlan {
            ForEach(routeSegments(for: journeyPlan)) { segment in
                MapPolyline(coordinates: segment.coordinates)
                    .stroke(segment.color, lineWidth: 9)
            }
        }

        ForEach(activeStations) { station in
            Annotation(station.name, coordinate: station.coordinate, anchor: .center) {
                Button {
                    if allowsStationSelection {
                        setDestination(to: station)
                    }
                } label: {
                    StationMarker(colors: stationColors(for: station), isSelected: station.id == journeyPlan?.egressStation.id)
                }
                .buttonStyle(.plain)
                .disabled(!allowsStationSelection)
            }
        }

        if let fromPlace {
            Annotation(fromPlace.name, coordinate: fromPlace.coordinate, anchor: .bottom) {
                RouteEndpointMarker(icon: "location.fill", color: Color.waypointTint)
            }
        }

        if let toPlace {
            Annotation(toPlace.name, coordinate: toPlace.coordinate, anchor: .bottom) {
                RouteEndpointMarker(icon: "mappin.circle.fill", color: Color.statusSevereDelay)
            }
        }
    }

    private var linesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Lines")
                    .font(.headline)

                Spacer()

                Button {
                    Task { await refreshLiveData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.waypointTint)
                        .padding(10)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }

            if isRefreshing && lineStatusRows.isEmpty {
                ProgressView("Loading official live feed")
                    .font(.caption)
            }

            ForEach(lineStatusRows) { row in
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            selectedLineID = selectedLineID == row.id ? nil : row.id
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(row.line.color)
                                .frame(width: 13, height: 13)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.line.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(row.displayReason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text(row.statusText)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(row.statusColor.opacity(0.14), in: Capsule())
                                .foregroundStyle(row.statusColor)

                            Image(systemName: selectedLineID == row.id ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if selectedLineID == row.id {
                        LineStopsView(line: row.line)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let liveError {
                Label(liveError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nextArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Next trains")
                .font(.headline)

            if arrivals.isEmpty {
                Label("Arrival predictions will appear once the official feed responds.", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(arrivals) { arrival in
                    HStack(spacing: 12) {
                        Text("\(arrival.minutesAway)")
                            .font(.title3.weight(.bold))
                            .frame(width: 42, height: 42)
                            .background(lineColor(forLineID: arrival.lineName, lineName: arrival.lineName).opacity(0.16), in: Circle())
                            .foregroundStyle(lineColor(forLineID: arrival.lineName, lineName: arrival.lineName))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(arrival.destinationName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(arrival.lineName) / \(arrival.stationName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("min")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "tram")
                    .font(.title2)
                    .foregroundStyle(Color.waypointTint)
                    .frame(width: 52, height: 52)
                    .background(Color.waypointTint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedSystem.displayName) coming soon")
                        .font(.headline)
                    Text("Official live API not connected yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("WayPoint will only show live closures, arrivals, and disruptions here after the relevant official feed is connected for \(selectedSystem.cityName).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let url = selectedSystem.bookingURL {
                Button {
                    openURL(url)
                } label: {
                    Label("Open official transport site", systemImage: "safari.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.waypointTint.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Color.waypointTint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard()
    }

    private var journeyPlan: MetroJourneyPlan? {
        guard let fromPlace, let toPlace else { return nil }
        guard let accessStation = station(for: fromPlace.stationID) ?? nearestStation(to: fromPlace.coordinate),
              let egressStation = station(for: toPlace.stationID) ?? nearestStation(to: toPlace.coordinate) else {
            return nil
        }

        if accessStation.id == egressStation.id {
            let directWalk = distance(from: fromPlace.coordinate, to: toPlace.coordinate)
            return MetroJourneyPlan(
                fromPlace: fromPlace,
                toPlace: toPlace,
                accessStation: accessStation,
                egressStation: egressStation,
                subwayPlan: nil,
                accessWalkDistance: directWalk,
                egressWalkDistance: 0,
                totalMinutes: walkingMinutes(for: directWalk)
            )
        }

        guard let subwayPlan = MetroRoutePlanner.fastestRoute(lines: activeLines, from: accessStation, to: egressStation) else {
            return nil
        }

        let accessWalk = distance(from: fromPlace.coordinate, to: accessStation.coordinate)
        let egressWalk = distance(from: egressStation.coordinate, to: toPlace.coordinate)
        return MetroJourneyPlan(
            fromPlace: fromPlace,
            toPlace: toPlace,
            accessStation: accessStation,
            egressStation: egressStation,
            subwayPlan: subwayPlan,
            accessWalkDistance: accessWalk,
            egressWalkDistance: egressWalk,
            totalMinutes: walkingMinutes(for: accessWalk) + subwayPlan.minutes + walkingMinutes(for: egressWalk)
        )
    }

    private var lineStatusRows: [MetroLineStatusRow] {
        legendLines.map { line in
            let statuses = liveStatuses.filter { statusMatchesLine($0, line: line) }
            return MetroLineStatusRow(line: line, statuses: statuses, isRefreshing: isRefreshing)
        }
    }

    private func journeySteps(for plan: MetroJourneyPlan) -> [MetroJourneyStep] {
        var steps: [MetroJourneyStep] = []

        if plan.subwayPlan == nil {
            steps.append(
                MetroJourneyStep(
                    color: Color.waypointTeal,
                    icon: "figure.walk",
                    title: "Walk to destination",
                    detail: "\(walkingMinutes(for: plan.accessWalkDistance)) min / \(formattedDistance(plan.accessWalkDistance))"
                )
            )
            return steps
        }

        if plan.accessWalkDistance > 35 {
            steps.append(
                MetroJourneyStep(
                    color: Color.waypointTeal,
                    icon: "figure.walk",
                    title: "Walk to \(plan.accessStation.name)",
                    detail: "\(walkingMinutes(for: plan.accessWalkDistance)) min / \(formattedDistance(plan.accessWalkDistance))"
                )
            )
        }

        for subwayStep in plan.subwayPlan?.steps ?? [] {
            steps.append(
                MetroJourneyStep(
                    color: subwayStep.color,
                    icon: "tram.fill",
                    title: subwayStep.lineName,
                    detail: "\(subwayStep.fromName) to \(subwayStep.toName) / \(subwayStep.stopCount) stop\(subwayStep.stopCount == 1 ? "" : "s")"
                )
            )
        }

        if plan.egressWalkDistance > 35 {
            steps.append(
                MetroJourneyStep(
                    color: Color.waypointTeal,
                    icon: "figure.walk",
                    title: "Walk to \(plan.toPlace.name)",
                    detail: "\(walkingMinutes(for: plan.egressWalkDistance)) min / \(formattedDistance(plan.egressWalkDistance))"
                )
            )
        }

        return steps
    }

    private func routeSegments(for plan: MetroJourneyPlan) -> [MetroRouteSegment] {
        guard let subwayPlan = plan.subwayPlan else { return [] }

        return subwayPlan.steps.compactMap { step in
            guard let line = activeLines.first(where: { $0.name == step.lineName }),
                  let fromIndex = line.stationNames.firstIndex(of: step.fromName),
                  let toIndex = line.stationNames.firstIndex(of: step.toName) else {
                return nil
            }

            let stationNames: [String]
            if fromIndex <= toIndex {
                stationNames = Array(line.stationNames[fromIndex...toIndex])
            } else {
                stationNames = Array(line.stationNames[toIndex...fromIndex].reversed())
            }

            let coordinates = stationNames.compactMap { station(named: $0)?.coordinate }
            guard coordinates.count > 1 else { return nil }
            return MetroRouteSegment(color: step.color, coordinates: coordinates)
        }
    }

    private func journeyQueryBinding(for field: JourneyField) -> Binding<String> {
        Binding {
            field == .from ? fromQuery : toQuery
        } set: { newValue in
            if field == .from {
                fromQuery = newValue
                fromPlace = nil
                didManuallySetFrom = true
            } else {
                toQuery = newValue
                toPlace = nil
            }
            updateSuggestions(for: field, query: newValue)
        }
    }

    private func updateSuggestions(for field: JourneyField, query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            setSuggestions([], for: field)
            searchTask(for: field)?.cancel()
            return
        }

        let stationMatches = stationSuggestions(matching: trimmedQuery)
        setSuggestions(stationMatches, for: field)

        searchTask(for: field)?.cancel()
        let system = selectedSystem
        let existingSuggestions = stationMatches

        let task = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmedQuery
            request.region = system.defaultRegion
            request.resultTypes = [.address, .pointOfInterest]

            let response = try? await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }

            let mapSuggestions = response?.mapItems.compactMap { mapItem -> MetroJourneySuggestion? in
                let coordinate = mapItem.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                let name = mapItem.name ?? trimmedQuery
                let subtitle = mapItem.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
                    ?? mapItem.addressRepresentations?.cityWithContext(.short)
                    ?? system.cityName
                return MetroJourneySuggestion(
                    id: "place-\(name)-\(coordinate.latitude)-\(coordinate.longitude)",
                    name: name,
                    subtitle: subtitle,
                    coordinate: coordinate,
                    stationID: nil,
                    icon: "mappin.circle.fill",
                    tint: Color.statusSevereDelay
                )
            } ?? []

            let merged = deduplicatedSuggestions(existingSuggestions + mapSuggestions).prefix(6)
            await MainActor.run {
                guard focusedJourneyField == field else { return }
                setSuggestions(Array(merged), for: field)
            }
        }

        setSearchTask(task, for: field)
    }

    private func selectSuggestion(_ suggestion: MetroJourneySuggestion, for field: JourneyField) {
        let place = MetroJourneyPlace(
            id: suggestion.id,
            name: suggestion.name,
            detail: suggestion.subtitle,
            coordinate: suggestion.coordinate,
            stationID: suggestion.stationID
        )

        if field == .from {
            fromPlace = place
            fromQuery = suggestion.name
            fromSuggestions = []
            didManuallySetFrom = true
        } else {
            toPlace = place
            toQuery = suggestion.name
            toSuggestions = []
        }

        focusedJourneyField = nil
        focusMap(on: suggestion.coordinate)
    }

    private func selectTopSuggestion(for field: JourneyField) {
        let suggestions = field == .from ? fromSuggestions : toSuggestions
        guard let first = suggestions.first else { return }
        selectSuggestion(first, for: field)
    }

    private func stationSuggestions(matching query: String) -> [MetroJourneySuggestion] {
        let normalizedQuery = normalized(query)
        return activeStations
            .filter { normalized($0.name).contains(normalizedQuery) }
            .prefix(5)
            .map { station in
                MetroJourneySuggestion(
                    id: "station-\(station.id)",
                    name: station.name,
                    subtitle: lineNames(for: station).joined(separator: ", "),
                    coordinate: station.coordinate,
                    stationID: station.id,
                    icon: "tram.fill",
                    tint: stationColors(for: station).first ?? Color.waypointTint
                )
            }
    }

    private func useCurrentLocation() {
        didManuallySetFrom = false
        locationManager.requestOnce()
        applyCurrentLocationIfAvailable(force: true)
    }

    private func applyCurrentLocationIfAvailable(force: Bool = false) {
        guard force || !didManuallySetFrom else { return }
        guard let coordinate = locationManager.currentCoordinate,
              let nearestStation = nearestStation(to: coordinate) else {
            return
        }

        fromPlace = MetroJourneyPlace(
            id: "current-location",
            name: "Current location",
            detail: "Nearest \(nearestStation.name)",
            coordinate: coordinate,
            stationID: nil
        )
        fromQuery = "Current location"
        fromSuggestions = []
    }

    private func swapJourneyEndpoints() {
        let oldFromPlace = fromPlace
        let oldFromQuery = fromQuery
        fromPlace = toPlace
        fromQuery = toQuery
        toPlace = oldFromPlace
        toQuery = oldFromQuery
        didManuallySetFrom = true
    }

    private func setDestination(to station: MetroStation) {
        let suggestion = MetroJourneySuggestion(
            id: "station-\(station.id)",
            name: station.name,
            subtitle: lineNames(for: station).joined(separator: ", "),
            coordinate: station.coordinate,
            stationID: station.id,
            icon: "tram.fill",
            tint: stationColors(for: station).first ?? Color.waypointTint
        )
        selectSuggestion(suggestion, for: .to)
    }

    private func setDestinationFromMap(_ coordinate: CLLocationCoordinate2D) {
        guard let nearestStation = nearestStation(to: coordinate) else { return }
        let name = "Dropped pin"
        toPlace = MetroJourneyPlace(
            id: "pin-\(coordinate.latitude)-\(coordinate.longitude)",
            name: name,
            detail: "Nearest \(nearestStation.name)",
            coordinate: coordinate,
            stationID: nil
        )
        toQuery = "\(name) near \(nearestStation.name)"
        toSuggestions = []
        focusedJourneyField = nil
    }

    private func setSystem(_ system: MetroSystem) {
        fromSearchTask?.cancel()
        toSearchTask?.cancel()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            selectedSystem = system
            mapPosition = .region(system.defaultRegion)
            networkSnapshot = nil
            networkError = nil
            liveStatuses = []
            arrivals = []
            liveError = nil
            selectedLineID = nil
            fromPlace = nil
            toPlace = nil
            fromQuery = ""
            toQuery = ""
            fromSuggestions = []
            toSuggestions = []
            didManuallySetFrom = false
            configureDefaults()
        }
    }

    private func configureDefaults() {
        guard !activeStations.isEmpty else {
            fromPlace = nil
            toPlace = nil
            return
        }

        applyCurrentLocationIfAvailable()

        if fromPlace == nil {
            let station = activeStations.first
            fromPlace = station.map { place(for: $0) }
            fromQuery = station?.name ?? ""
        }

        if toPlace == nil || toPlace?.stationID == fromPlace?.stationID {
            let station = activeStations.dropFirst(3).first ?? activeStations.last
            toPlace = station.map { place(for: $0) }
            toQuery = station?.name ?? ""
        }
    }

    @MainActor
    private func loadNetwork() async {
        guard selectedSystem.isMapReady else {
            networkSnapshot = nil
            networkError = nil
            return
        }

        isLoadingNetwork = selectedSystem == .londonUnderground
        networkError = nil
        defer { isLoadingNetwork = false }

        do {
            networkSnapshot = try await MetroNetworkService.shared.fetchNetwork(for: selectedSystem)
            configureDefaults()
        } catch {
            networkSnapshot = nil
            networkError = "Using fallback map while the official network feed is unavailable."
        }
    }

    @MainActor
    private func refreshLiveData() async {
        guard selectedSystem.isLiveAPIReady else {
            liveStatuses = []
            arrivals = []
            liveError = "Official live feed integration queued for \(selectedSystem.displayName)."
            return
        }

        isRefreshing = true
        liveError = nil
        defer { isRefreshing = false }

        do {
            async let fetchedStatuses = MetroLiveService.shared.fetchLineStatuses(for: selectedSystem)
            async let fetchedArrivals = MetroLiveService.shared.fetchArrivals(for: selectedSystem)
            liveStatuses = try await fetchedStatuses
            arrivals = try await fetchedArrivals
        } catch {
            liveStatuses = []
            arrivals = []
            liveError = error.localizedDescription
        }
    }

    private func focusMap(on coordinate: CLLocationCoordinate2D) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: selectedSystem.defaultRegion.span.latitudeDelta * 0.42, longitudeDelta: selectedSystem.defaultRegion.span.longitudeDelta * 0.42)
                )
            )
        }
    }

    private func place(for station: MetroStation) -> MetroJourneyPlace {
        MetroJourneyPlace(
            id: "station-\(station.id)",
            name: station.name,
            detail: lineNames(for: station).joined(separator: ", "),
            coordinate: station.coordinate,
            stationID: station.id
        )
    }

    private func lineColor(forLineID lineID: String, lineName: String) -> Color {
        activeLines.first { line in
            normalized(line.id).contains(normalized(lineID)) ||
                normalized(line.name).contains(normalized(lineName)) ||
                normalized(lineName).contains(normalized(line.name))
        }?.color ?? Color.waypointTint
    }

    private func stationColors(for station: MetroStation) -> [Color] {
        let colors = station.lineIDs.compactMap { lineID in
            activeLines.first { normalized($0.id).contains(normalized(lineID)) || normalized(lineID).contains(normalized($0.id)) }?.color
        }

        if colors.isEmpty {
            return [Color.waypointTint]
        }

        return Array(colors.prefix(3))
    }

    private func lineNames(for station: MetroStation) -> [String] {
        station.lineIDs.compactMap { lineID in
            activeLines.first { normalized($0.id).contains(normalized(lineID)) || normalized(lineID).contains(normalized($0.id)) }?.name
        }
    }

    private func station(for id: String?) -> MetroStation? {
        guard let id else { return nil }
        return activeStations.first { $0.id == id }
    }

    private func station(named name: String) -> MetroStation? {
        activeStations.first { $0.name == name }
    }

    private func nearestStation(to coordinate: CLLocationCoordinate2D) -> MetroStation? {
        activeStations.min { lhs, rhs in
            distance(from: lhs.coordinate, to: coordinate) < distance(from: rhs.coordinate, to: coordinate)
        }
    }

    private func distance(from lhs: CLLocationCoordinate2D, to rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }

    private func walkingMinutes(for distance: CLLocationDistance) -> Int {
        if distance <= 35 { return 0 }
        return max(1, Int(ceil(distance / 80.0)))
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return "\(Int(distance.rounded())) m"
    }

    private func statusMatchesLine(_ status: MetroLineLiveStatus, line: MetroLine) -> Bool {
        let statusID = normalized(status.lineID)
        let statusName = normalized(status.lineName)
        let lineID = normalized(line.id)
        let lineName = normalized(line.name)

        return lineID.contains(statusID) ||
            statusID.contains(lineID) ||
            lineName.contains(statusName) ||
            statusName.contains(lineName)
    }

    private func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func setSuggestions(_ suggestions: [MetroJourneySuggestion], for field: JourneyField) {
        if field == .from {
            fromSuggestions = suggestions
        } else {
            toSuggestions = suggestions
        }
    }

    private func searchTask(for field: JourneyField) -> Task<Void, Never>? {
        field == .from ? fromSearchTask : toSearchTask
    }

    private func setSearchTask(_ task: Task<Void, Never>, for field: JourneyField) {
        if field == .from {
            fromSearchTask = task
        } else {
            toSearchTask = task
        }
    }

    private func deduplicatedSuggestions(_ suggestions: [MetroJourneySuggestion]) -> [MetroJourneySuggestion] {
        var seen: Set<String> = []
        return suggestions.filter { suggestion in
            let key = normalized(suggestion.name) + "-\(Int(suggestion.coordinate.latitude * 1000))-\(Int(suggestion.coordinate.longitude * 1000))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private var systemDataStatus: String {
        if selectedSystem.isLiveAPIReady {
            return selectedSystem == .londonUnderground ? "Official TfL map + live API" : "Official MTA live feed"
        }
        if selectedSystem.isMapReady {
            return "Map ready / official live API coming soon"
        }
        return "Official API integration coming soon"
    }

    private var activeStations: [MetroStation] {
        networkSnapshot?.stations ?? selectedSystem.stations
    }

    private var activeLines: [MetroLine] {
        networkSnapshot?.lines ?? selectedSystem.lines
    }

    private var legendLines: [MetroLine] {
        var merged: [String: MetroLine] = [:]
        var order: [String] = []

        for line in activeLines {
            let key = normalized(line.name)
            if let existing = merged[key] {
                let stationNames = existing.stationNames + line.stationNames.filter { !existing.stationNames.contains($0) }
                let coordinates = existing.coordinates + line.coordinates
                merged[key] = MetroLine(
                    id: existing.id,
                    name: existing.name,
                    color: existing.color,
                    stationNames: stationNames,
                    coordinates: coordinates
                )
            } else {
                merged[key] = line
                order.append(key)
            }
        }

        return order.compactMap { merged[$0] }
    }

    private var mapCoverageLabel: String {
        if networkSnapshot?.isOfficial == true {
            return "Official TfL network / \(activeStations.count) stations"
        }
        if selectedSystem == .nycSubway {
            return "NYC Subway preview map / official MTA live feed"
        }
        return "\(selectedSystem.displayName) / fallback map"
    }

    private var mapCameraBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: mapBoundsRect,
            minimumDistance: 350,
            maximumDistance: selectedSystem == .londonUnderground ? 90000 : 65000
        )
    }

    private var mapBoundsRect: MKMapRect {
        let coordinates = activeStations.map(\.coordinate)
        guard !coordinates.isEmpty else {
            return MKMapRect(region: selectedSystem.defaultRegion)
        }

        let points = coordinates.map(MKMapPoint.init)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        let width = max(maxX - minX, 1200)
        let height = max(maxY - minY, 1200)
        let paddingX = width * 0.35
        let paddingY = height * 0.35

        return MKMapRect(
            x: minX - paddingX,
            y: minY - paddingY,
            width: width + paddingX * 2,
            height: height + paddingY * 2
        )
    }
}

private enum JourneyField: Hashable {
    case from
    case to
}

private struct MetroJourneyPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let coordinate: CLLocationCoordinate2D
    let stationID: String?

    static func == (lhs: MetroJourneyPlace, rhs: MetroJourneyPlace) -> Bool {
        lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude &&
            lhs.stationID == rhs.stationID
    }
}

private struct MetroJourneySuggestion: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let stationID: String?
    let icon: String
    let tint: Color
}

private struct MetroJourneyPlan: Identifiable {
    let id = UUID()
    let fromPlace: MetroJourneyPlace
    let toPlace: MetroJourneyPlace
    let accessStation: MetroStation
    let egressStation: MetroStation
    let subwayPlan: MetroRoutePlan?
    let accessWalkDistance: CLLocationDistance
    let egressWalkDistance: CLLocationDistance
    let totalMinutes: Int

    var summary: String {
        if subwayPlan == nil {
            return "Walk"
        }

        let transfers = max(0, (subwayPlan?.steps.count ?? 1) - 1)
        if transfers == 0 {
            return "Direct"
        }
        return "\(transfers) transfer\(transfers == 1 ? "" : "s")"
    }
}

private struct MetroJourneyStep: Identifiable {
    let id = UUID()
    let color: Color
    let icon: String
    let title: String
    let detail: String
}

private struct MetroRouteSegment: Identifiable {
    let id = UUID()
    let color: Color
    let coordinates: [CLLocationCoordinate2D]
}

private struct MetroLineStatusRow: Identifiable {
    let line: MetroLine
    let statuses: [MetroLineLiveStatus]
    let isRefreshing: Bool

    var id: String { line.id }

    var status: TrainStatus {
        if statuses.contains(where: { $0.status == .severeDelay }) {
            return .severeDelay
        }
        if statuses.contains(where: { $0.status == .minorDelay }) {
            return .minorDelay
        }
        return statuses.isEmpty ? .onTime : .onTime
    }

    var statusText: String {
        if statuses.isEmpty {
            return isRefreshing ? "Checking" : "Status unknown"
        }

        if status == .severeDelay {
            return statuses.first(where: { $0.status == .severeDelay })?.statusText ?? "Severe delay"
        }
        if status == .minorDelay {
            return statuses.first(where: { $0.status == .minorDelay })?.statusText ?? "Minor delay"
        }
        return "Good Service"
    }

    var displayReason: String {
        if statuses.isEmpty {
            return "\(line.stationNames.count) mapped stops"
        }

        return statuses.first { status in
            status.displayReason != status.statusText
        }?.displayReason ?? "\(line.stationNames.count) mapped stops"
    }

    var statusColor: Color {
        status.color
    }
}

private struct StationMarker: View {
    let colors: [Color]
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: isSelected ? 20 : 16, height: isSelected ? 20 : 16)
                .shadow(color: .black.opacity(0.16), radius: 3, y: 1)

            if colors.count == 1 {
                Circle()
                    .fill(colors[0])
                    .frame(width: isSelected ? 12 : 9, height: isSelected ? 12 : 9)
            } else {
                HStack(spacing: 1) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                        Capsule()
                            .fill(color)
                            .frame(width: isSelected ? 4 : 3, height: isSelected ? 12 : 9)
                    }
                }
            }
        }
        .overlay {
            Circle()
                .stroke(isSelected ? Color.statusSevereDelay : Color.primary.opacity(0.55), lineWidth: isSelected ? 3 : 1.5)
        }
    }
}

private struct RouteEndpointMarker: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: Circle())
            .shadow(color: .black.opacity(0.24), radius: 6, y: 3)
    }
}

private struct LineStopsView: View {
    let line: MetroLine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(line.stationNames.enumerated()), id: \.offset) { index, stationName in
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(line.color)
                            .frame(width: 9, height: 9)

                        if index < line.stationNames.count - 1 {
                            Rectangle()
                                .fill(line.color.opacity(0.45))
                                .frame(width: 2, height: 24)
                        }
                    }
                    .frame(width: 12)

                    Text(stationName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, index < line.stationNames.count - 1 ? 12 : 0)

                    Spacer()
                }
            }
        }
        .padding(.leading, 2)
    }
}

private extension MKMapRect {
    init(region: MKCoordinateRegion) {
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        let pointA = MKMapPoint(topLeft)
        let pointB = MKMapPoint(bottomRight)
        self.init(
            x: min(pointA.x, pointB.x),
            y: min(pointA.y, pointB.y),
            width: abs(pointA.x - pointB.x),
            height: abs(pointA.y - pointB.y)
        )
    }
}

#Preview {
    SubwayMapView(selectedNetwork: .constant(.ukNationalRail))
}
