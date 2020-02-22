//
//  ImageCacheManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/22.
//  Copyright © 2020 jinho. All rights reserved.
//

/* 이미지 캐시를 전역 관리하는 매니저 입니다. */
/* 오리지날 이미지와 썸네일 이미지의 캐시를 따로 관리합니다. */
/* 전역 이미지 캐시 관리자를 이용하면, 각 뷰가 개별로 캐시를 관리할 때에 비해 캐시 데이터의 무결성 관리가 쉽다는 장점이 있습니다. */
/* 무결성 관리 방법을 위해 다른 방법을 사용(eg. id 말고 각 이미지 데이터 마다 절대로 중복되지 않는 unique id 부여, 노티피케이션 등...)할 수도 있지만, 간략하게 이용해봅니다. */
import UIKit

class ImageCacheManager {
    static let manager = ImageCacheManager()
    
    var thumnailCache = NSCache<NSString, UIImage>()
    var originalCache = NSCache<NSString, UIImage>()
}
