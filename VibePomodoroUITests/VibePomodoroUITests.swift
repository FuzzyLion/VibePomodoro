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
    private func makeCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-vibe-store"]
        app.launchEnvironment = [
            "VIBE_UI_TESTING": "1",
            "VIBE_RESET_STORE": "1",
            "VIBE_DEFAULTS_SUITE": "Qi.VibePomodoroUITests.\(name)"
        ]
        return app
    }
}
