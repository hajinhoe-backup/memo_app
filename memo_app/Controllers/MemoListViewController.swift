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
    let imageFileManager = ImageFileManager()
    
    var memos: [Memo] = []
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(moveMemoWriteView))
        navigationItem.title = "Memo List".localized()
        
    }
    
    @objc func moveMemoWriteView() {
        memoViewController.setToFirstWriteMode()
        memoViewController.needInitialize = true
        memoViewController.memo = Memo()
        navigationController?.pushViewController(memoViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* 데이터를 갱신합니다. */
        memos.removeAll(keepingCapacity: true)
        
        let datas = RealmManager.realm.objects(Memo.self)
        
        for idx in (0..<datas.count) {
            memos.append(datas[datas.count - idx - 1])
        }

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // register 된 셀이므로 형변환에 실패하지 않습니다. (맞나?)ㅇㅇㅁㄴㅇ오노 수정필요
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
            cell.imagePreView.image = imageFileManager.getSavedImage(named: imageUrl)
            cell.imagePreView.isHidden = false
        } else {
            cell.imagePreView.isHidden = true
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        //iOS 버전 11+ 부터 automaticDimension이 지원됩니다. (예정)
        //return UITableView.automaticDimension
        return 120
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        memoViewController.setToViewMode()
        memoViewController.needInitialize = true
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
    
    func deleteMemo(indexPath: IndexPath) {
        print("지웁니다?")
        for photo in memos[indexPath.item].photos {
            imageFileManager.deleteImage(imageName: photo.url)
        }
        
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.delete(memos[indexPath.item].photos)
            RealmManager.realm.delete(memos[indexPath.item])
        }
        memos.remove(at: indexPath.item)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memos.count
    }
}
