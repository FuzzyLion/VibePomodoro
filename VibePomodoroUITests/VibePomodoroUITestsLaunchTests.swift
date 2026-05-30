//
//  VibePomodoroUITestsLaunchTests.swift
//  VibePomodoroUITests
//
//  Created by Qi Wu on 15.03.26.
//

import XCTest

final class VibePomodoroUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-vibe-store"]
        app.launchEnvironment = [
            "VIBE_UI_TESTING": "1",
            "VIBE_RESET_STORE": "1",
            "VIBE_DEFAULTS_SUITE": "Qi.VibePomodoroUITests.\(name)"
        ]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
