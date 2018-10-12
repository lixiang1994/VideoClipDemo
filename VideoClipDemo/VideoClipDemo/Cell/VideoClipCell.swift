//
//  VideoClipCell.swift
//  LiveTrivia
//
//  Created by iOS on 2018/7/31.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit

class VideoClipCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func set(image: UIImage?) {
        imageView.image = image
    }
}
