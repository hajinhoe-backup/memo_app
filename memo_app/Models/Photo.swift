//
//  Photo.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import RealmSwift

/* 포토 모델을 정의합니다. */
class Photo: Object {
    @objc dynamic var id: Int = -1 //할당 안 됨
    @objc dynamic var url: String = "" //NSURL 서포트 안 함
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
