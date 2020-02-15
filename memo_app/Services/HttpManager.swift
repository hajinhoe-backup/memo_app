//
//  HttpManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation
import UIKit

class HTTPRequester {
    class func get(urlComponents: URLComponents,  completion: @escaping(Data?) -> ()) {
        guard let url = urlComponents.url else {
            print("Error : can not make url)")
            return
        }
        
        let request = URLRequest(url: url)
        
        let session = URLSession(configuration: .default)
        
        let dataTask = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error : \(String(describing: error))")
                return
            }

            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                //complete request. return json data.
                print("첫번째 성공")
                completion(data)
            }
        }
        
        if dataTask.state == .running {
            print("im running")
        }
        dataTask.resume()
    }
}
