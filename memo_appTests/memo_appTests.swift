//
//  memo_appTests.swift
//  memo_appTests
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import XCTest
import RealmSwift
@testable import memos

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
    /* isSaveFunctionWorksProperly? */
    /* 시나리오 1
     사진을 100장 첨부합니다.
     바로 저장 버튼을 클립합니다.
     오류가 나는지 살펴봅니다.*/
    /* 시나리오 2
     사진을 20장 지웁니다.
     바로 저장 버튼을 클릭합니다.
     오류가 나는지 살펴봅니다.*/
    /* 시나리오 3
     사진 10장 추가 5장 지움 20장 추가 10장 지움
     저장합니다.
     오류가 나는지 살펴봅니다.*/
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let fileManager = FileManager.default
        do {
            let documentDirectoryURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for url in fileURLs {
               try print(url)
            }
        } catch {
            print(error)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
