//
//  SpaceLensUITestsLaunchTests.swift
//  SpaceLensUITests
//
//  Created by David Glover on 10/11/26.
//

import XCTest

final class SpaceLensUITestsLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
    }
}
