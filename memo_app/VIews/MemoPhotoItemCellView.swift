//
//  MemoPhotoItemCellWithDeleteButtonView.swift
//  memo_app
//
//  Created by jinho on 2020/02/11.
//  Copyright © 2020 jinho. All rights reserved.
//

/*
 메모 하단에 보여지는 포토들의 셀 뷰입니다.
 보기/편집 모드에 따라 delete 버튼을 숨기고 표시합니다.
 */
import UIKit

class ButtonWithIndexPath: UIButton {
    var indexPath: IndexPath?
}

class MemoPhotoItemCellView: UICollectionViewCell {
    let cellStackView: UIStackView = {
        let cellStackView = UIStackView()
        cellStackView.axis = .vertical
        cellStackView.distribution = .fillProportionally
        cellStackView.alignment = .fill
        cellStackView.spacing = 1
        return cellStackView
    }()
    
    func setupCellStackView(_ cellStackView: UIStackView) {
        cellStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cellStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            cellStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            cellStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            cellStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
        ])
        
        cellStackView.addArrangedSubview(imageView)
        setupImageView(imageView)
        cellStackView.addArrangedSubview(deleteButton)
    }
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "broken") // 임시 이미지, 실패 이미지이기도 함.
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Added Image".localized()
        return imageView
    }()
    
    func setupImageView(_ imageView: UIImageView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 150),
        ])
    }
    
    let deleteButton: ButtonWithIndexPath = {
        let deleteButton = ButtonWithIndexPath()
        deleteButton.setTitle("Delete".localized(), for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.layer.cornerRadius = 10
        deleteButton.clipsToBounds = true
        deleteButton.isAccessibilityElement = true
        deleteButton.accessibilityHint = "Removes Image at Upside".localized()
        return deleteButton
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(cellStackView)
        setupCellStackView(cellStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
