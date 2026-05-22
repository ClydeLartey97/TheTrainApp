//
//  RouteStore.swift
//  WayPoint
//
//  Created on 22/05/2026.
//

import Foundation
import Observation

@Observable
final class RouteStore {
    private enum StorageKey {
        static let favorites = "waypoint.savedRoutes.favorites"
        static let recents = "waypoint.savedRoutes.recents"
    }

    private let defaults: UserDefaults
    private let maxRecents = 8

    private(set) var savedRoutes: [SavedRoute] = []
    private(set) var recentRoutes: [SavedRoute] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        savedRoutes = Self.loadRoutes(forKey: StorageKey.favorites, defaults: defaults)
        recentRoutes = Self.loadRoutes(forKey: StorageKey.recents, defaults: defaults)
    }

    func favoriteRoutes(for network: RailNetwork) -> [SavedRoute] {
        savedRoutes
            .filter { $0.networkID == network.rawValue }
            .sorted { $0.lastUsedAt > $1.lastUsedAt }
    }

    func recentRoutes(for network: RailNetwork) -> [SavedRoute] {
        let favoriteIDs = Set(savedRoutes.map(\.id))
        return recentRoutes
            .filter { $0.networkID == network.rawValue && !favoriteIDs.contains($0.id) }
            .sorted { $0.lastUsedAt > $1.lastUsedAt }
    }

    func recordSearch(_ selection: RouteStationSelection, network: RailNetwork) {
        var route = SavedRoute(
            origin: selection.origin,
            destination: selection.destination,
            network: network,
            isFavorite: false,
            lastUsedAt: .now
        )

        if let existing = recentRoutes.first(where: { $0.id == route.id }) {
            route.createdAt = existing.createdAt
        }

        if let favoriteIndex = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            savedRoutes[favoriteIndex].lastUsedAt = .now
            persistFavorites()
        }

        recentRoutes.removeAll { $0.id == route.id }
        recentRoutes.insert(route, at: 0)
        recentRoutes = Array(recentRoutes.prefix(maxRecents))
        persistRecents()
    }

    @discardableResult
    func saveFavorite(_ selection: RouteStationSelection, network: RailNetwork) -> SavedRoute {
        saveFavorite(
            SavedRoute(
                origin: selection.origin,
                destination: selection.destination,
                network: network,
                isFavorite: true,
                lastUsedAt: .now
            )
        )
    }

    @discardableResult
    func saveFavorite(_ route: SavedRoute) -> SavedRoute {
        var favorite = route
        favorite.isFavorite = true
        favorite.lastUsedAt = .now

        if let index = savedRoutes.firstIndex(where: { $0.id == favorite.id }) {
            favorite.createdAt = savedRoutes[index].createdAt
            savedRoutes[index] = favorite
        } else {
            savedRoutes.insert(favorite, at: 0)
        }

        persistFavorites()
        return favorite
    }

    func removeFavorite(_ route: SavedRoute) {
        savedRoutes.removeAll { $0.id == route.id }
        persistFavorites()
    }

    func touch(_ route: SavedRoute) {
        if let index = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            savedRoutes[index].lastUsedAt = .now
            persistFavorites()
        }

        if let index = recentRoutes.firstIndex(where: { $0.id == route.id }) {
            recentRoutes[index].lastUsedAt = .now
            persistRecents()
        }
    }

    func isFavorite(_ route: SavedRoute) -> Bool {
        savedRoutes.contains { $0.id == route.id }
    }

    func isFavorite(_ selection: RouteStationSelection, network: RailNetwork) -> Bool {
        let id = SavedRoute.routeID(
            networkID: network.rawValue,
            originCode: selection.origin.crs,
            destinationCode: selection.destination?.crs
        )
        return savedRoutes.contains { $0.id == id }
    }

    private func persistFavorites() {
        Self.saveRoutes(savedRoutes, forKey: StorageKey.favorites, defaults: defaults)
    }

    private func persistRecents() {
        Self.saveRoutes(recentRoutes, forKey: StorageKey.recents, defaults: defaults)
    }

    private static func loadRoutes(forKey key: String, defaults: UserDefaults) -> [SavedRoute] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SavedRoute].self, from: data)) ?? []
    }

    private static func saveRoutes(_ routes: [SavedRoute], forKey key: String, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(routes) else { return }
        defaults.set(data, forKey: key)
    }
}
