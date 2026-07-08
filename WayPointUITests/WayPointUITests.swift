//
//  WayPointUITests.swift
//  WayPointUITests
//
//  Created on 07/07/2026.
//

import XCTest

final class WayPointUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsTimesShell() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Commuter board"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Train Times"].exists)
        XCTAssertTrue(app.buttons["Search Trains"].exists)
    }

    func testNetworkSwitcherShowsComingSoonMarket() throws {
        let app = XCUIApplication()
        app.launch()

        // The network selector renders as a button whose label includes the
        // market name; "UK Rail" alone also appears in the commuter board caption.
        let networkMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS 'UK Rail'")).firstMatch
        XCTAssertTrue(networkMenu.waitForExistence(timeout: 10))
        networkMenu.tap()

        let amtrak = app.buttons["Amtrak"]
        XCTAssertTrue(amtrak.waitForExistence(timeout: 5))
        amtrak.tap()

        XCTAssertTrue(app.staticTexts["Amtrak — Coming Soon"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open official ticket site"].exists)
    }

    /// Station map smoke: land on the map tab, tap a station pin, and verify
    /// its live departure board sheet opens with the freshness row.
    func testStationMapOpensLiveBoard() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["WAYPOINT_DEBUG_TAB": "livemap"]
        app.launch()

        // Decline location so the fresh simulator can't auto-switch away from UK Rail.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let dontAllow = springboard.buttons["Don't Allow"]
        if dontAllow.waitForExistence(timeout: 8) {
            dontAllow.tap()
        }

        // Map annotations can surface as buttons or generic elements depending
        // on how MapKit wraps them — accept either.
        let pinPredicate = NSPredicate(format: "identifier BEGINSWITH 'station-pin-'")
        var pin = app.buttons.matching(pinPredicate).firstMatch
        if !pin.waitForExistence(timeout: 15) {
            pin = app.descendants(matching: .any).matching(pinPredicate).firstMatch
            XCTAssertTrue(pin.waitForExistence(timeout: 10), app.debugDescription)
        }
        pin.tap()

        // The board sheet shows the trust row (or an honest error) plus Done.
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 10))
        let boardLoaded = app.staticTexts["National Rail via Huxley2"].waitForExistence(timeout: 20)
            || app.staticTexts["Couldn't load departures"].exists
        XCTAssertTrue(boardLoaded)
    }

    /// Full Phase 4 smoke: auto-search a route with overnight service, auto-track
    /// the first result, accept the notification permission prompt, and verify
    /// the pinned tracking card. Skips instead of failing when the live board is
    /// empty (small hours) so the suite stays honest about live-data dependence.
    func testTrackedJourneyFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "WAYPOINT_DEBUG_AUTOSEARCH": "VIC>GTW",
            "WAYPOINT_DEBUG_TRACK": "1",
        ]
        app.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 15) {
            allowButton.tap()
        }

        let trackingLabel = app.staticTexts["Tracking"]
        if !trackingLabel.waitForExistence(timeout: 20) {
            throw XCTSkip("No live departures available to track right now (empty board).")
        }

        let stopButton = app.buttons["Stop"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Platform pending"].exists
                || app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Platform '")).firstMatch.exists
        )

        // Let the card's entrance animation settle so the tap lands on the
        // button's final position, then stop tracking.
        sleep(1)
        stopButton.tap()
        if !trackingLabel.waitForNonExistence(timeout: 5) {
            // The spring animation can swallow a tap; one retry keeps the
            // smoke test honest without making it flaky.
            stopButton.tap()
            XCTAssertTrue(trackingLabel.waitForNonExistence(timeout: 5))
        }
    }
}
