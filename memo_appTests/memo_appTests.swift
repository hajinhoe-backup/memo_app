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
        
        // 데이터 저장 폴더 초기화
        let fileManager = ImageFileManager()
        do {
            try fileManager.clearDirectory(directory: .original)
            try fileManager.clearDirectory(directory: .originalTemporary)
            try fileManager.clearDirectory(directory: .thumbnail)
        } catch {
            print("폴더 초기화 중 에러 발생!")
            print(error)
        }
        // 테스트 전 데이터 베이스를 초기화합니다.
        RealmManager.initRealm()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // 데이터 저장 폴더 초기화
        let fileManager = ImageFileManager()
        do {
            try fileManager.clearDirectory(directory: .original)
            try fileManager.clearDirectory(directory: .originalTemporary)
            try fileManager.clearDirectory(directory: .thumbnail)
        } catch {
            print("폴더 초기화 중 에러 발생!")
            print(error)
        }
        
        RealmManager.initRealm()
    }
    
    /* Photo 50개를 한 번에 저장하는 테스트입니다. */
    func testPhotoSave50atOnece() {
        clean()
        let controller = MemoViewContoller(collectionViewLayout: .init())
        
        controller.isEditing = true
        controller.isFirstWrite = true
        controller.initializeView()
        
        for _ in (0..<50) {
            controller.savePhotoTemporary(image: UIImage(imageLiteralResourceName: "broken"))
        }
        controller.savePhotosPermanently()
        
        print("------test result-------")
        print(controller.photos)
        
        XCTAssert(controller.photos.count == 50)
    }
    
    /* Photo를 한 번에 한 개씩 총 50개 저장하는 테스트입니다. */
    func testPhotoSave50saveatmost1() {
        clean()
        let controller = MemoViewContoller(collectionViewLayout: .init())
        
        controller.isEditing = true
        controller.isFirstWrite = true
        controller.initializeView()
        
        controller.saveMemo()
        
        for _ in (0..<50) {
            controller.editMemo() /* savePhoto가 db의 정보를 활용해서 매번 저장해줘야할 필요 있음 */
            controller.savePhotoTemporary(image: UIImage(imageLiteralResourceName: "testimage"))
            controller.savePhotosPermanently()
        }
        
        print("------test result-------")
        print(controller.photos)
        
        XCTAssert(controller.photos.count == 50)
    }
    
    /* 메모 저장 기능을 테스트 합니다. */
    func testSaveMemo() {
        let controller = MemoViewContoller(collectionViewLayout: .init())
        
        controller.isEditing = true
        controller.isFirstWrite = true
        controller.initializeView()
        
        for _ in (0..<50) {
            controller.savePhotoTemporary(image: UIImage(imageLiteralResourceName: "testimage"))
        }
        
        controller.saveMemo()
        controller.savePhotosPermanently()
        
        print("------test result-------")
        print(controller.memo)
        
        XCTAssert(controller.memo.id != -1 && controller.photos.count == 50)
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
    
    func testFileManagerClean(){
        let fileManager = ImageFileManager()
        do {
            try fileManager.clearDirectory(directory: .original)
        } catch {
            print("폴더 초기화 중 에러 발생!")
            print(error)
        }
        
        guard let originalTemporaryImageDirectory = try? fileManager.getDirectoryURL(directory: .original) else {
                return
            }
        
        let fileUrls = try? FileManager.default.contentsOfDirectory(at: originalTemporaryImageDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        
        print("------test result-------")
        XCTAssert(fileUrls!.count == 0)
    }
    
    func clean() {
        // 데이터 저장 폴더 초기화
        let fileManager = ImageFileManager()
        do {
            try fileManager.clearDirectory(directory: .original)
            try fileManager.clearDirectory(directory: .originalTemporary)
            try fileManager.clearDirectory(directory: .thumbnail)
        } catch {
            print("폴더 초기화 중 에러 발생!")
            print(error)
        }
        // 테스트 전 데이터 베이스를 초기화합니다.
        RealmManager.initRealm()
    }

}
