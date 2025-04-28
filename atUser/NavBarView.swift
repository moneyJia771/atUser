//
//  NavBarView.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//

import Foundation
import UIKit

/// 顶部状态栏高度（包括安全区）
let MVStatusScreenHeight: CGFloat = {
    var statusBarHeight: CGFloat = 0
    if #available(iOS 13.0, *) {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let statusBarManager = windowScene.statusBarManager else { return 0 }
        statusBarHeight = statusBarManager.statusBarFrame.height
    } else {
        statusBarHeight = UIApplication.shared.statusBarFrame.height
    }
    return statusBarHeight
}()

class NavBarView: UIView {
    
    weak var vc: UIViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(backButton)
        self.addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func backButtonAction(_ btn: UIButton) {
     
        if let vc = vc {
            vc.dismiss(animated: true)
        }
    }
    
    lazy var titleLabel: UILabel = {
       
        let titleLabel = UILabel.init()
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: (self.frame.size.width - 200)/2.0, y: 0, width: 200, height: 44)
        return titleLabel
    } ()
    
    
    lazy var backButton: UIButton = {
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
        button.addTarget(self, action: #selector(backButtonAction(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("返回", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
}
