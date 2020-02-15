//
//  Memo.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import RealmSwift

class Memo: Object {
    @objc dynamic var id: Int = -1 //할당 안 됨
    @objc dynamic var title: String = ""
    @objc dynamic var content: String = ""
    //@objc dynamic var date 날짜는 나중에
    let photos = List<Photo>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
