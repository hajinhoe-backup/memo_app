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
    let settingViewController = SettingViewController(style: .grouped)
    
    let appTabBarController = UITabBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    /* 호환 편리를 위해서 최상단 뷰에서 작성한 뷰를 생성하여 불러옵니다. */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.memoNavgationController.setViewControllers([memoLIstViewController], animated: false)
        
        self.memoNavgationController.modalPresentationStyle = .fullScreen
        
present(memoNavgationController, animated: false, completion: nil)
        /*
        memoNavgationController.tabBarItem = UITabBarItem(tabBarSystemItem: .bookmarks, tag: 0)
        memoNavgationController.tabBarItem.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        settingViewController.tabBarItem = UITabBarItem(title: <#T##String?#>, image: , tag: <#T##Int#>)
        
        appTabBarController.modalPresentationStyle = .fullScreen
        //tapp.tabBar.setItems([UITabBarItem(tabBarSystemItem: .bookmarks, tag: 0)], animated: false)
        appTabBarController.setViewControllers([memoNavgationController, settingViewController], animated: true)
        present(appTabBarController, animated: false, completion: nil)
        */
        
 
    }
}

