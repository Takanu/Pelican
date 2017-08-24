//
//  LogTest.swift
//  PelicanTests
//
//  Created by Ido Constantine on 23/08/2017.
//

import XCTest

class LogTest: XCTestCase {
	
	/// The template to be operated with.
	var ghost = try! GhostPelican()

    override func setUp() {
			
			// Build a new template
			ghost = try! GhostPelican()
    }
    
    override func tearDown() {
			
    }

    func testExample() {
			
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
