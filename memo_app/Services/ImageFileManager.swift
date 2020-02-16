//
//  ImageFileManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/14.
//  Copyright © 2020 jinho. All rights reserved.
//

//https://stackoverflow.com/questions/41071976/i-am-confused-about-using-static-method-in-multithreading-java
//카메라를 90도 회전 해서 찍으면 사진 정보에만 회전했다고 남아서 실제 저장시 회전하는 문제점이 있음.
//https://stackoverflow.com/questions/3554244/uiimagepngrepresentation-issues-images-rotated-by-90-degrees
import Foundation
import UIKit

class ImageFileManager {
    // static function으로 하면 멀티쓰레드 문제가 있을 법 한데 흠..
    func rotateImage(image: UIImage) -> UIImage? {
        if (image.imageOrientation == UIImage.Orientation.up ) {
            return image
        }
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return copy
    }
    
    func saveImage(imageName: String, image: UIImage) -> Bool {
        guard let rotatedImage = rotateImage(image: image) else { //이미지의 정보를 따라, 이미지를 정방향으로 돌립니다.
            return false
        }
        guard let data = rotatedImage.pngData() ?? rotatedImage.jpegData(compressionQuality: 1) else {
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
    
    func deleteImage(imageName: String) -> Bool {
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
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func resizeImage(image:UIImage, toWidth width: CGFloat) -> UIImage? {
        if image.size.width <= width {
            return image
        }
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/image.size.width * image.size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, image.scale)
        defer { UIGraphicsEndImageContext() } // 함수가 return 된 후에 실행됩니다.
        image.draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
