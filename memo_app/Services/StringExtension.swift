//
//  StringExtension.swift
//  memo_app
//
//  Created by jinho on 2020/02/16.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation

/* 현지화 편의를 위해 String 클래스에 추가 함수를 더합니다. */

extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String
{
        return NSLocalizedString(self, tableName: tableName, value: self, comment: "")
    }
}
