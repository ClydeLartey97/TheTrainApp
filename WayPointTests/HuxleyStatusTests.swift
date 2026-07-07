//
//  HuxleyStatusTests.swift
//  WayPointTests
//
//  Created on 07/07/2026.
//

import Testing
@testable import WayPoint

struct HuxleyStatusTests {
    @Test func cancelledWinsOverEverything() {
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "On time", isCancelled: true) == "Cancelled")
    }

    @Test func onTimeVariants() {
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "On time", isCancelled: false) == "On time")
        #expect(HuxleyStatus.statusText(std: "10:00", etd: nil, isCancelled: nil) == "On time")
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "", isCancelled: false) == "On time")
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "10:00", isCancelled: false) == "On time")
    }

    @Test func delayedWithoutEstimate() {
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "Delayed", isCancelled: false) == "Delayed")
    }

    @Test func estimatedTimeBecomesExpected() {
        #expect(HuxleyStatus.statusText(std: "10:00", etd: "10:12", isCancelled: false) == "Exp. 10:12")
    }

    @Test func delayMinutesFromEstimate() {
        #expect(HuxleyStatus.delayMinutes(std: "10:00", etd: "10:12") == 12)
        #expect(HuxleyStatus.delayMinutes(std: "10:00", etd: "10:00") == 0)
        #expect(HuxleyStatus.delayMinutes(std: "10:00", etd: "Delayed") == nil)
        #expect(HuxleyStatus.delayMinutes(std: nil, etd: "10:12") == nil)
    }

    @Test func delayAcrossMidnight() {
        #expect(HuxleyStatus.delayMinutes(std: "23:55", etd: "00:10") == 15)
    }
}
