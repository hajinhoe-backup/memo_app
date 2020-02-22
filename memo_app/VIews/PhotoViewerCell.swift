//
//  ImageViewerCell.swift
//  memo_app
//
//  Created by jinho on 2020/02/20.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

/* 포토 뷰어의 셀 입니다. */
class PhotoViewerCell: UICollectionViewCell, UIScrollViewDelegate {
    let imageView = UIImageView()
    let imageScrollView = UIScrollView()
    
    func setupImageView() {
        self.imageView.contentMode = .scaleAspectFit
    }
    
    func setupImageScrollView() {
        self.imageScrollView.delegate = self
        self.imageScrollView.alwaysBounceVertical = false
        self.imageScrollView.alwaysBounceHorizontal = false
        
        self.imageScrollView.showsHorizontalScrollIndicator = false
        self.imageScrollView.showsVerticalScrollIndicator = false
        
        self.imageScrollView.minimumZoomScale = 1.0
        self.imageScrollView.maximumZoomScale = 3.0
        
        self.imageScrollView.addSubview(self.imageView)
        setupImageView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.imageScrollView)
        setupImageScrollView()
    }
    
    override func layoutSubviews() { // 하위뷰의 레이아웃을 재정의
        super.layoutSubviews()
        self.imageScrollView.frame = self.bounds
        self.imageView.frame = self.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
