//
//  Loading.swift
//  LiveTrivia
//
//  Created by 李响 on 2018/8/15.
//  Copyright © 2018年 LiveTrivia. All rights reserved.
//

import Foundation
import UIKit

protocol Loadingable: NSObjectProtocol {
    
    var reloadButton: UIButton { get }
    
    func start()
    
    func stop()
    
    func failure()
    
    func reload(_ handle: @escaping (()->Void))
}

typealias LoadingView = (UIView & Loadingable)

enum Loading {}

extension Loading {
    
    enum State {
        case loading
        case success
        case failure
    }
    
    enum Style {
        case system(UIActivityIndicatorView.Style)
        case rotate(UIImage, CGFloat)
        case circle(UIColor, CGFloat)
        case custom(UIView)
    }
}

extension Loading {
    
    static func view<T: LoadingView>(_ style: Style) -> T {
        return view(style) as! T
    }
    
    static func view(_ style: Style) -> LoadingView {
        
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        switch style {
        case .system(let style):
            let temp = LoadingSystemView(frame: defaultRect)
            temp.set(style: style)
            return temp
            
        case .rotate(let image, let size):
            let temp = LoadingRotateView(frame: defaultRect)
            temp.set(image: image)
            temp.set(size: size)
            return temp
            
        case .circle(let color, let size):
            let temp = LoadingCircleView(frame: defaultRect)
            temp.set(color: color)
            temp.set(size: size)
            return temp
            
        case .custom(let view):
            let temp = LoadingCustomView(frame: defaultRect)
            temp.set(view: view)
            return temp
        }
    }
}
