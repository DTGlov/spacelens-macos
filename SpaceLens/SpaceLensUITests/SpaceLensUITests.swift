//
//  SpaceLensUITests.swift
//  SpaceLensUITests
//
//  Created by David Glover on 10/11/26.
//

import XCTest

final class SpaceLensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testWelcomeScreenExplainsTheSafeStartingState() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["See where your storage went."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Choose a folder to scan"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Scans stay on your Mac. Nothing moves unless you confirm it."
            ].exists
        )
    }
}
