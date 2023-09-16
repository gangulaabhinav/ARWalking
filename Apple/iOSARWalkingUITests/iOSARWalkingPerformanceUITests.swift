//
//  iOSARWalkingPerformanceUITests.swift
//  iOSARWalkingUITests
//
//  Created by Abhinav Gangula on 16/09/23.
//

import XCTest

final class iOSARWalkingPerformanceUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testMemory() throws {
        let options = XCTMeasureOptions()
            options.invocationOptions = [.manuallyStart]
        measure(metrics: [XCTMemoryMetric(application: app)],
                    options: options) {
            startMeasuring()
        }
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
