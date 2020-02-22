//
//  RealmManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation
import RealmSwift

/* Realm 이용을 위한 RealmManager 클래스를 정의합니다. */
public class RealmManager {
    /* 전역 림 객체를 반환합니다. */
    static var realm: Realm {
        get {
            do {
                let realm = try Realm()
                return realm
            } catch let error as NSError {
                print("Could not access database: ", error)
            }
            return self.realm
        }
    }
    
    /* 클로저 안에서 림의 쓰기 작업을 합니다. */
    static func write(realm: Realm, writeClosure: () -> ()) {
        do {
            try realm.write {
                writeClosure()
            }
        } catch let error as NSError {
                print("Realm Write Error: ", error)
        }
    }
    
    /* Realm을 초기화 합니다. */
    static func initRealm() {
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
            } catch let error as NSError {
                print("Error while init Realm: ", error)
            }

        }
    }
}
