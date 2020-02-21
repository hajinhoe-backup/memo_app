//
//  ImageFileManager.swift
//  memo_app
//
//  Created by jinho on 2020/02/14.
//  Copyright © 2020 jinho. All rights reserved.
//

//참고 자료
//https://stackoverflow.com/questions/41071976/i-am-confused-about-using-static-method-in-multithreading-java
//https://stackoverflow.com/questions/3554244/uiimagepngrepresentation-issues-images-rotated-by-90-degrees
import Foundation
import UIKit

/* 아래의 클래스는 이미지 저장, 처리와 관련된 클래스입니다. */

/* temporary 저장소는 실제 iOS의 temporary 저장소가 아닙니다.
 iOS의 temporary 저장소는 적절하게 자신의 파일을 알아서 지우기 때문에 한 번에 저장하는 용도로 이용이 어렵습니다. */

enum ImageFileManagerError: Error {
    case getUrlError
    case diretoryUrlError
    case writeError
    case moveError
    case removeError
    case temporaryImageDeleteError
}

enum DirectoryType {
    case original
    case thumbnail
    case originalTemporary
}

class ImageFileManager {
    func getDirectoryURL(directory: DirectoryType) throws -> URL {
        /* directory 변수에 URL 타입을 대입합니다. 결과적으로 에러가 없다면 항상 nil이 아닙니다. */
        var directoryName = ""
        
        switch directory {
        case .original:
            directoryName = "originalImage"
        case .thumbnail:
            directoryName = "thumbnailImage"
        case .originalTemporary:
            directoryName = "originalTemporary"
        }
        
        guard var directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            throw ImageFileManagerError.getUrlError
        }

        directory.appendPathComponent(directoryName)
        
        // 다이렉토리가 존재하는지 검사 한 후, 없다면 생성합니다.
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(atPath: directory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("폴더생성문제?")
                print(error)
                throw ImageFileManagerError.getUrlError
            }
        }
        
        return directory
    }
    
    /* 파일 데이터를 저장합니다. */
    func saveImage(imageName: String, imageData: Data, directory: DirectoryType) throws {
        guard let directory = try? getDirectoryURL(directory: directory) else {
            throw ImageFileManagerError.writeError
        }
        
        do {
            try imageData.write(to: directory.appendingPathComponent(imageName))
        } catch {
            print(error)
            throw ImageFileManagerError.writeError
        }
    }
    
    /* 임시 이미지를 정식 저장소로 옮깁니다. */
    func moveFromTo(from fromDirectory: DirectoryType, fromImageName: String, to toDirectory: DirectoryType, toImageName: String) throws {
        guard let originalTemporaryImageDirectory = try? getDirectoryURL(directory: fromDirectory) else {
            throw ImageFileManagerError.diretoryUrlError
        }
        
        guard let originalImageDirectory = try? getDirectoryURL(directory: toDirectory) else {
            throw ImageFileManagerError.diretoryUrlError
        }
        
        do {
            try FileManager.default.moveItem(at: originalTemporaryImageDirectory.appendingPathComponent(fromImageName), to: originalImageDirectory.appendingPathComponent(toImageName))
        } catch {
            print(error)
            throw ImageFileManagerError.moveError
        }
    }
    
    /* 이미지를 저장소에서 지웁니다. */
    func deleteImage(imageName: String, directory: DirectoryType) throws {
        guard let directory = try? getDirectoryURL(directory: directory) else {
            throw ImageFileManagerError.diretoryUrlError
        }
        do {
            try FileManager.default.removeItem(at: directory.appendingPathComponent(imageName))
        } catch {
            print(error)
            throw ImageFileManagerError.removeError
        }
    }
    
    /* 임시 저장 이미지 들을 지웁니다. */
    func clearDirectory(directory: DirectoryType) throws {
        do {
            guard let originalTemporaryImageDirectory = try? getDirectoryURL(directory: directory) else {
                throw ImageFileManagerError.getUrlError
            }
            let fileUrls = try FileManager.default.contentsOfDirectory(at: originalTemporaryImageDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for url in fileUrls {
               try FileManager.default.removeItem(at: url)
            }
        } catch {
            print(error)
            throw ImageFileManagerError.temporaryImageDeleteError
        }
    }
    
    /* 저장된 이미지를 가져옵니다. */
    func getSavedImage(named: String, directory: DirectoryType) -> UIImage? {
        if let dir = try? getDirectoryURL(directory: directory) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        
        return nil
    }
}
