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

    func updateOriginSuggestions() {
        let results = repo.search(query: origin)
        originSuggestions = Array(results.prefix(6))
        isShowingOriginSuggestions = !originSuggestions.isEmpty && origin.count >= 2
        // Hide if the text exactly matches a station
        if repo.findStation(named: origin) != nil {
            isShowingOriginSuggestions = false
        }
    }

    func updateDestinationSuggestions() {
        let results = repo.search(query: destination)
        destinationSuggestions = Array(results.prefix(6))
        isShowingDestinationSuggestions = !destinationSuggestions.isEmpty && destination.count >= 2
        if repo.findStation(named: destination) != nil {
            isShowingDestinationSuggestions = false
        }
    }

    func selectOrigin(_ station: Station) {
        origin = station.name
        isShowingOriginSuggestions = false
    }

    func selectDestination(_ station: Station) {
        destination = station.name
        isShowingDestinationSuggestions = false
    }

    func swapStations() {
        let temp = origin
        origin = destination
        destination = temp
    }

    func searchDepartures() async {
        guard let originStation = repo.findStation(named: origin) else {
            errorMessage = "Unknown origin station: \"\(origin)\". Please select from the suggestions."
            return
        }

        let destStation = repo.findStation(named: destination)

        isSearching = true
        errorMessage = nil
        searchResults = []

        do {
            let trips = try await service.fetchDepartures(
                from: originStation.crs,
                to: destStation?.crs,
                date: departureDate
            )
            searchResults = trips
            hasSearched = true
            if trips.isEmpty {
                errorMessage = "No departures found from \(origin)"
                if let dest = destStation {
                    errorMessage! += " to \(dest.name)"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func showServiceDetail(for trip: RailTrip) {
        selectedTrip = trip
        isShowingServiceDetail = true
    }
}
