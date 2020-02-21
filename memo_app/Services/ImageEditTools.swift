//
//  ImageTools.swift
//  memo_app
//
//  Created by jinho on 2020/02/20.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

enum ImageEditToolsError: Error {
    case convertError
}

class ImageEditTools {
    /* 이미지를 width에 맞게 리사이징 합니다. */
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
    
    /* 메타 데이터를 기록하지 않기 때문에 이미지를 회전 시킵니다.*/
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
    
    func uiimageToFileData(image: UIImage?) throws -> Data {
        guard let image = image, let data = image.pngData() ?? image.jpegData(compressionQuality: 1) else {
            print("유아이이미지투파일데이타")
            throw ImageEditToolsError.convertError
        }
        
        return data
    }
}
