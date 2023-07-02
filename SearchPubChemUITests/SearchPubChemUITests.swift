//
//  SearchPubChemUITests.swift
//  SearchPubChemUITests
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import XCTest

class SearchPubChemUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        // We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--uitesting")
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSelectTabs() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        app.launch()
        
        let compoundTabSelected = app.buttons["compoundTabSelected"]
        let compoundTabUnselected = app.buttons["compoundTabUnselected"]
        let solutionTabSelected = app.buttons["solutionTabSelected"]
        let solutionTabUnselected = app.buttons["solutionTabUnselected"]
        
        XCTAssert(compoundTabSelected.exists)
        XCTAssert(solutionTabUnselected.exists)
        
        solutionTabUnselected.tap()
        
        XCTAssert(compoundTabUnselected.exists)
        XCTAssert(solutionTabSelected.exists)
        
        compoundTabUnselected.tap()
        XCTAssert(compoundTabSelected.exists)
        XCTAssert(solutionTabUnselected.exists)
    }
    
    func testTagButton() {
        app.launch()
        
        let compoundTabSelected = app.buttons["compoundTabSelected"]
        let compoundTabUnselected = app.buttons["compoundTabUnselected"]
        if compoundTabUnselected.exists {
            compoundTabUnselected.tap()
        }
        
        let tagButton = app.buttons["tagButton"]
        XCTAssert(tagButton.exists)
        
        tagButton.tap()
        
        let resetTagButton = app.buttons["resetTagButton"]
        XCTAssert(resetTagButton.exists)

        resetTagButton.tap()
        XCTAssertFalse(resetTagButton.waitForExistence(timeout: 0.5))
        
        XCTAssert(compoundTabSelected.exists)
    }
}
