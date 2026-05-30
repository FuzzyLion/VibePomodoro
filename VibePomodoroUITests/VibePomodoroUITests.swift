//
//  VibePomodoroUITests.swift
//  VibePomodoroUITests
//
//  Created by Qi Wu on 15.03.26.
//

import XCTest

final class VibePomodoroUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFocusStartPauseResumeSmoke() throws {
        let app = makeCleanApp()
        app.launch()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.tabBars.buttons["Focus"].exists)
        XCTAssertTrue(app.tabBars.buttons["Productivity"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)

        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))

        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testProductivityEmptyStateSmoke() throws {
        let app = makeCleanApp(arguments: ["--open-productivity"])
        app.launch()

        XCTAssertTrue(app.navigationBars["Productivity"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.staticTexts["No finished sessions yet"].exists)
        XCTAssertTrue(app.staticTexts["Complete a full session to start filling these charts. Productivity only reflects finished sessions."].exists)
        XCTAssertTrue(app.staticTexts["Focus Sessions"].exists)
        XCTAssertTrue(app.staticTexts["Focus Time"].exists)
        XCTAssertTrue(app.staticTexts["Break Time"].exists)
        XCTAssertTrue(app.buttons["Time Range"].exists)
    }

    @MainActor
    func testProductivityLongExtremeDataSmoke() throws {
        let app = makeCleanApp(
            arguments: ["--open-productivity"],
            environment: ["VIBE_PRODUCTIVITY_FIXTURE": "long-extreme"]
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Productivity"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Focus Sessions"].exists)
        XCTAssertTrue(app.staticTexts["Focus Time"].exists)
        XCTAssertTrue(app.staticTexts["Break Time"].exists)
        XCTAssertFalse(app.staticTexts["No finished sessions yet"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'finished sessions'")).firstMatch.exists)

        app.buttons["Time Range"].tap()
        XCTAssertTrue(app.buttons["Month"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Month"].tap()
        XCTAssertTrue(app.staticTexts["MONTH"].waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Focus Sessions"].exists)

        app.buttons["Time Range"].tap()
        XCTAssertTrue(app.buttons["Year"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Year"].tap()
        XCTAssertTrue(app.staticTexts["YEAR"].waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Break Time"].exists)
    }

    @MainActor
    private func makeCleanApp(
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-vibe-store"] + arguments
        app.launchEnvironment = [
            "VIBE_UI_TESTING": "1",
            "VIBE_RESET_STORE": "1",
            "VIBE_DEFAULTS_SUITE": "Qi.VibePomodoroUITests.\(name)"
        ].merging(environment) { _, new in new }
        return app
    }
}
