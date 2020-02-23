//
//  PhotoViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/20.
//  Copyright © 2020 jinho. All rights reserved.
//

/* 이미지 뷰어입니다. */
/* 핀치 투 줌, 넘겨 집기 등이 가능합니다. */
/* 트랜지션일 때, 처리를 최대한 해보았는데, 기본 사진 어플리케이션 만큼 스무스 하지는 못 합니다. 조금 더 기교가 필요할 듯. */
import UIKit

class PhotoViewerViewController: UICollectionViewController {
    let thumbnailCache = ImageCacheManager.manager.thumnailCache // 썸네일 캐시
    let originalCache = ImageCacheManager.manager.originalCache // 오리지날 캐시
    
    var photos: [Photo] = []
    
    var photoOffset = IndexPath()
    
    let imageFileManager = ImageFileManager()
    
    func getPhotoViewerViewCache(indexPath: IndexPath) -> UIImage? {
        if indexPath.item < photos.count { // 영원하게 저장되어 있는 경우
            let url = photos[indexPath.item].url
            
            if let cachedImage = originalCache.object(forKey: url as NSString) { // 원본 이미지 캐시에 저장됨.
                return cachedImage
            }
            
            // 원본 이미지 없는 경우 다른 쓰레드에서 오리지날 이미지 가져옴.
            DispatchQueue.global(qos: .userInitiated).async {
                //고화질 이미지를 가져온다.
                if let originalImage = self.imageFileManager.getSavedImage(named: url, directory: .original) {
                    self.originalCache.setObject(originalImage, forKey: url as NSString)
                    DispatchQueue.main.async {
                        //고화질 이미지를 가져온 후 업데이트 한다.
                        self.collectionView.reloadData()
                    }
                }
            }
            
            // 썸네일 캐시 요청
            if let cachedImage = thumbnailCache.object(forKey: url as NSString) { // 원본 이미지 캐시에 저장됨.
                return cachedImage
            }
            
            // 썸네일 캐시도 없는 경우 요청 후 디스패치 큐로 썸네일 저장하고 바로 반환
            if let thumbnailImage = self.imageFileManager.getSavedImage(named: url, directory: .thumbnail) {
                DispatchQueue.global().async {
                    self.thumbnailCache.setObject(thumbnailImage, forKey: url as NSString)
                }
                return thumbnailImage
            }
        }
        
        // 데이터를 찾을 수 없는 경우
        return UIImage(imageLiteralResourceName: "imageError") // 이미지 없음 표시
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
        navigationController?.hidesBarsOnTap = true //allow hiding bar
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        collectionView.reloadData()
        collectionView.scrollToItem(at: photoOffset, at: .left , animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let offset = photoOffset
        
        coordinator.animate(alongsideTransition: .none) { _ in
            if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.itemSize = size
                if let cell = self.collectionView.cellForItem(at: offset) as? PhotoViewerCell {
                    cell.imageScrollView.frame = self.collectionView.bounds
                    cell.imageView.frame = self.collectionView.bounds
                    cell.imageScrollView.setZoomScale(1.0, animated: true)
                }
                self.collectionView.selectItem(at: offset, animated: false, scrollPosition: .left)
                layout.invalidateLayout()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 리유저블 셀의 정의
        let cell=collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoViewerCell
        
        cell.imageView.image = getPhotoViewerViewCache(indexPath: indexPath)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let willDisplayCell = cell as! PhotoViewerCell
        willDisplayCell.imageScrollView.setZoomScale(1.0, animated: false)
    }
}


extension PhotoViewerViewController {
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    @objc func dismissView() {
        navigationController?.popViewController(animated: true)
        self.navigationController?.hidesBarsOnTap = false //allow hiding bar
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            photoOffset = indexPath
        }
    }
}
