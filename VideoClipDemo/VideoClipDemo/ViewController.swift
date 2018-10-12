//
//  ViewController.swift
//  VideoClipDemo
//
//  Created by 李响 on 2018/10/12.
//  Copyright © 2018 swift. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        let vc = VideoPickerViewController.instance()
        let nc = UINavigationController(rootViewController: vc)
        nc.setNavigationBarHidden(true, animated: false)
        present(nc, animated: true)
    }
}

