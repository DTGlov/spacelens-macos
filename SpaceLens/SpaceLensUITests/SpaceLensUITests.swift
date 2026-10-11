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

        XCTAssertTrue(app.staticTexts["See what is using your storage"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Choose a Folder…"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Choose a folder to find its largest files and folders. SpaceLens won’t modify anything."
            ].exists
        )
    }
}
