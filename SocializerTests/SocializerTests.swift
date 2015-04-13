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
        let string = "RT @alvarodias_: Projeto de Alvaro Dias veda retirada de assinatura em pedido de CPI após leitura http://t.co/U3qG21PU1X via @twitterapi"
        var parser = Parser()
         let results = parser.parseStringForURLS(string)
          println(results)
        
        
        //        let results =  Parser.parseString(string)
 //       println(results)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
