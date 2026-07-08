//
//  TrainPositionEstimator.swift
//  WayPoint
//
//  Created on 08/07/2026.
//

import CoreLocation
import Foundation

/// Where a train position came from. The map labels the marker with this so
/// an estimate is never presented as a live fix.
nonisolated enum TrainPositionSource: String, Codable {
    case liveFeed
    case estimatedFromTimings

    var label: String {
        switch self {
        case .liveFeed: "Live position"
        case .estimatedFromTimings: "Estimated position"
        }
    }
}

nonisolated struct TrainMapPosition {
    let coordinate: CLLocationCoordinate2D
    let source: TrainPositionSource
    /// Human-readable location, e.g. "Between Reading and Didcot Parkway".
    let statusLine: String
    /// Known coordinates along the service's calling points, for the route line.
    let routeCoordinates: [CLLocationCoordinate2D]
}

/// Single entry point for train positions. Tries a real vehicle feed first;
/// when the market has none (UK today), falls back to interpolating between
/// calling points using their live actual/estimated timings.
enum TrainPositionProvider {
    static func position(for journey: TrackedJourney, at now: Date = .now) -> TrainMapPosition? {
        if let live = liveVehiclePosition(for: journey, at: now) {
            return live
        }
        return TrainPositionEstimator.estimate(
            callingPoints: journey.callingPoints,
            anchoredNear: journey.trackedAt,
            at: now,
            coordinateFor: { StationRepository.shared.findStation(crs: $0)?.coordinate }
        )
    }

    /// Hook for official vehicle-position feeds. No UK feed is integrated yet;
    /// when one lands (e.g. Network Rail train movements), implement this and
    /// every surface automatically prefers it over the estimate.
    private static func liveVehiclePosition(for journey: TrackedJourney, at now: Date) -> TrainMapPosition? {
        nil
    }
}

/// Pure interpolation from calling-point timings — no networking, fully testable.
nonisolated enum TrainPositionEstimator {
    struct TimedStop {
        let name: String
        let coordinate: CLLocationCoordinate2D
        let date: Date
    }

    static func estimate(
        callingPoints: [CallingPoint],
        anchoredNear anchor: Date,
        at now: Date = .now,
        coordinateFor: (String) -> CLLocationCoordinate2D?
    ) -> TrainMapPosition? {
        let stops = timedStops(from: callingPoints, anchoredNear: anchor, coordinateFor: coordinateFor)
        guard stops.count >= 2 else { return nil }

        let route = stops.map(\.coordinate)

        if now <= stops[0].date {
            return TrainMapPosition(
                coordinate: stops[0].coordinate,
                source: .estimatedFromTimings,
                statusLine: "Waiting to depart \(stops[0].name)",
                routeCoordinates: route
            )
        }

        if let last = stops.last, now >= last.date {
            return TrainMapPosition(
                coordinate: last.coordinate,
                source: .estimatedFromTimings,
                statusLine: "Arrived at \(last.name)",
                routeCoordinates: route
            )
        }

        for index in 0..<(stops.count - 1) {
            let from = stops[index]
            let to = stops[index + 1]
            guard now >= from.date, now < to.date else { continue }

            let legDuration = to.date.timeIntervalSince(from.date)
            let progress = legDuration > 0 ? now.timeIntervalSince(from.date) / legDuration : 0

            let coordinate = CLLocationCoordinate2D(
                latitude: from.coordinate.latitude + (to.coordinate.latitude - from.coordinate.latitude) * progress,
                longitude: from.coordinate.longitude + (to.coordinate.longitude - from.coordinate.longitude) * progress
            )
            return TrainMapPosition(
                coordinate: coordinate,
                source: .estimatedFromTimings,
                statusLine: "Between \(from.name) and \(to.name)",
                routeCoordinates: route
            )
        }

        return nil
    }

    /// Calling points reduced to stops with a usable clock time and a known
    /// coordinate, with times anchored to concrete dates. Times must be
    /// monotonic; a wrap past midnight rolls to the next day.
    static func timedStops(
        from callingPoints: [CallingPoint],
        anchoredNear anchor: Date,
        coordinateFor: (String) -> CLLocationCoordinate2D?
    ) -> [TimedStop] {
        let calendar = Calendar.current
        var result: [TimedStop] = []
        var previousDate: Date?

        for point in callingPoints {
            // Each stop is anchored to the previous stop's day so an overnight
            // timeline never gains a phantom 24-hour gap.
            let reference = previousDate ?? anchor
            guard let time = effectiveTime(for: point),
                  let minutes = RailTrip.minutes(from: time),
                  let coordinate = coordinateFor(point.crs),
                  var date = calendar.date(
                      bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: reference
                  )
            else { continue }

            if let previous = previousDate {
                if date < previous {
                    date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                }
            } else {
                // Clock times carry no date. The first stop may be hours in the
                // past (a service that originated yesterday evening) or shortly
                // ahead (tracked 23:50, departs 00:10) — pick whichever day puts
                // it closest to when tracking started.
                let candidates = [-1, 0, 1].compactMap {
                    calendar.date(byAdding: .day, value: $0, to: date)
                }
                date = candidates.min {
                    abs($0.timeIntervalSince(anchor)) < abs($1.timeIntervalSince(anchor))
                } ?? date
            }

            previousDate = date
            result.append(TimedStop(name: point.stationName, coordinate: coordinate, date: date))
        }

        return result
    }

    /// Best clock time for a stop: actual beats estimated beats scheduled.
    /// Non-time strings ("On time", "Delayed", "Cancelled") are ignored.
    static func effectiveTime(for point: CallingPoint) -> String? {
        if let actual = point.actualTime, RailTrip.minutes(from: actual) != nil {
            return actual
        }
        if let estimated = point.estimatedTime, RailTrip.minutes(from: estimated) != nil {
            return estimated
        }
        return RailTrip.minutes(from: point.scheduledTime) != nil ? point.scheduledTime : nil
    }
}
