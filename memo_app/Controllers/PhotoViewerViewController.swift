//
//  PhotoViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/20.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UICollectionViewController {
    // 캐시를 전역 싱글톤으로 쓰는게 좋을 듯?
    var cachedImages = NSCache<NSString, UIImage>() // NSCache는 스레드 세이프 함.
    
    var photos: [Photo] = []
    
    var photoOffset = IndexPath()
    
    let imageFileManager = ImageFileManager()
    
    func getPhotoViewerViewCache(indexPath: IndexPath) -> UIImage? {
        if indexPath.item < photos.count { // 영원하게 저장되어 있는 경우
            let idValue = String(photos[indexPath.item].id)
            
            if let cachedImage = cachedImages.object(forKey: idValue as NSString) { // 캐시에 저장되어 있음
                return cachedImage
            }
            
            // 캐시되어 있지 않은 경우 이미지를 가져온다.
            // 크기가 작은 썸네일을 먼저 가져온다.
            let url = photos[indexPath.item].url
            if let cachedImage = self.imageFileManager.getSavedImage(named: url, directory: .thumbnail) {
                DispatchQueue.global().async {
                    //고화질 이미지를 가져온다.
                    if let originalImage = self.imageFileManager.getSavedImage(named: url, directory: .original) {
                        self.cachedImages.setObject(originalImage, forKey: idValue as NSString)
                        DispatchQueue.main.async {
                            //고화질 이미지를 가져온 후 업데이트 한다.
                            self.collectionView.reloadData()
                        }
                    }
                }
                return cachedImage
            }
        }
        return nil
    }
    
    func setupLayout() {
        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumInteritemSpacing=0
            layout.minimumLineSpacing=0
            layout.scrollDirection = .horizontal
            
            layout.itemSize = self.collectionView.frame.size
        }
    }
    
    func setupCollectionView() {
        collectionView.register(PhotoViewerCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.isPagingEnabled = true
    }
    
    override func viewDidLoad() { // 객체가 메모리에 올라간 다음에 , 뷰 디드 로이드가 된다음에 창이 보인다.
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        //상단 바
        self.title = "Viewer".localized()
        
        if #available(iOS 11.0, *) {
            self.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        //setup layout
        setupLayout()
        
        //setup ViewerCollectionView
        setupCollectionView()
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.hidesBarsOnTap = true //allow hiding bar
        collectionView.reloadData()
        collectionView.scrollToItem(at: photoOffset, at: .left , animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    
    @objc func dismissView() {
        navigationController?.popViewController(animated: true)
        self.navigationController?.hidesBarsOnTap = false //allow hiding bar
    }
}


extension PhotoViewerViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 리유저블 셀의 정의
        let cell=collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoViewerCell
        
        cell.imageView.image = getPhotoViewerViewCache(indexPath: indexPath)
        
        return cell
    }
}
