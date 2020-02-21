//
//  SettingViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/19.
//  Copyright © 2020 jinho. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        navigationItem.title = "Setting".localized() //현지화필요
        //아이콘 라이선스로 인해 아이콘 제공 홈페이지 링크해야함
        //https://icons8.com/license
        //https://icons8.com/license
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let switchView = UISwitch(frame: .zero)
        switchView.setOn(false, animated: true)
        switchView.tag = indexPath.row // for detect which row switch Changed
        //switchView.addTarget(self, action: nil, for: .valueChanged)
        /*
         원본 이미지 보기
         원본 이미지가 저장되어 있는 경우 이미지 썸네일을 클릭했을 때, 원본 이미지를 보여줍니다.
         원본 이미지 저장
         이미지를 저장할 떄, 리사이즈된 이미지 뿐 만이 아닌 원본 이미지도 저장됩니다. (원본이미지를 항상 디스크에 올리고, 만약 도중에 삭제되면 지우는 식으로.... 저장하지 않고 네비게이션 백 버튼을 눌럿을 때 지우는 동작이 필요함. didrecevieedlow메모리로 처리하는 방법도 있을 듯 하지만 애매하다...)
         */
        cell.accessoryView = switchView

        return cell
    }
}
