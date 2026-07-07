//
//  RouteStoreTests.swift
//  WayPointTests
//
//  Created on 07/07/2026.
//

import Foundation
import Testing
@testable import WayPoint

struct RouteStoreTests {
    private func makeStore() -> (RouteStore, UserDefaults) {
        let suite = "waypoint.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (RouteStore(defaults: defaults), defaults)
    }

    private var selection: RouteStationSelection {
        RouteStationSelection(
            origin: Station(name: "London Euston", crs: "EUS"),
            destination: Station(name: "Manchester Piccadilly", crs: "MAN")
        )
    }

    @Test func recordSearchAppearsInRecents() {
        let (store, _) = makeStore()
        store.recordSearch(selection, network: .ukNationalRail)
        #expect(store.recentRoutes(for: .ukNationalRail).count == 1)
        #expect(store.recentRoutes(for: .ukNationalRail).first?.originCode == "EUS")
    }

    @Test func favoritesPersistAcrossStoreInstances() {
        let (store, defaults) = makeStore()
        store.saveFavorite(selection, network: .ukNationalRail)

        let reloaded = RouteStore(defaults: defaults)
        #expect(reloaded.favoriteRoutes(for: .ukNationalRail).count == 1)
    }

    @Test func favoriteHidesMatchingRecent() {
        let (store, _) = makeStore()
        store.recordSearch(selection, network: .ukNationalRail)
        store.saveFavorite(selection, network: .ukNationalRail)
        #expect(store.recentRoutes(for: .ukNationalRail).isEmpty)
        #expect(store.favoriteRoutes(for: .ukNationalRail).count == 1)
    }

    @Test func removeFavoriteDeletesIt() {
        let (store, _) = makeStore()
        let route = store.saveFavorite(selection, network: .ukNationalRail)
        store.removeFavorite(route)
        #expect(store.favoriteRoutes(for: .ukNationalRail).isEmpty)
    }

    @Test func recentsCapAtEight() {
        let (store, _) = makeStore()
        for i in 0..<12 {
            let sel = RouteStationSelection(
                origin: Station(name: "Origin \(i)", crs: "O\(i)"),
                destination: nil
            )
            store.recordSearch(sel, network: .ukNationalRail)
        }
        #expect(store.recentRoutes(for: .ukNationalRail).count == 8)
    }

    @Test func routesAreScopedToNetwork() {
        let (store, _) = makeStore()
        store.recordSearch(selection, network: .ukNationalRail)
        #expect(store.recentRoutes(for: .amtrak).isEmpty)
    }

    @Test func reversedRouteSwapsStations() {
        let route = SavedRoute(
            origin: Station(name: "London Euston", crs: "EUS"),
            destination: Station(name: "Manchester Piccadilly", crs: "MAN"),
            network: .ukNationalRail
        )
        let reversed = route.reversedForSearch()
        #expect(reversed?.originCode == "MAN")
        #expect(reversed?.destinationCode == "EUS")
    }

    @Test func destinationlessRouteCannotReverse() {
        let route = SavedRoute(
            origin: Station(name: "London Euston", crs: "EUS"),
            destination: nil,
            network: .ukNationalRail
        )
        #expect(route.canReverse == false)
        #expect(route.reversedForSearch() == nil)
    }
}
