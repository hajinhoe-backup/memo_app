//
//  HttpManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation
import UIKit

/* HTTP 요청을 위한 HttpManager 클래스를 정의합니다. */
class HttpManager {
    /* URL로 부터 이미지를 얻어옵니다. 요청에 실패하거나, 이미지가 아닌 경우 nil을 반환합니다. */
    func getImage(from url: URL, complition: @escaping(UIImage?, Error?) -> ()) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                complition(nil, error)
                return
            }
            complition(image, error)
        }
        task.resume()
        return task
    }
    
    /* String을 URL로 변환하여 리턴합니다. nil이 될 수 있습니다. (실패) */
    func stringToUrl(from link: String) -> URL? {
        if let url = URL(string: link) {
            if UIApplication.shared.canOpenURL(url) {
                return url
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
