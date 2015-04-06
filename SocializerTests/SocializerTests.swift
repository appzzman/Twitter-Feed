//
//  SocializerTests.swift
//  SocializerTests
//
//  Created by sadmin on 3/10/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import UIKit
import XCTest

class SocializerTests: XCTestCase {
    let parser:Parser = Parser()
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
        let string = "Pascal Hiel |Security|iBeacon|DDIHi Jackie, You might want to take a look at Kontakt.io's cloudbeacon. [http://kontakt.io/introducing-kontakt-io-cloud-beacon/|leo://plh/http%3A*3*3kontakt%2Eio*3introducing-kontakt-io-cloud-beacon*3/JJkQ?_t=tracking_disc] show less"
        let results =  parser.parseString(string)
        println(results)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
