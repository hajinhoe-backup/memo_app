//
//  memo_appTests.swift
//  memo_appTests
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import XCTest
import RealmSwift
@testable import memo_app

class memo_appTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        //일단 초기화 박아버리자
            let realmURL = Realm.Configuration.defaultConfiguration.fileURL!

            let realmURLs = [
                realmURL,
                realmURL.appendingPathExtension("lock"),
                realmURL.appendingPathExtension("note"),
                realmURL.appendingPathExtension("management")

            ]

            for URL in realmURLs {
                do {
                    try FileManager.default.removeItem(at: URL)
                } catch {
                    // handle error
                }
        }
    
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
