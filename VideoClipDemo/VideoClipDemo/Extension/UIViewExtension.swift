//
//  UIViewExtension.swift
//  VideoClipDemo
//
//  Created by 李响 on 2018/10/12.
//  Copyright © 2018 swift. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func startLoading(_ activityIndicatorStyle: UIActivityIndicatorView.Style = .white) {
        stopLoading()
        
        let maskView = UIImageView(frame: bounds)
        
        addSubview(maskView)
        maskView.tag = 1994
        
        if let button = self as? UIButton {
            button.titleLabel?.alpha = 0.0
            button.imageView?.alpha = 0.0
            button.titleLabel?.isHidden = true
            button.imageView?.isHidden = true
            maskView.image = button.currentBackgroundImage
        }
        maskView.backgroundColor = backgroundColor
        
        let load = UIActivityIndicatorView(style: activityIndicatorStyle)
        
        maskView.addSubview(load)
        load.center = maskView.center
        load.startAnimating()
        
        isUserInteractionEnabled = false
    }
    
    func stopLoading() {
        guard let maskView = viewWithTag(1994) else { return }
        
        if let button = self as? UIButton {
            button.titleLabel?.alpha = 1.0
            button.imageView?.alpha = 1.0
            button.titleLabel?.isHidden = false
            button.imageView?.isHidden = false
        }
        maskView.removeFromSuperview()
        
        isUserInteractionEnabled = true
    }
}
