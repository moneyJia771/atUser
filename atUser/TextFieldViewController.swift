//
//  TextFieldViewController.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//

import UIKit

class TextFieldViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(headerView)
    }
    
    
    lazy var headerView: NavBarView = {
        let a = NavBarView.init(frame: CGRect(x: 0, y: MVStatusScreenHeight, width: self.view.frame.size.width, height: 44))
        a.titleLabel.text = "UITextField添加@事件"
        a.vc = self
        return a
    } ()
    
}
