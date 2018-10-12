//
//  LoadingSystemView.swift
//  LiveTrivia
//
//  Created by 李响 on 2018/8/15.
//  Copyright © 2018年 LiveTrivia. All rights reserved.
//

import UIKit
import SnapKit

class LoadingSystemView: UIView {

    lazy var indicator: UIActivityIndicatorView = {
        $0.style = .gray
        $0.hidesWhenStopped = true
        return $0
    } ( UIActivityIndicatorView() )
    
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

extension LoadingSystemView {
    
    func set(style: UIActivityIndicatorView.Style) {
        indicator.style = style
    }
}

extension LoadingSystemView: Loadingable {
    
    func start() {
        isHidden = false
        indicator.startAnimating()
        reloadButton.isHidden = true
    }
    
    func stop() {
        isHidden = true
        indicator.stopAnimating()
        reloadButton.isHidden = true
    }
    
    func failure() {
        isHidden = false
        indicator.stopAnimating()
        reloadButton.isHidden = false
    }
    
    func reload(_ handle: @escaping (() -> Void)) {
        reload = handle
    }
}

extension LoadingSystemView {
    
    @objc private func reloadAction(_ sender: UIButton) {
        sender.isHidden = true
        reload?()
    }
}
