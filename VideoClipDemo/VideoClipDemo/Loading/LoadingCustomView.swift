//
//  LoadingCustomView.swift
//  LiveTrivia
//
//  Created by 李响 on 2018/8/16.
//  Copyright © 2018年 LiveTrivia. All rights reserved.
//

import UIKit
import SnapKit

class LoadingCustomView: UIView {
    
    lazy var indicator: UIView = UIView()
    
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

extension LoadingCustomView {
    
    func set(view: UIView) {
        indicator.removeFromSuperview()
        indicator = view
        addSubview(indicator)
        
        indicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}

extension LoadingCustomView: Loadingable {
    
    func start() {
        isHidden = false
        reloadButton.isHidden = true
    }
    
    func stop() {
        isHidden = true
        reloadButton.isHidden = true
    }
    
    func failure() {
        isHidden = false
        reloadButton.isHidden = false
    }
    
    func reload(_ handle: @escaping (() -> Void)) {
        reload = handle
    }
}

extension LoadingCustomView {
    
    @objc private func reloadAction(_ sender: UIButton) {
        sender.isHidden = true
        reload?()
    }
}
