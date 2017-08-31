//
//  TestMessageSending.swift
//  PelicanTests
//
//  Created by Ido Constantine on 31/08/2017.
//

import XCTest
import Pelican

class TestMessageSending: XCTestCase {

	/// The template to be operated with.
	var ghost = try! GhostPelican()
	
	override func setUp() {
		
		// Build a new template
		ghost = try! GhostPelican()
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
			
			let file = Audio(url: "vibri.mp3", duration: 0)
			let request = TelegramRequest.sendFile(file: file, chatID: <#T##Int#>, markup: <#T##MarkupType?#>)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
