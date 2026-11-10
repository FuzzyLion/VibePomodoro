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
        XCTAssertTrue(app.staticTexts["Sessions appear here once they end, including ones you finish early. A session in progress isn't counted until then."].exists)
        XCTAssertTrue(app.staticTexts["Rhythm"].exists)
        XCTAssertFalse(app.staticTexts["Sessions"].exists)
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
        XCTAssertTrue(app.staticTexts["Rhythm"].exists)
        XCTAssertTrue(app.staticTexts["Sessions"].exists)
        XCTAssertFalse(app.staticTexts["No finished sessions yet"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' across ' AND label CONTAINS 'focus blocks'")).firstMatch.exists, app.debugDescription)
        XCTAssertTrue(rangeCaption(in: app, startingWith: "Last 7 days").exists, app.debugDescription)

        app.buttons["Time Range"].tap()
        XCTAssertTrue(app.buttons["Month"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Month"].tap()
        XCTAssertTrue(rangeCaption(in: app, startingWith: "Last 30 days").waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Rhythm"].exists)

        app.buttons["Time Range"].tap()
        XCTAssertTrue(app.buttons["Year"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Year"].tap()
        XCTAssertTrue(rangeCaption(in: app, startingWith: "Last 12 months").waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Sessions"].exists)
    }

    @MainActor
    func testProductivityTappingABarShowsThatDaysSessions() throws {
        let app = makeCleanApp(
            arguments: ["--open-productivity"],
            environment: ["VIBE_PRODUCTIVITY_FIXTURE": "long-extreme"]
        )
        app.launch()
        XCTAssertTrue(app.navigationBars["Productivity"].waitForExistence(timeout: 8), app.debugDescription)

        try assertTappingTodaysBarShowsTodaysSessions(app)
    }

    @MainActor
    func testProductivityWorksAtTheLargestTextSize() throws {
        let app = makeCleanApp(
            arguments: ["--open-productivity", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"],
            environment: ["VIBE_PRODUCTIVITY_FIXTURE": "long-extreme"]
        )
        app.launch()
        XCTAssertTrue(app.navigationBars["Productivity"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Rhythm"].exists)
        XCTAssertTrue(rangeCaption(in: app, startingWith: "Last 7 days").exists, app.debugDescription)

        try assertTappingTodaysBarShowsTodaysSessions(app)

        app.buttons["Time Range"].tap()
        XCTAssertTrue(app.buttons["Month"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Month"].tap()
        XCTAssertTrue(rangeCaption(in: app, startingWith: "Last 30 days").waitForExistence(timeout: 2), app.debugDescription)
    }

    @MainActor
    private func assertTappingTodaysBarShowsTodaysSessions(_ app: XCUIApplication) throws {
        let today = Date()
        let spokenDay = englishDateText(today, format: "EEEE d MMMM")
        let shownDay = englishDateText(today, format: "EEE d MMM")
        let todaysBars = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", spokenDay))
        XCTAssertTrue(todaysBars.firstMatch.waitForExistence(timeout: 2), app.debugDescription)

        // Tap today's column once it is clear of the navigation and tab bars.
        let visibleTop = app.navigationBars.firstMatch.frame.maxY + 8
        let visibleBottom = app.tabBars.firstMatch.frame.minY - 8
        func uncoveredBar() -> XCUIElement? {
            todaysBars.allElementsBoundByIndex.first { $0.frame.minY > visibleTop && $0.frame.maxY < visibleBottom }
        }
        var candidate = uncoveredBar()
        for _ in 0..<3 where candidate == nil {
            app.swipeUp()
            candidate = uncoveredBar()
        }
        let todaysBar = try XCTUnwrap(candidate, app.debugDescription)
        // The fixture has one session a day; before the tap the list shows the latest five.
        let sessionRows = app.descendants(matching: .any).matching(identifier: "productivity.session")
        XCTAssertEqual(sessionRows.count, 5, app.debugDescription)

        todaysBar.tap()
        XCTAssertTrue(app.staticTexts[shownDay].waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertEqual(sessionRows.count, 1, app.debugDescription)

        todaysBar.tap()
        let cleared = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.staticTexts[shownDay])
        wait(for: [cleared], timeout: 2)
        XCTAssertEqual(sessionRows.count, 5, app.debugDescription)
    }

    private func rangeCaption(in app: XCUIApplication, startingWith title: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    private func englishDateText(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    @MainActor
    func testSettingsSessionRhythmPickerExpandsAndCollapses() throws {
        let app = makeCleanApp(arguments: ["--open-settings"])
        app.terminate()
        app.launch()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), app.debugDescription)

        let shortBreakRow = app.buttons["settings.sessionRhythm.shortBreak"]
        XCTAssertTrue(shortBreakRow.waitForExistence(timeout: 2), app.debugDescription)

        let shortBreakPicker = app.descendants(matching: .any)["settings.sessionRhythm.shortBreak.picker"]
        XCTAssertFalse(shortBreakPicker.exists, app.debugDescription)

        shortBreakRow.tap()
        XCTAssertTrue(
            shortBreakPicker.waitForExistence(timeout: 2),
            app.debugDescription
        )

        shortBreakRow.tap()
        XCTAssertTrue(
            waitForElementToDisappear(shortBreakPicker, timeout: 2),
            app.debugDescription
        )

        XCTAssertTrue(app.buttons["settings.sessionRhythm.longBreak"].exists)
    }

    @MainActor
    func testSettingsAppearanceMenuSwitchesBetweenModes() throws {
        let app = makeCleanApp(arguments: ["--open-settings"])
        app.launch()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertFalse(app.staticTexts["APPEARANCE"].exists)
        XCTAssertTrue(app.staticTexts["DISPLAY"].exists)

        let appearanceMenu = app.buttons["settings.appearance"]
        XCTAssertTrue(appearanceMenu.waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(app.switches["Keep Screen On"].exists || app.buttons["Keep Screen On"].exists)
        XCTAssertTrue(app.staticTexts["Follow System"].exists)

        scrollUntilHittable(appearanceMenu, in: app)
        appearanceMenu.tap()
        XCTAssertTrue(app.buttons["Dark"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Dark"].tap()
        XCTAssertTrue(app.staticTexts["Dark"].waitForExistence(timeout: 2), app.debugDescription)

        appearanceMenu.tap()
        XCTAssertTrue(app.buttons["Light"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Light"].tap()
        XCTAssertTrue(app.staticTexts["Light"].waitForExistence(timeout: 2), app.debugDescription)

        appearanceMenu.tap()
        XCTAssertTrue(app.buttons["Follow System"].waitForExistence(timeout: 2), app.debugDescription)
        app.buttons["Follow System"].tap()
        XCTAssertTrue(app.staticTexts["Follow System"].waitForExistence(timeout: 2), app.debugDescription)
    }

    @MainActor
    func testSettingsLinksToIOSSettingsWhenNotificationsAreBlocked() throws {
        let app = makeCleanApp(
            arguments: ["--open-settings"],
            environment: ["VIBE_NOTIFICATION_PERMISSION": "denied"]
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), app.debugDescription)

        let openSettings = app.buttons["settings.notifications.openSettings"]
        XCTAssertTrue(openSettings.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertTrue(element(in: app, containing: "Off in iOS Settings").exists, app.debugDescription)
        XCTAssertFalse(app.switches["Notifications"].exists)

        // Sound also plays inside the app, so it stays adjustable and says where it can be heard.
        let sound = app.switches["Sound"]
        XCTAssertTrue(sound.exists, app.debugDescription)
        XCTAssertTrue(sound.isEnabled)
        XCTAssertTrue(element(in: app, containing: "Only while the app is open").exists, app.debugDescription)
    }

    @MainActor
    func testSettingsRowsStayLeadingAtTheLargestTextSize() throws {
        let app = makeCleanApp(
            arguments: [
                "--open-settings",
                "--appearance-light",
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), app.debugDescription)
        attachScreenshot(named: "settings-largest-text-top")

        // At this size a row stacks its label over its value. A section label marks the card's leading
        // edge, and a value that sits more than a pill's inset to its right has drifted to the center.
        let appearanceMenu = app.buttons["settings.appearance"]
        scrollUntilHittable(appearanceMenu, in: app, maxSwipes: 8)
        let display = app.staticTexts["DISPLAY"]
        let appearanceValue = app.staticTexts["Light"]
        XCTAssertTrue(display.exists && appearanceValue.exists, app.debugDescription)
        XCTAssertLessThan(appearanceValue.frame.minX - display.frame.minX, 20)
        attachScreenshot(named: "settings-largest-text-display")

        appearanceMenu.tap()
        XCTAssertTrue(app.buttons["Dark"].waitForExistence(timeout: 2), app.debugDescription)
        attachScreenshot(named: "settings-largest-text-appearance-menu")
        app.buttons["Light"].tap()

        let shareAppStatus = app.staticTexts.matching(NSPredicate(format: "label == 'SOON'")).element(boundBy: 1)
        scrollUntilHittable(shareAppStatus, in: app, maxSwipes: 8)
        let other = app.staticTexts["OTHER"]
        XCTAssertTrue(other.exists && shareAppStatus.exists, app.debugDescription)
        XCTAssertLessThan(shareAppStatus.frame.minX - other.frame.minX, 20)
        app.swipeUp()
        attachScreenshot(named: "settings-largest-text-bottom")
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func element(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    @MainActor
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if !element.exists {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline

        return !element.exists
    }

    @MainActor
    private func scrollUntilHittable(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 4
    ) {
        var remainingSwipes = maxSwipes

        while element.exists && !element.isHittable && remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
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
