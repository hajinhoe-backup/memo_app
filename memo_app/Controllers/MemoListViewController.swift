//
//  MemoListViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//
/*
 제일 처음 보여지게 되는 메모의 리스트 뷰입니다.
 */

import Foundation
import RealmSwift
import UIKit

class MemoListViewController: UITableViewController {
    /* 좌측 이미지 프리뷰에 쓰이는 캐시를 정의합니다. */
    let imagePreviewCache = ImageCacheManager.manager.thumnailCache
    
    /* 이미지 데이터를 불러오는 매니저를 생성합니다. */
    let imageFileManager = ImageFileManager()
    
    var memos: [Memo] = []
    
    /* 메모 보기 화면을 생성합니다. 재활용됩니다. */
    /* 메모 보기 화면은 접근이 잦으므로, 바로 생성합니다. */
    let memoViewController: MemoViewContoller = {
        let layout = UICollectionViewFlowLayout()
        layout.headerReferenceSize = CGSize(width: 100, height: 100)
        let viewController = MemoViewContoller(collectionViewLayout: layout)
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.dataSource = self
        self.tableView.register(MemoListCellView.self, forCellReuseIdentifier: "cell")
        
        /* iOS 버전 11+ 부터 atomativDimension을 지원합니다. (예정)*/
        //self.tableView.rowHeight = UITableView.automaticDimension
        //self.tableView.estimatedRowHeight = UITableView.automaticDimension
        
        self.tableView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(moveMemoWriteView))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(changeListEditMode))
        
        navigationItem.title = "Memo List".localized()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* 데이터를 갱신합니다. */
        memos.removeAll(keepingCapacity: true)
        
        // Edit Date가 최근인 순으로 보여줍니다.
        memos = RealmManager.realm.objects(Memo.self).sorted(byKeyPath: "editDate", ascending: false).map{ $0 }
        
        tableView.reloadData()
        
        memoViewController.needInitialize = true
        
        if tableView.isEditing {
            changeListEditMode()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MemoListCellView
        
        if memos[indexPath.item].title != "" {
            cell.cellTitleView.text = memos[indexPath.item].title
        } else {
            cell.cellTitleView.text = "There's no title".localized()
        }
        
        if memos[indexPath.item].content != "" {
            cell.cellContentPreviewView.text = memos[indexPath.item].content
        } else {
            cell.cellContentPreviewView.text = "There's no content".localized()
        }
        
        if let imageUrl = memos[indexPath.item].photos.first?.url {
            if let image = getImagePreviewCache(url: imageUrl) {
                cell.imagePreView.image = image
            }
            cell.imagePreView.isHidden = false
        } else {
            cell.imagePreView.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        //iOS 버전 11+ 부터 automaticDimension이 지원됩니다. (예정)
        //return UITableView.automaticDimension
        return 130
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        memoViewController.setToViewMode()
        memoViewController.memo = memos[indexPath.item]
        navigationController?.pushViewController(memoViewController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteMemo(indexPath: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memos.count
    }
}

extension MemoListViewController {
    /* Edit 버튼의 작동 메소드입니다. 버튼의 모양과 리스트 뷰에 삭제 버튼 변화 여뷰를 바꿔줍니다. */
    @objc func changeListEditMode() {
        tableView.isEditing = !tableView.isEditing
        
        if tableView.isEditing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(changeListEditMode))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(changeListEditMode))
        }
        
    }
    
    /* 좌로 슬라이드 했을 때, 메모를 지우는 메소드 입니다.
     데이터베이스에서 메모와 사진, 그리고 사진의 파일을 지웁니다. */
    func deleteMemo(indexPath: IndexPath) {
        for photo in memos[indexPath.item].photos {
            do {
                try imageFileManager.deleteImage(imageName: photo.url, directory: .original)
                try imageFileManager.deleteImage(imageName: photo.url, directory: .thumbnail)
            } catch {
                print(error)
            }
            // 캐시 제거
            ImageCacheManager.manager.originalCache.removeObject(forKey: photo.url as NSString)
            ImageCacheManager.manager.thumnailCache.removeObject(forKey: photo.url as NSString)
        }
        
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.delete(memos[indexPath.item].photos)
            RealmManager.realm.delete(memos[indexPath.item])
        }
        memos.remove(at: indexPath.item)
        tableView.reloadData()
    }
    
    func getImagePreviewCache(url: String) -> UIImage? {
        if let image = imagePreviewCache.object(forKey: url as NSString) {
            return image
        }
        if let image = imageFileManager.getSavedImage(named: url, directory: .thumbnail) {
            DispatchQueue.global().async {
                self.imagePreviewCache.setObject(image, forKey: url as NSString)
            }
            return image
        }
        return nil
    }
    
    /* 메모 뷰로 옮겨주는 메소드 입니다. */
    @objc func moveMemoWriteView() {
        memoViewController.setToFirstWriteMode()
        memoViewController.memo = Memo()
        navigationController?.pushViewController(memoViewController, animated: true)
    }
}
