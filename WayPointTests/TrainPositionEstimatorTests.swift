//
//  TrainPositionEstimatorTests.swift
//  WayPointTests
//
//  Created on 08/07/2026.
//

import CoreLocation
import Foundation
import Testing
@testable import WayPoint

struct TrainPositionEstimatorTests {
    // A three-stop line laid out on a simple grid: A (0,0) → B (1,0) → C (2,0).
    private let coordinates: [String: CLLocationCoordinate2D] = [
        "AAA": CLLocationCoordinate2D(latitude: 0, longitude: 0),
        "BBB": CLLocationCoordinate2D(latitude: 1, longitude: 0),
        "CCC": CLLocationCoordinate2D(latitude: 2, longitude: 0),
    ]

    private func point(
        _ crs: String, scheduled: String, estimated: String? = nil, actual: String? = nil
    ) -> CallingPoint {
        CallingPoint(
            stationName: crs, crs: crs,
            scheduledTime: scheduled, estimatedTime: estimated, actualTime: actual
        )
    }

    /// 10:00 on the anchor day.
    private func time(_ hhmm: String, anchor: Date) -> Date {
        let minutes = RailTrip.minutes(from: hhmm)!
        return Calendar.current.date(
            bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: anchor
        )!
    }

    private var anchor: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now)!
    }

    private func estimate(_ points: [CallingPoint], at now: Date) -> TrainMapPosition? {
        TrainPositionEstimator.estimate(
            callingPoints: points,
            anchoredNear: anchor,
            at: now,
            coordinateFor: { coordinates[$0] }
        )
    }

    @Test func waitingAtOriginBeforeDeparture() {
        let points = [point("AAA", scheduled: "10:00"), point("BBB", scheduled: "10:30")]
        let result = estimate(points, at: time("09:45", anchor: anchor))
        #expect(result?.statusLine == "Waiting to depart AAA")
        #expect(result?.coordinate.latitude == 0)
    }

    @Test func midwayInterpolation() {
        let points = [point("AAA", scheduled: "10:00"), point("BBB", scheduled: "10:30")]
        let result = estimate(points, at: time("10:15", anchor: anchor))
        #expect(result?.statusLine == "Between AAA and BBB")
        #expect(abs((result?.coordinate.latitude ?? 0) - 0.5) < 0.001)
    }

    @Test func arrivedAtDestinationAfterLastStop() {
        let points = [point("AAA", scheduled: "10:00"), point("BBB", scheduled: "10:30")]
        let result = estimate(points, at: time("10:45", anchor: anchor))
        #expect(result?.statusLine == "Arrived at BBB")
        #expect(result?.coordinate.latitude == 1)
    }

    @Test func liveEstimateBeatsSchedule() {
        // Scheduled 10:30 at B but running 20 late (est 10:50): at 10:40 the
        // train should still be short of B, not past it.
        let points = [
            point("AAA", scheduled: "10:00", actual: "10:00"),
            point("BBB", scheduled: "10:30", estimated: "10:50"),
        ]
        let result = estimate(points, at: time("10:40", anchor: anchor))
        #expect(result?.statusLine == "Between AAA and BBB")
        #expect((result?.coordinate.latitude ?? 1) < 0.9)
    }

    @Test func nonTimeStringsFallBackToSchedule() {
        let points = [
            point("AAA", scheduled: "10:00", estimated: "On time"),
            point("BBB", scheduled: "10:30", estimated: "Delayed"),
        ]
        let result = estimate(points, at: time("10:15", anchor: anchor))
        #expect(result?.statusLine == "Between AAA and BBB")
    }

    @Test func stopsWithoutCoordinatesAreSkipped() {
        let points = [
            point("AAA", scheduled: "10:00"),
            point("ZZZ", scheduled: "10:10"), // unknown station
            point("BBB", scheduled: "10:30"),
        ]
        let result = estimate(points, at: time("10:15", anchor: anchor))
        #expect(result != nil)
        #expect(result?.routeCoordinates.count == 2)
    }

    @Test func overnightServiceThatOriginatedYesterdayResolvesBackward() {
        // Tracked at 01:16; the service left its origin at 23:06 the previous
        // evening (real case: the 23:06 Bedford → Three Bridges at Gatwick).
        let smallHoursAnchor = Calendar.current.date(bySettingHour: 1, minute: 16, second: 0, of: .now)!
        let points = [
            point("AAA", scheduled: "23:06", actual: "On time"),
            point("BBB", scheduled: "00:45"),
            point("CCC", scheduled: "01:23"),
        ]
        let stops = TrainPositionEstimator.timedStops(
            from: points, anchoredNear: smallHoursAnchor, coordinateFor: { coordinates[$0] }
        )
        #expect(stops.count == 3)
        #expect(stops[0].date < smallHoursAnchor)
        #expect(stops[1].date > stops[0].date)
        #expect(stops[2].date > stops[1].date)

        // At 01:00 the train has passed BBB (00:45) and is heading for CCC (01:23).
        let now = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: smallHoursAnchor)!
        let result = TrainPositionEstimator.estimate(
            callingPoints: points, anchoredNear: smallHoursAnchor, at: now,
            coordinateFor: { coordinates[$0] }
        )
        #expect(result?.statusLine == "Between BBB and CCC")
    }

    @Test func consecutiveYesterdayStopsStayOnYesterday() {
        // Real regression: 23:06 and 23:18 both belong to yesterday when
        // tracked at 01:16; the second stop must not jump to today's 23:18.
        let smallHoursAnchor = Calendar.current.date(bySettingHour: 1, minute: 16, second: 0, of: .now)!
        let points = [
            point("AAA", scheduled: "23:06"),
            point("BBB", scheduled: "23:18"),
            point("CCC", scheduled: "01:23"),
        ]
        let stops = TrainPositionEstimator.timedStops(
            from: points, anchoredNear: smallHoursAnchor, coordinateFor: { coordinates[$0] }
        )
        #expect(stops.count == 3)
        #expect(stops[1].date.timeIntervalSince(stops[0].date) == 12 * 60)
        #expect(stops[1].date < smallHoursAnchor)

        // At 01:16 the train is past both evening stops, approaching CCC.
        let result = TrainPositionEstimator.estimate(
            callingPoints: points, anchoredNear: smallHoursAnchor, at: smallHoursAnchor,
            coordinateFor: { coordinates[$0] }
        )
        #expect(result?.statusLine == "Between BBB and CCC")
    }

    @Test func midnightWrapKeepsTimelineMonotonic() {
        let lateAnchor = Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: .now)!
        let points = [point("AAA", scheduled: "23:40"), point("BBB", scheduled: "00:20")]
        let stops = TrainPositionEstimator.timedStops(
            from: points, anchoredNear: lateAnchor, coordinateFor: { coordinates[$0] }
        )
        #expect(stops.count == 2)
        #expect(stops[1].date > stops[0].date)
    }

    @Test func singleUsableStopGivesNoPosition() {
        let points = [point("AAA", scheduled: "10:00")]
        #expect(estimate(points, at: time("10:15", anchor: anchor)) == nil)
    }

    @Test func effectiveTimePrefersActualThenEstimated() {
        #expect(TrainPositionEstimator.effectiveTime(
            for: point("AAA", scheduled: "10:00", estimated: "10:05", actual: "10:07")) == "10:07")
        #expect(TrainPositionEstimator.effectiveTime(
            for: point("AAA", scheduled: "10:00", estimated: "10:05")) == "10:05")
        #expect(TrainPositionEstimator.effectiveTime(
            for: point("AAA", scheduled: "10:00", estimated: "Cancelled")) == "10:00")
    }
}
