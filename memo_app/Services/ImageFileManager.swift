//
//  ImageFileManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/14.
//  Copyright © 2020 jinho. All rights reserved.
//

//https://stackoverflow.com/questions/41071976/i-am-confused-about-using-static-method-in-multithreading-java

import Foundation
import UIKit

class ImageFileManager {
    // static function으로 하면 멀티쓰레드 문제가 있을 법 한데 흠..
    static func saveImage(imageName: String, image: UIImage) -> Bool {
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 1) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent(imageName)!) //!로 처리해도 됨?;
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    static func deleteImage(imageName: String) -> Bool {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(imageName)!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    static func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
}
