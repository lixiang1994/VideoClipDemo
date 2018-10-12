//
//  LoadingRotateView.swift
//  LiveTrivia
//
//  Created by 李响 on 2018/8/15.
//  Copyright © 2018年 LiveTrivia. All rights reserved.
//

import UIKit
import SnapKit

class LoadingRotateView: UIView {
    
    lazy var indicator: UIImageView = {
        $0.image = #imageLiteral(resourceName: "loading")
        $0.alpha = 0.0
        $0.backgroundColor = .clear
        return $0
    } ( UIImageView() )
    lazy var reloadButton: UIButton = {
        $0.isHidden = true
        $0.setTitle("加载失败, 点击重试", for: .normal)
        $0.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        $0.addTarget(self, action: #selector(reloadAction), for: .touchUpInside)
        return $0
    } ( UIButton() )
    
    private var reload: (()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
        setupLayout()
    }
    
    private func setup() {
        isHidden = true
        
        addSubview(indicator)
        addSubview(reloadButton)
    }
    
    private func setupLayout() {
        
        indicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        reloadButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}

extension LoadingRotateView {
    
    func set(image: UIImage) {
        indicator.image = image
    }
    
    func set(size: CGFloat) {
        indicator.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(size)
        }
        layoutIfNeeded()
    }
}

extension LoadingRotateView: Loadingable {
    
    func start() {
        isHidden = false
        addAnimation()
        indicator.alpha = 1.0
        reloadButton.isHidden = true
    }
    
    func stop() {
        isHidden = true
        indicator.alpha = 0.0
        removeAnimation()
        reloadButton.isHidden = true
    }
    
    func failure() {
        isHidden = false
        indicator.alpha = 0.0
        removeAnimation()
        reloadButton.isHidden = false
    }
    
    func reload(_ handle: @escaping (() -> Void)) {
        reload = handle
    }
}

extension LoadingRotateView {
    
    @objc private func reloadAction(_ sender: UIButton) {
        sender.isHidden = true
        reload?()
    }
}

extension LoadingRotateView {
    
    private func addAnimation() {
        guard indicator.layer.animation(forKey: "loading") == nil else {
            return
        }
        let animation = CABasicAnimation()
        animation.keyPath = "transform.rotation.z"
        animation.fromValue = 0
        animation.toValue = 360 * CGFloat(CGFloat.pi / 180)
        animation.duration = 0.9
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        indicator.layer.add(animation, forKey: "loading")
    }
    
    private func removeAnimation() {
        indicator.layer.removeAllAnimations()
    }
}
