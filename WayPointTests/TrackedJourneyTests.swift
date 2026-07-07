//
//  TrackedJourneyTests.swift
//  WayPointTests
//
//  Created on 07/07/2026.
//

import Foundation
import Testing
@testable import WayPoint

struct TrackedJourneyTests {
    private func makeTrip(departure: String = "10:00", arrival: String = "11:00") -> RailTrip {
        RailTrip(
            origin: "London Euston",
            destination: "Manchester Piccadilly",
            departureTime: departure,
            arrivalTime: arrival,
            duration: "1 hr 0 min",
            operatorName: "Avanti West Coast",
            changeSummary: "Direct",
            price: nil,
            platform: "3",
            status: "On time",
            serviceId: "abc123",
            callingPoints: [
                CallingPoint(stationName: "London Euston", crs: "EUS", scheduledTime: departure, estimatedTime: "On time", actualTime: nil)
            ]
        )
    }

    @Test func initCapturesTripFields() {
        let journey = TrackedJourney(trip: makeTrip(), serviceId: "abc123")
        #expect(journey.serviceId == "abc123")
        #expect(journey.originCRS == "EUS")
        #expect(journey.platform == "3")
        #expect(journey.notifiedPlatform == "3")
        #expect(journey.notifiedCancellation == false)
    }

    @Test func resolveTimeInFutureStaysToday() {
        let calendar = Calendar.current
        let reference = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let resolved = TrackedJourney.resolve(time: "10:30", near: reference)
        #expect(resolved != nil)
        #expect(calendar.isDate(resolved!, inSameDayAs: reference))
        #expect(calendar.component(.hour, from: resolved!) == 10)
    }

    @Test func resolveTimeWellInPastRollsToTomorrow() {
        let calendar = Calendar.current
        let reference = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: .now)!
        let resolved = TrackedJourney.resolve(time: "00:15", near: reference)!
        #expect(resolved > reference)
    }

    @Test func arrivalAfterMidnightComesAfterDeparture() {
        let trip = makeTrip(departure: "23:40", arrival: "00:20")
        let journey = TrackedJourney(trip: trip, serviceId: "abc123")
        guard let departure = journey.departureDate, let arrival = journey.arrivalDate else {
            Issue.record("expected resolvable dates")
            return
        }
        #expect(arrival > departure)
        #expect(arrival.timeIntervalSince(departure) == 40 * 60)
    }

    @Test func expiresWellAfterArrival() {
        let journey = TrackedJourney(trip: makeTrip(), serviceId: "abc123")
        guard let arrival = journey.arrivalDate else {
            Issue.record("expected arrival date")
            return
        }
        #expect(journey.isExpired(at: arrival) == false)
        #expect(journey.isExpired(at: arrival.addingTimeInterval(31 * 60)) == true)
    }

    @Test func roundTripsThroughJSON() throws {
        let journey = TrackedJourney(trip: makeTrip(), serviceId: "abc123")
        let data = try JSONEncoder().encode(journey)
        let decoded = try JSONDecoder().decode(TrackedJourney.self, from: data)
        #expect(decoded == journey)
    }
}
