//
//  MemoPhotoItemCellWithDeleteButtonView.swift
//  memo_app
//
//  Created by jinho on 2020/02/11.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

class ButtonWithIndexPath: UIButton {
    var indexPath: IndexPath?
}

class MemoPhotoItemCellWithDeleteButtonView: UICollectionViewCell {
    var isEditMode = false
    
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
            cellStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ])
        
        cellStackView.addArrangedSubview(imageView)
        setupImageView(imageView)
        cellStackView.addArrangedSubview(deleteButton)
        
        
        
    }
    
    let imageView: UIImageView = {
        //실패하는 경우 임시 이미지를 보여줘야 한다.
        let imageView = UIImageView()
        imageView.image = UIImage(named: "testimage")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        //imageView.frame =
        //print(self.frame)
        return imageView
    }()
    
    func setupImageView(_ imageView: UIImageView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
        //    imageView.heightAnchor.constraint(equalToConstant: self.frame.width),
            imageView.heightAnchor.constraint(equalToConstant: 150),
        ])
        //imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 100)
    }
    
    let deleteButton: ButtonWithIndexPath = {
       let deleteButton = ButtonWithIndexPath()
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.layer.cornerRadius = 10
        deleteButton.clipsToBounds = true
        return deleteButton
    }()
    
    @objc func handleNewJob() {
        print("나얌")
        
        isEditMode = !isEditMode
        
        if isEditMode {
            cellStackView.addArrangedSubview(deleteButton)
        } else {
            cellStackView.removeArrangedSubview(deleteButton)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //addSubview(imageView)
        addSubview(cellStackView)
        setupCellStackView(cellStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
