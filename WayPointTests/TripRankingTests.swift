//
//  TripRankingTests.swift
//  WayPointTests
//
//  Created on 07/07/2026.
//

import Testing
@testable import WayPoint

struct TripRankingTests {
    private func trip(
        departure: String,
        arrival: String,
        duration: String,
        status: String = "On time",
        cancelled: Bool = false
    ) -> RailTrip {
        RailTrip(
            origin: "A",
            destination: "B",
            departureTime: departure,
            arrivalTime: arrival,
            duration: duration,
            operatorName: "Test",
            changeSummary: "Direct",
            price: nil,
            status: status,
            isCancelled: cancelled
        )
    }

    @Test func bestGoesToEarliestArrival() {
        let early = trip(departure: "10:00", arrival: "10:50", duration: "50 min")
        let late = trip(departure: "10:10", arrival: "11:10", duration: "1 hr 0 min")
        let badges = RailTrip.badges(for: [late, early])
        #expect(badges[early.id]?.contains(.best) == true)
        #expect(badges[late.id]?.contains(.best) != true)
    }

    @Test func fastestGoesToShortestJourneyWhenDifferentFromBest() {
        let best = trip(departure: "10:00", arrival: "10:50", duration: "50 min")
        let fastest = trip(departure: "10:30", arrival: "11:00", duration: "30 min")
        let badges = RailTrip.badges(for: [best, fastest])
        #expect(badges[best.id]?.contains(.best) == true)
        #expect(badges[fastest.id]?.contains(.fastest) == true)
    }

    @Test func fastestNotDuplicatedOnBestTrip() {
        let both = trip(departure: "10:00", arrival: "10:30", duration: "30 min")
        let other = trip(departure: "10:10", arrival: "11:10", duration: "1 hr 0 min")
        let badges = RailTrip.badges(for: [both, other])
        #expect(badges[both.id]?.contains(.best) == true)
        #expect(badges[both.id]?.contains(.fastest) != true)
    }

    @Test func singleRunningServiceGetsNoRankingBadges() {
        let only = trip(departure: "10:00", arrival: "10:50", duration: "50 min")
        let cancelled = trip(departure: "10:10", arrival: "11:00", duration: "50 min", cancelled: true)
        let badges = RailTrip.badges(for: [only, cancelled])
        #expect(badges[only.id] == nil)
        #expect(badges[cancelled.id] == [.cancelled])
    }

    @Test func delayedAndCancelledBadges() {
        let delayed = trip(departure: "10:00", arrival: "10:50", duration: "50 min", status: "Exp. 10:12")
        let cancelled = trip(departure: "10:10", arrival: "11:00", duration: "50 min", status: "Cancelled", cancelled: true)
        let onTime = trip(departure: "10:20", arrival: "11:20", duration: "1 hr 0 min")
        let badges = RailTrip.badges(for: [delayed, cancelled, onTime])
        #expect(badges[delayed.id]?.contains(.delayed) == true)
        #expect(badges[cancelled.id] == [.cancelled])
    }

    @Test func overnightArrivalRanksAfterSameEveningArrival() {
        let evening = trip(departure: "23:00", arrival: "23:55", duration: "55 min")
        let overnight = trip(departure: "23:40", arrival: "00:10", duration: "30 min")
        let badges = RailTrip.badges(for: [overnight, evening])
        #expect(badges[evening.id]?.contains(.best) == true)
    }

    @Test func durationMinutesParsing() {
        #expect(trip(departure: "10:00", arrival: "11:08", duration: "1 hr 8 min").durationMinutes == 68)
        #expect(trip(departure: "10:00", arrival: "10:26", duration: "26 min").durationMinutes == 26)
        #expect(trip(departure: "10:00", arrival: "10:26", duration: "").durationMinutes == nil)
    }

    @Test func minutesFromTimeString() {
        #expect(RailTrip.minutes(from: "00:00") == 0)
        #expect(RailTrip.minutes(from: "23:59") == 1439)
        #expect(RailTrip.minutes(from: "not a time") == nil)
    }
}
