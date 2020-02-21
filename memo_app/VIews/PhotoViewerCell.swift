//
//  ImageViewerCell.swift
//  memo_app
//
//  Created by jinho on 2020/02/20.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

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
        self.imageScrollView.showsVerticalScrollIndicator = true
        self.imageScrollView.flashScrollIndicators()
        
        self.imageScrollView.minimumZoomScale = 1.0
        self.imageScrollView.maximumZoomScale = 3.0
        
        self.imageScrollView.addSubview(self.imageView)
        setupImageView()
    }
    
         
    
    //음 동작이 좀 아쉽긴한데 되긴되네.
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.imageScrollView)
        setupImageScrollView()

        
    }
    
    override func layoutSubviews() { // 하위뷰의 레이아웃을 재정의
        //원래 쓰면 안됨. 고쳐야함.
        super.layoutSubviews()
        print(self.bounds)
        self.imageScrollView.frame = self.bounds
        self.imageView.frame = self.bounds
        //self.frame = CGRect(origin: CGPoint(x: self.frame.origin.x, y: 0), size: CGSize(width: 375.0, height: 600.0))
        
        //print(self.imageScrollView.bounds)
        ////print(self.imageScrollView.frame)
//print(self.imageView.bounds)
        //print(self.imageView.frame)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageScrollView.setZoomScale(1, animated: true)
    }
    

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
