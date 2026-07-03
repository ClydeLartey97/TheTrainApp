//
//  TripRanking.swift
//  WayPoint
//
//  Created on 03/07/2026.
//

import SwiftUI

/// Deterministic, explainable tags for a departure board (Phase 3).
/// Best = arrives first. Fastest = shortest journey. Both require at least
/// two running services, otherwise the tag carries no information.
nonisolated enum TripBadge: String, Identifiable {
    case best = "Best"
    case fastest = "Fastest"
    case delayed = "Delayed"
    case cancelled = "Cancelled"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .best: "Arrives first"
        case .fastest: "Shortest journey"
        case .delayed: "Running late"
        case .cancelled: "Not running"
        }
    }
}

extension TripBadge {
    var color: Color {
        switch self {
        case .best: .statusOnTime
        case .fastest: .waypointTint
        case .delayed: .statusMinorDelay
        case .cancelled: .statusSevereDelay
        }
    }
}

nonisolated extension RailTrip {
    var isDelayed: Bool {
        guard let status else { return false }
        return status == "Delayed" || status.hasPrefix("Exp.")
    }

    /// Minutes parsed from the "1 hr 23 min" style duration string, or nil.
    var durationMinutes: Int? {
        let parts = duration.split(separator: " ").compactMap { Int($0) }
        switch parts.count {
        case 2: return parts[0] * 60 + parts[1]
        case 1: return duration.contains("hr") ? parts[0] * 60 : parts[0]
        default: return nil
        }
    }

    /// Minutes since midnight parsed from an "HH:mm" time, or nil.
    static func minutes(from time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    static func badges(for trips: [RailTrip]) -> [UUID: [TripBadge]] {
        var result: [UUID: [TripBadge]] = [:]

        for trip in trips {
            if trip.isCancelled {
                result[trip.id] = [.cancelled]
            } else if trip.isDelayed {
                result[trip.id] = [.delayed]
            }
        }

        let running = trips.filter { !$0.isCancelled }
        guard running.count >= 2 else { return result }

        // Arrival minutes are adjusted for journeys that cross midnight so an
        // 00:10 arrival after a 23:40 departure still ranks after 23:55.
        func arrivalRank(_ trip: RailTrip) -> Int? {
            guard let departure = Self.minutes(from: trip.departureTime),
                  let arrival = Self.minutes(from: trip.arrivalTime) else { return nil }
            return arrival < departure ? arrival + 24 * 60 : arrival
        }

        if let best = running.min(by: { (arrivalRank($0) ?? .max, Self.minutes(from: $0.departureTime) ?? .max)
            < (arrivalRank($1) ?? .max, Self.minutes(from: $1.departureTime) ?? .max) }),
           arrivalRank(best) != nil {
            result[best.id, default: []].insert(.best, at: 0)
        }

        if let fastest = running.min(by: { ($0.durationMinutes ?? .max, Self.minutes(from: $0.departureTime) ?? .max)
            < ($1.durationMinutes ?? .max, Self.minutes(from: $1.departureTime) ?? .max) }),
           fastest.durationMinutes != nil,
           !(result[fastest.id]?.contains(.best) ?? false) {
            result[fastest.id, default: []].insert(.fastest, at: 0)
        }

        return result
    }
}
