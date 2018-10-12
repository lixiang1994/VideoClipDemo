//
//  LoadingCircleView.swift
//  LiveTrivia
//
//  Created by 李响 on 2018/8/15.
//  Copyright © 2018年 LiveTrivia. All rights reserved.
//

import UIKit
import SnapKit

class LoadingCircleView: UIView {

    lazy var indicator: CAShapeLayer = {
        $0.strokeColor = UIColor.white.cgColor
        $0.fillColor = UIColor.clear.cgColor
        $0.lineWidth = 2
        $0.lineCap = CAShapeLayerLineCap.round
        $0.bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        return $0
    } ( CAShapeLayer() )
    lazy var reloadButton: UIButton = {
        $0.isHidden = true
        $0.setTitle("加载失败, 点击重试", for: .normal)
        $0.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        $0.addTarget(self, action: #selector(reloadAction), for: .touchUpInside)
        return $0
    } ( UIButton() )
    
    private var reload: (()->Void)?
    private var duration: TimeInterval = 1.5
    private var timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    
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
        
        layer.addSublayer(indicator)
        addSubview(reloadButton)
    }
    
    private func setupLayout() {
        
        reloadButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        indicator.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let center = CGPoint(x: indicator.bounds.midX, y: indicator.bounds.midY)
        let radius = min(indicator.bounds.midX,
                         indicator.bounds.midX - indicator.lineWidth / 2)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        indicator.path = path.cgPath
    }
}

extension LoadingCircleView {
    
    /// 设置颜色
    ///
    /// - Parameter color: 颜色
    func set(color: UIColor) {
        indicator.strokeColor = color.cgColor
    }
    
    /// 设置大小
    ///
    /// - Parameter size: 大小
    func set(size: CGFloat) {
        indicator.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        layoutSubviews()
    }
    
    /// 设置线条宽度
    ///
    /// - Parameter line: 宽度
    func set(line: CGFloat) {
        indicator.lineWidth = line
        layoutSubviews()
    }
    
    /// 设置动画时长
    ///
    /// - Parameter duration: 时长
    func set(duration: TimeInterval) {
        self.duration = duration
        removeAnimation()
        addAnimation()
    }
    
    /// 设置动画曲线
    ///
    /// - Parameter timingFunction: 默认 EaseInEaseOut
    func set(timingFunction: CAMediaTimingFunction) {
        self.timingFunction = timingFunction
        removeAnimation()
        addAnimation()
    }
}

extension LoadingCircleView: Loadingable {
    
    func start() {
        isHidden = false
        addAnimation()
        indicator.opacity = 1.0
        reloadButton.isHidden = true
    }
    
    func stop() {
        isHidden = true
        indicator.opacity = 0.0
        removeAnimation()
        reloadButton.isHidden = true
    }
    
    func failure() {
        isHidden = false
        indicator.opacity = 0.0
        removeAnimation()
        reloadButton.isHidden = false
    }
    
    func reload(_ handle: @escaping (() -> Void)) {
        reload = handle
    }
}

extension LoadingCircleView {
    
    @objc private func reloadAction(_ sender: UIButton) {
        sender.isHidden = true
        reload?()
    }
}

extension LoadingCircleView {
    
    private func addAnimation() {
        guard indicator.animation(forKey: "A") == nil else {
            return
        }
        
        let animation = CABasicAnimation()
        animation.keyPath = "transform.rotation"
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration / 0.375
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        indicator.add(animation, forKey: "A")
        
        let headAnimation = CABasicAnimation()
        headAnimation.keyPath = "strokeStart"
        headAnimation.fromValue = 0
        headAnimation.toValue = 0.25
        headAnimation.duration = duration / 1.5
        headAnimation.timingFunction = timingFunction
        
        let tailAnimation = CABasicAnimation()
        tailAnimation.keyPath = "strokeEnd"
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1
        tailAnimation.duration = duration / 1.5
        tailAnimation.timingFunction = timingFunction
        
        let endHeadAnimation = CABasicAnimation()
        endHeadAnimation.keyPath = "strokeStart"
        endHeadAnimation.fromValue = 0.25
        endHeadAnimation.toValue = 1
        endHeadAnimation.beginTime = duration / 1.5
        endHeadAnimation.duration = duration / 3.0
        endHeadAnimation.timingFunction = timingFunction
        
        let endTailAnimation = CABasicAnimation()
        endTailAnimation.keyPath = "strokeEnd"
        endTailAnimation.fromValue = 1
        endTailAnimation.toValue = 1
        endTailAnimation.beginTime = duration / 1.5
        endTailAnimation.duration = duration / 3.0
        endTailAnimation.timingFunction = timingFunction
        
        let animations = CAAnimationGroup()
        animations.duration = duration
        animations.animations = [headAnimation, tailAnimation,
                                 endHeadAnimation, endTailAnimation]
        animations.repeatCount = HUGE
        animations.isRemovedOnCompletion = false
        indicator.add(animations, forKey: "B")
    }
    
    private func removeAnimation() {
        indicator.removeAllAnimations()
    }
}
