//
//  TrackedJourney.swift
//  WayPoint
//
//  Created on 07/07/2026.
//

import Foundation

/// A single service the user is actively monitoring (Phase 4).
/// The notified* fields persist which alerts have already fired so a
/// relaunch never re-notifies the same change.
nonisolated struct TrackedJourney: Codable, Equatable {
    let serviceId: String
    let originName: String
    let originCRS: String
    let destinationName: String
    /// Scheduled departure "HH:mm" at the origin the board was fetched for.
    let scheduledDeparture: String
    let scheduledArrival: String
    let operatorName: String
    let trackedAt: Date

    var platform: String?
    var status: String
    var isCancelled: Bool
    var disruptionReason: String?
    var lastUpdatedAt: Date
    var lastUpdateFailed: Bool

    var notifiedCancellation: Bool
    var notifiedPlatform: String?
    var notifiedDelayedStatus: String?

    init(trip: RailTrip, serviceId: String) {
        self.serviceId = serviceId
        self.originName = trip.origin
        self.originCRS = trip.callingPoints.first?.crs ?? ""
        self.destinationName = trip.destination
        self.scheduledDeparture = trip.departureTime
        self.scheduledArrival = trip.arrivalTime
        self.operatorName = trip.operatorName
        self.trackedAt = .now
        self.platform = trip.platform
        self.status = trip.status ?? "On time"
        self.isCancelled = trip.isCancelled
        self.disruptionReason = trip.cancelReason ?? trip.delayReason
        self.lastUpdatedAt = .now
        self.lastUpdateFailed = false
        self.notifiedCancellation = trip.isCancelled
        self.notifiedPlatform = trip.platform
        self.notifiedDelayedStatus = nil
    }

    var routeTitle: String {
        "\(scheduledDeparture) \(originName) → \(destinationName)"
    }

    /// The scheduled departure resolved against the day tracking started,
    /// rolling to the next day for journeys that cross midnight.
    var departureDate: Date? {
        Self.resolve(time: scheduledDeparture, near: trackedAt)
    }

    var arrivalDate: Date? {
        guard let departure = departureDate,
              let departureMinutes = RailTrip.minutes(from: scheduledDeparture),
              let arrivalMinutes = RailTrip.minutes(from: scheduledArrival) else { return nil }
        var delta = arrivalMinutes - departureMinutes
        if delta < 0 { delta += 24 * 60 }
        return departure.addingTimeInterval(TimeInterval(delta * 60))
    }

    /// Tracking stops being useful well after the scheduled arrival has passed.
    func isExpired(at date: Date = .now) -> Bool {
        guard let arrival = arrivalDate else {
            return date.timeIntervalSince(trackedAt) > 12 * 3600
        }
        return date > arrival.addingTimeInterval(30 * 60)
    }

    /// Turns an "HH:mm" string into a concrete date near a reference day.
    /// Times more than 3 hours in the past are assumed to be tomorrow.
    static func resolve(time: String, near reference: Date) -> Date? {
        guard let minutes = RailTrip.minutes(from: time) else { return nil }
        let calendar = Calendar.current
        guard let candidate = calendar.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: reference
        ) else { return nil }

        if candidate < reference.addingTimeInterval(-3 * 3600) {
            return calendar.date(byAdding: .day, value: 1, to: candidate)
        }
        return candidate
    }
}
