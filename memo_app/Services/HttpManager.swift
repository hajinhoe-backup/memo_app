//
//  HttpManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation
import UIKit

class HttpManager {
    /* URL로 부터 이미지를 얻어옵니다. 요청에 실패하거나, 이미지가 아닌 경우 nil을 반환합니다. */
    func getImage(from url: URL, complition: @escaping(UIImage?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                complition(nil)
                return
            }
            complition(image)
        }.resume()
    }
    
    /* String을 URL로 변환하여 리턴합니다. nil이 될 수 있습니다. (실패) */
    func stringToUrl(from link: String) -> URL? {
        if let url = URL(string: link) {
            return url
        } else {
            return nil
        }
    }
}
