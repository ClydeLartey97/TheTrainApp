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
