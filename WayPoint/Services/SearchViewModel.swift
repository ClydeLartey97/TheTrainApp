//
//  SearchViewModel.swift
//  WayPoint
//
//  Created by Clyde Lartey on 11/04/2026.
//

import Foundation
import Observation

@Observable
final class SearchViewModel {
    var origin = ""
    var destination = ""
    var departureDate = Date.now

    var originSuggestions: [Station] = []
    var destinationSuggestions: [Station] = []
    var isShowingOriginSuggestions = false
    var isShowingDestinationSuggestions = false

    var searchResults: [RailTrip] = []
    var isSearching = false
    var hasSearched = false
    var errorMessage: String?

    var selectedTrip: RailTrip?
    var isShowingServiceDetail = false

    private let repo = StationRepository.shared
    private let service = DepartureService.shared
    private var selectedOriginStation: Station?
    private var selectedDestinationStation: Station?
    private var originSearchTask: Task<Void, Never>?
    private var destinationSearchTask: Task<Void, Never>?

    func reset() {
        searchResults = []
        hasSearched = false
        errorMessage = nil
        origin = ""
        destination = ""
        departureDate = .now
        isShowingOriginSuggestions = false
        isShowingDestinationSuggestions = false
        isShowingServiceDetail = false
        selectedOriginStation = nil
        selectedDestinationStation = nil
        originSearchTask?.cancel()
        destinationSearchTask?.cancel()
    }

    func updateOriginSuggestions() {
        selectedOriginStation = selectedOriginStation?.matches(origin) == true ? selectedOriginStation : nil
        updateSuggestions(
            for: origin,
            currentSelection: selectedOriginStation,
            task: &originSearchTask,
            assign: { [self] suggestions, shouldShow in
                self.originSuggestions = suggestions
                self.isShowingOriginSuggestions = shouldShow
            }
        )
    }

    func updateDestinationSuggestions() {
        selectedDestinationStation = selectedDestinationStation?.matches(destination) == true ? selectedDestinationStation : nil
        updateSuggestions(
            for: destination,
            currentSelection: selectedDestinationStation,
            task: &destinationSearchTask,
            assign: { [self] suggestions, shouldShow in
                self.destinationSuggestions = suggestions
                self.isShowingDestinationSuggestions = shouldShow
            }
        )
    }

    func selectOrigin(_ station: Station) {
        originSearchTask?.cancel()
        selectedOriginStation = station
        origin = station.name
        originSuggestions = []
        isShowingOriginSuggestions = false
    }

    func selectDestination(_ station: Station) {
        destinationSearchTask?.cancel()
        selectedDestinationStation = station
        destination = station.name
        destinationSuggestions = []
        isShowingDestinationSuggestions = false
    }

    func swapStations() {
        let temp = origin
        origin = destination
        destination = temp
        let tempStation = selectedOriginStation
        selectedOriginStation = selectedDestinationStation
        selectedDestinationStation = tempStation
    }

    func searchDepartures() async {
        let trimmedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let originStation = resolvedStation(for: trimmedOrigin, selected: selectedOriginStation, suggestions: originSuggestions) else {
            errorMessage = "Unknown origin station: \"\(origin)\". Please select from the suggestions."
            return
        }

        let destStation = resolvedStation(for: trimmedDestination, selected: selectedDestinationStation, suggestions: destinationSuggestions)
        if !trimmedDestination.isEmpty && destStation == nil {
            errorMessage = "Unknown destination station: \"\(destination)\". Please select from the suggestions or leave it blank."
            return
        }

        isSearching = true
        errorMessage = nil
        searchResults = []
        defer { isSearching = false }

        do {
            let trips = try await service.fetchDepartures(
                from: originStation.crs,
                to: destStation?.crs,
                date: departureDate
            )
            searchResults = trips
            hasSearched = true
            if trips.isEmpty {
                var msg = "No departures found from \(origin)"
                if let dest = destStation { msg += " to \(dest.name)" }
                errorMessage = msg
            }
        } catch {
            errorMessage = error.localizedDescription
            hasSearched = true
        }
    }

    func showServiceDetail(for trip: RailTrip) {
        selectedTrip = trip
        isShowingServiceDetail = true
    }

    private func updateSuggestions(
        for query: String,
        currentSelection: Station?,
        task: inout Task<Void, Never>?,
        assign: @escaping ([Station], Bool) -> Void
    ) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        task?.cancel()

        guard trimmedQuery.count >= 2 else {
            assign([], false)
            return
        }

        let localResults = Array(repo.search(query: trimmedQuery).prefix(8))
        let shouldShowLocal = currentSelection == nil && !localResults.isEmpty
        assign(localResults, shouldShowLocal)

        task = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }

            let remoteResults = (try? await service.searchStations(query: trimmedQuery)) ?? []
            guard !Task.isCancelled else { return }

            await MainActor.run {
                let merged = mergeStations(localResults + remoteResults)
                let shouldShow = currentSelection == nil && !merged.isEmpty && normalized(query) == normalized(trimmedQuery)
                assign(Array(merged.prefix(8)), shouldShow)
            }
        }
    }

    private func resolvedStation(for query: String, selected: Station?, suggestions: [Station]) -> Station? {
        if let selected, selected.matches(query) {
            return selected
        }

        if let station = repo.resolveStation(query: query) {
            return station
        }

        let matchingSuggestions = suggestions.filter { $0.matches(query) }
        if matchingSuggestions.count == 1 {
            return matchingSuggestions[0]
        }

        return nil
    }

    private func mergeStations(_ stations: [Station]) -> [Station] {
        var seen: Set<String> = []
        return stations.filter { station in
            let key = station.crs.uppercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }
}

private extension Station {
    func matches(_ query: String) -> Bool {
        let normalizedQuery = query
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }

        let normalizedName = name
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }

        return normalizedName == normalizedQuery || crs.uppercased() == query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
