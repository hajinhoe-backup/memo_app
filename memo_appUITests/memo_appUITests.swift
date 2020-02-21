//
//  memo_appUITests.swift
//  memo_appUITests
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import XCTest

class memo_appUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNewViewControllerOrReuseIsFast1() {
        /* 간이 테스트 결과*/
        /* 뷰 컨트롤러를 lazy var로 정의하고, 매번 임의 초기화 후 재사용, 실코드는 lazy 아님*/
        /* 사진을 8개 추가 후 사용 */
        /* Result */
        /*
         "Time elapsed for First: 1.8201889991760254 s.", "Time elapsed for Second: 1.3239339590072632 s.", "Time elapsed for third: 1.3270409107208252 s.",
         "Time elapsed for First: 1.6321699619293213 s.", "Time elapsed for Second: 1.329679012298584 s.", "Time elapsed for third: 1.3362780809402466 s.",
         "Time elapsed for First: 1.6008620262145996 s.", "Time elapsed for Second: 1.3377079963684082 s.", "Time elapsed for third: 1.3378280401229858 s."]
         엄청나지는 않지만, 어느정도 재사용이 더 빠른 듯함.
         */
        var testResults: [String] = []
        
        for _ in (0..<3) {
            let app = XCUIApplication()
            app.launch()
            
            // 기다리기
            sleep(5)
            
            // 변인 통제를 위해 변수 미리 첫 할당
            var startTime = CFAbsoluteTimeGetCurrent()
            var timeElapsed = CFAbsoluteTimeGetCurrent()
            
            sleep(5)
            
            // 뷰가 로드 될 때
            startTime = CFAbsoluteTimeGetCurrent()
            app.tables.cells.allElementsBoundByIndex[0].tap()
            app.navigationBars.buttons.allElementsBoundByIndex[0].tap()
            timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            testResults.append("Time elapsed for First: \(timeElapsed) s.")
        
            sleep(5)
            
            startTime = CFAbsoluteTimeGetCurrent()
            app.tables.cells.allElementsBoundByIndex[0].tap()
            app.navigationBars.buttons.allElementsBoundByIndex[0].tap()
            timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            testResults.append("Time elapsed for Second: \(timeElapsed) s.")
            
            sleep(5)
                
            startTime = CFAbsoluteTimeGetCurrent()
            app.tables.cells.allElementsBoundByIndex[0].tap()
            app.navigationBars.buttons.allElementsBoundByIndex[0].tap()
            timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            testResults.append("Time elapsed for third: \(timeElapsed) s.")
            
            app.terminate()
        }
        
        print(testResults)
    }
    
    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
                
            }
        }
    }
}
