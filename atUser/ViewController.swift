//
//  ViewController.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(textFieldButton)
        view.addSubview(textViewButton)
    }
    
    
    @objc func textFieldButtonAction(_ btn: UIButton) {
        
        let vc = TextFieldViewController.init()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func textViewButtonAction(_ btn: UIButton) {
        
        let vc = TextViewController.init()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    
    lazy var textFieldButton: UIButton = {
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 100, y: 100, width: 200, height: 50)
        button.addTarget(self, action: #selector(textFieldButtonAction(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("UITextField添加@事件", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    
    
    lazy var textViewButton: UIButton = {
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        button.addTarget(self, action: #selector(textViewButtonAction(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitle("UITextView添加@事件", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    
//    lazy var a: UITextField
//    lazy var a: UITextView
}

