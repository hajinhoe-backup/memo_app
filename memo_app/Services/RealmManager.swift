//
//  RealmManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation
import RealmSwift


public class RealmManager {
    static var realm: Realm {
        get {
            do {
                print("림 게터 1111111111")
                
                let realm = try Realm()
                return realm
            } catch let error as NSError {
                print("Could not access database: ", error) // need log error 패치 필요
                
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
            print("림 게터 2222222")
            return self.realm
        }
    }
    
    public static func write(realm: Realm, writeClosure: () -> ()) {
        do {
            try realm.write {
                writeClosure()
            }
        } catch let error as NSError {
                print("림 에러 기록", error)
        }
    }
}
