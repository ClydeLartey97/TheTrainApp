//
//  LiveDataSnapshot.swift
//  WayPoint
//
//  Created on 03/07/2026.
//

import Foundation

/// Freshness and provenance metadata attached to every live data surface.
nonisolated struct LiveDataSnapshot: Equatable {
    let sourceName: String
    let sourceURL: URL?
    let fetchedAt: Date
    /// How long the data is considered fresh before surfaces should flag it as stale.
    let timeToLive: TimeInterval
    /// True when the data did not come from the live provider (cache, sample, or previous fetch kept after an error).
    let isFallback: Bool

    init(
        sourceName: String,
        sourceURL: URL? = nil,
        fetchedAt: Date = .now,
        timeToLive: TimeInterval = 120,
        isFallback: Bool = false
    ) {
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.fetchedAt = fetchedAt
        self.timeToLive = timeToLive
        self.isFallback = isFallback
    }

    var expiresAt: Date {
        fetchedAt.addingTimeInterval(timeToLive)
    }

    func isStale(at date: Date = .now) -> Bool {
        date >= expiresAt
    }

    func updatedText(at date: Date = .now) -> String {
        let elapsed = date.timeIntervalSince(fetchedAt)
        if elapsed < 60 {
            return "Updated just now"
        }
        return "Updated \(fetchedAt.formatted(date: .omitted, time: .shortened))"
    }

    /// The same snapshot re-labeled as fallback, used when an error keeps previous results on screen.
    func asFallback() -> LiveDataSnapshot {
        LiveDataSnapshot(
            sourceName: sourceName,
            sourceURL: sourceURL,
            fetchedAt: fetchedAt,
            timeToLive: timeToLive,
            isFallback: true
        )
    }
}

/// A departure board result paired with its freshness metadata.
nonisolated struct DepartureBoardSnapshot {
    let trips: [RailTrip]
    let metadata: LiveDataSnapshot
}
