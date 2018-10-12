//
//  UIImageExtension.swift
//  VideoClipDemo
//
//  Created by 李响 on 2018/10/12.
//  Copyright © 2018 swift. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func scaled(toHeight: CGFloat, opaque: Bool = false) -> UIImage? {
        let scale = toHeight / size.height
        let newWidth = size.width * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: toHeight), opaque, 0)
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: toHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
