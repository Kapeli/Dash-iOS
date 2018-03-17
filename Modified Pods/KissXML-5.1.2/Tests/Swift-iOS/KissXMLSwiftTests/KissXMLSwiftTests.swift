//
//  KissXMLSwiftTests.swift
//  KissXMLSwiftTests
//
//  Created by David Chiles on 1/29/16.
//
//

import XCTest
import KissXML

class KissXMLSwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testElementCreatoin() {
        let element = NSXMLNode()
        XCTAssertNotNil(element)
    }
    
}
