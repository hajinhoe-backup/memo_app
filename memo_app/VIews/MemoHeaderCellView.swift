//
//  MemoHeaderCellView.swift
//  memo_app
//
//  Created by jinho on 2020/02/11.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

class MemoHeaderCellView: UICollectionReusableView {
    /* 레이아웃 상 최상위 스택 뷰 정의 및 설정 */
    let verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        return verticalStackView
    }()
    
    func setupVerticalStackView(_ verticalStackView: UIStackView) {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            verticalStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            verticalStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            verticalStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ])
        
        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(titleView)
        verticalStackView.addArrangedSubview(textLabel)
        verticalStackView.addArrangedSubview(textView)
        
        
        verticalStackView.addArrangedSubview(imageCollectionBar)
        setupImageCollectionBar(imageCollectionBar)
        
    }
    
    /* 스텍 뷰 하위의 타이틀 쓰는 곳 정의 및 설정 */
    let titleLabel: UILabel = {
       let titleLabel = UILabel()
        titleLabel.text = "Title"
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .gray
        return titleLabel
    }()
    
    let titleView: UITextView = {
        let titleView = UITextView()
        titleView.font = UIFont.boldSystemFont(ofSize: 24)
        titleView.isScrollEnabled = false
        titleView.backgroundColor = UIColor(red: CGFloat(242)/CGFloat(255), green: CGFloat(242)/CGFloat(255), blue: CGFloat(247)/CGFloat(255), alpha: 1) // iOS13+에서 .systemgray6 지원
        titleView.layer.cornerRadius = 10
        titleView.clipsToBounds = true
        titleView.tag = 0
        return titleView
    }()
    
    
    func setupTitleView(_ titleView: UIView) {
        /* 미 이용 함수*/
    }
    
    /* 본문 란 정의 및 설정 */
    let textLabel: UILabel = {
        let label = UILabel()
        label.text = "Content"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor(red: CGFloat(242)/CGFloat(255), green: CGFloat(242)/CGFloat(255), blue: CGFloat(247)/CGFloat(255), alpha: 1) // iOS13+에서 .systemgray6 지원
        textView.layer.cornerRadius = 10
        textView.clipsToBounds = true
        textView.tag = 1
        return textView
    }()
    
    
    /* 아래의 뷰들은 이미지 뷰들의 바로 위에 나오게 되는 뷰 입니다.
     아래에 이미지가 있다는 정보를 줌과 동시에 Edit모드에서는 add 버튼이 보이게 됩니다. */
    let imageCollectionBar: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    func setupImageCollectionBar(_ imageCollectionBar: UIStackView) {
        imageCollectionBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageCollectionBar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        imageCollectionBar.frame = CGRect(x: 0, y: 0, width: imageCollectionBar.frame.width, height: 40)
        
        imageCollectionBar.addArrangedSubview(imageCollectionBarHeader)
        imageCollectionBar.addArrangedSubview(imageCollectionBarAddButton)
        setupImageCollectionBarAddButton(imageCollectionBarAddButton)
    }
    
    let imageCollectionBarHeader: UILabel = {
        let label = UILabel()
        label.text = "Images"
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let imageCollectionBarAddButton: UIButton = { // 이미지 추가 버튼, 글 편집 시에만 보이게 됩니다.
        let button = UIButton()
        button.backgroundColor = .orange
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.setTitle("Add", for: .normal)
        return button
    }()
    
    func setupImageCollectionBarAddButton(_ button: UIButton) {
        let widthConstraint = button.widthAnchor.constraint(equalToConstant: 50)
        widthConstraint.priority = UILayoutPriority(999) // ishidden 속성으로 감추기를 할 때, priority 충돌로 인해 레이아웃이 충돌나므로 설정
        widthConstraint.isActive = true
        
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 40)
        heightConstraint.isActive = true
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(verticalStackView)
        setupVerticalStackView(verticalStackView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
