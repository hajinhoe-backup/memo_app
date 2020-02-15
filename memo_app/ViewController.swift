//
//  ViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let memoNavgationController = UINavigationController()
    let memoLIstViewController = MemoListViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    /* 호환 편리를 위해서 최상단 뷰에서 작성한 뷰를 생성하여 불러옵니다. */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        self.memoNavgationController.setViewControllers([memoLIstViewController], animated: false)
        self.memoNavgationController.modalPresentationStyle = .fullScreen
        self.present(memoNavgationController, animated: false, completion: nil)
    }
}

