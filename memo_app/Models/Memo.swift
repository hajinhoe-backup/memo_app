//
//  Memo.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import RealmSwift

/* 메모 모델을 정의합니다.
 realm 데이터베이스에서 이용할 수 있습니다. */
/* 메모 모델은 포토 모델을 자식으로 가집니다. */
class Memo: Object {
    @objc dynamic var id: Int = -1 //할당 안 됨
    @objc dynamic var title: String = ""
    @objc dynamic var content: String = ""
    @objc dynamic var createDate = Date()
    @objc dynamic var editDate = Date()

    let photos = List<Photo>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
