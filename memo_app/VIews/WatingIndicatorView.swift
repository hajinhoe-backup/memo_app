//
//  watingIndicatorView.swift
//  memo_app
//
//  Created by jinho on 2020/02/16.
//  Copyright © 2020 jinho. All rights reserved.
//

import Foundation


extension UIViewController {
    func showSpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    func removeSpinner(view:UIView) {
        DispatchQueue.main.async {
            view.removeFromSuperview()
        }
    }
}
