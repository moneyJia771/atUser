//
//  TextViewController.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//


import UIKit

class TextViewController1: UIViewController {
    
    /// @人数组
    var selectedPersonArray: [BCAtUserInfoModel] = [BCAtUserInfoModel]()
    
    /// 输入框内容修改 增加或者删除
    private var isAddText = false
    /// 是否是删除，当删除时为 true ，为了区分中文输入删除完预输入内容 和 中文输入用户确定的内容
    private var isDeleteText = false
    private var changgeRange: NSRange?
    private var addText = ""
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(headerView)
        
        self.view.addSubview(textView)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(mv_textChange(_:)), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    
    lazy var headerView: NavBarView = {
        let a = NavBarView.init(frame: CGRect(x: 0, y: MVStatusScreenHeight, width: self.view.frame.size.width, height: 44))
        a.titleLabel.text = "UITextView添加@事件"
        a.vc = self
        return a
    } ()
    
    lazy var textView: UITextView = {
        
        let view = UITextView.init(frame: CGRect(x: 20, y: 200, width: self.view.frame.size.width - 40, height: 200))
        view.delegate = self
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.textColor = .black
        return view
    } ()
    
}

extension TextViewController1 {
    
    
    /// @人点击
    @objc func selectPersonAction() {
        
        let vc = ChooseUserVC.init()
        vc.selectBlock = { [weak self] data in
            
            guard let self = self else {return}
            
            guard let userInfoModel = data as? BCUserInfoModel else {
                return
            }
            
            self.textView.unmarkText()
            
            // 获取当前光标位置，而不是文本末尾
            let index = self.textView.selectedRange.location
            
            let atStr: String = "@\(userInfoModel.BCuserName)"
            
            let atUserInfoModel = BCAtUserInfoModel.init()
            atUserInfoModel.userId = userInfoModel.BCuid
            atUserInfoModel.userName = userInfoModel.BCuserName
            atUserInfoModel.startIndex = index
            atUserInfoModel.endIndex = atStr.utf16.count + index
            self.selectedPersonArray.append(atUserInfoModel)
            
            // 在光标位置插入文本，而不是追加到末尾
            let currentText = self.textView.text ?? ""
            let nsText = NSMutableString(string: currentText)
            nsText.insert(atStr, at: index)
            self.textView.text = nsText as String
            
            // 更新光标位置到插入的@用户名之后
            self.textView.selectedRange = NSRange(location: index + atStr.utf16.count, length: 0)
            
            // 更新所有在插入位置之后的@用户名的位置信息
            for model in self.selectedPersonArray where model !== atUserInfoModel {
                if model.startIndex >= index {
                    model.startIndex += atStr.utf16.count
                    model.endIndex += atStr.utf16.count
                }
            }
            
            self.hightAtUserName()
            
//            self.inputBarBecomeFirstResponder()
            
//            self.isSelect = false
        }
        vc.leftCallBack = { [weak self] in
            /// 返回时增加 艾特符号
            
            guard let self = self else {return}
            
            self.isAddText = false
            
            // 获取当前光标位置
            let cursorPosition = self.textView.selectedRange.location
            
            // 在光标位置插入@符号
            let currentText = self.textView.text ?? ""
            let nsText = NSMutableString(string: currentText)
            nsText.insert("@", at: cursorPosition)
            self.textView.text = nsText as String
            
            // 更新光标位置到@符号之后
            self.textView.selectedRange = NSRange(location: cursorPosition + 1, length: 0)
            
            // 更新所有在插入位置之后的@用户名的位置信息
            for model in self.selectedPersonArray {
                if model.startIndex >= cursorPosition {
                    model.startIndex += 1
                    model.endIndex += 1
                }
            }
            
            self.hightAtUserName()
            
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
//                self.inputBarBecomeFirstResponder()
//            }
        }
        self.present(vc, animated: true)
        
    }
    
    
    @objc func hightAtUserName() {
        
        /// 当有预输入时不使用富文本，否则中文第一个字母处理不了
        if let markedTextRange = textView.markedTextRange {
            if let newText = textView.text(in: markedTextRange) {
                if newText.isEmpty == false {
                    return
                }
            }
        }
        
        
        // 高亮输入框中的@
        let range = textView.selectedRange
        
        let newCurrentText = textView.text ?? ""
        
        let attriStr = NSMutableAttributedString(string: newCurrentText)
        attriStr.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: attriStr.string.utf16.count))
        attriStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSRange(location: 0, length: attriStr.string.utf16.count))
        
        var newPersonArray = [BCAtUserInfoModel]()
        
        selectedPersonArray.forEach { userInfoModel in
            
            let range = NSRange.init(location: userInfoModel.startIndex, length: userInfoModel.endIndex - userInfoModel.startIndex)
            
            /// 做容错处理，当遇到越界的情况就忽略掉这条有问题的艾特数据
            if range.length <= attriStr.string.utf16.count - range.location {
                attriStr.addAttribute(.foregroundColor, value: UIColor.red, range: range)
                newPersonArray.append(userInfoModel)
            }
        }
        
        selectedPersonArray.removeAll()
        selectedPersonArray = newPersonArray
        
        
        let offset = textView.attributedText.length - attriStr.length
        textView.attributedText = attriStr
        textView.selectedRange = NSRange(location: range.location - offset, length: 0)
        //        textView.selectedRange = range
        
        
        ///结束后状态需要调整
        let markedTextRange2 = textView.markedTextRange
        if let _ = markedTextRange2 {
            
        } else {
            self.isAddText = false
        }
        
    }
    
    func deleteAtUser(range: NSRange) -> Bool {
        
        var selectedModels = [BCAtUserInfoModel]()
        
        var newRange = range
        
        var isLocation = false
        
        var selectStart = 0
        
        for atUserModel in self.selectedPersonArray {
            
            let start = atUserModel.startIndex
            let end = atUserModel.endIndex
            
            let location = range.location
            let length = range.length
            
            ///删除前的艾特信息不需修改
            if location >= end {
                selectedModels.append(atUserModel)
                continue
            }
            
            ///删除后的位置需要调整
            if location + length <= start {
                
                atUserModel.startIndex = start - newRange.length
                atUserModel.endIndex = end - newRange.length
                selectedModels.append(atUserModel)
                continue
            }
            
            if location < end, isLocation == false {
                selectStart = location < start ? location : start
                newRange.location = selectStart
                isLocation = true
            }
            
            if location + length > start {
                newRange.length = location + length > end ? location + length - selectStart : end - selectStart
            }
        }
        
        if self.selectedPersonArray.count == selectedModels.count {
            return false
        }
        
        
        self.selectedPersonArray.removeAll()
        self.selectedPersonArray = selectedModels
        
        
        
        let text = NSMutableString.init(string: textView.text ?? "")
        text.replaceCharacters(in: newRange, with: "")
        
        let newCurrentText: String = text as String
        textView.text = newCurrentText
        textView.selectedRange = NSRange(location: newRange.location, length: 0)
        
        self.changgeRange = NSRange(location: newRange.location, length: 0)
        
        self.hightAtUserName()
        
        //        // 移动光标到新位置
        //        let newCursorPosition = newCurrentText.utf16.count
        //        if let position = mv_textView.mv_textField.position(from: mv_textView.mv_textField.beginningOfDocument, offset: newCursorPosition) {
        //
        //            mv_textView.mv_textField.selectedTextRange = mv_textView.mv_textField.textRange(from: position, to: position)
        //        }
        
        return true
    }
}

extension TextViewController1: UITextViewDelegate {
    
    /// 输入框内容变化
    @objc
    private func mv_textChange(_ userInfo: NSNotification) {
        
        guard let _: NSString = textView.text as NSString? else {
            self.hightAtUserName()
            return
        }
        
        if self.isAddText {
            
            let markedTextRange = textView.markedTextRange
            if let a = markedTextRange {
                let newText = textView.text(in: a) ?? ""
                
                /// 计算插入数据后的位置
                for atUserModel in self.selectedPersonArray {
                    
                    let rangeLocation = self.changgeRange?.location ?? 0
                    
                    if rangeLocation < atUserModel.endIndex {
                        
                        if atUserModel.yuText.isEmpty {
                            atUserModel.yuStartIndex = atUserModel.startIndex
                        }
                        
                        let start = atUserModel.yuStartIndex
                        let end = atUserModel.yuStartIndex + "@\(atUserModel.userName)".utf16.count
                        
                        let location = atUserModel.startIndex
                        let length = newText.utf16.count
                        
                        if start <= location {
                            
                            atUserModel.startIndex = start + length
                            atUserModel.endIndex = end + length
                        }
                        
                        atUserModel.yuText = newText
                    }
                    
                }
                
                self.isDeleteText = false
                
            } else {
                
                
                ///需判断addText为空，为空表示删除
                if addText.isEmpty, self.isDeleteText {
                    
                    self.isAddText = false
                    self.isDeleteText = false
                    
                    /// 计算插入数据后的位置
                    for atUserModel in self.selectedPersonArray {
                        
                        let rangeLocation = self.changgeRange?.location ?? 0
                        
                        if rangeLocation < atUserModel.endIndex {
                            
                            let start = atUserModel.yuStartIndex
                            let end = atUserModel.yuStartIndex + "@\(atUserModel.userName)".utf16.count
                            
                            let location = atUserModel.startIndex
                            let length = 0
                            
                            if start <= location {
                                
                                atUserModel.startIndex = start + length
                                atUserModel.endIndex = end + length
                            }
                            
                            atUserModel.yuText = ""
                        }
                        
                    }
                    
                } else {
                    
                    /// 计算插入数据后的位置
                    for atUserModel in self.selectedPersonArray {
                        
                        let start = atUserModel.startIndex
                        let end = atUserModel.endIndex
                        
                        let location = self.changgeRange?.location ?? 0
                        let length = addText.utf16.count
                        
                        if location <= start {
                            
                            atUserModel.startIndex = start + length
                            atUserModel.endIndex = end + length
                        }
                    }
                }
                
            }
        }
        
        self.hightAtUserName()
        
        ///结束后状态需要调整
        let markedTextRange2 = textView.markedTextRange
        if let _ = markedTextRange2 {
            
            addText = ""
        } else {
            
            self.isAddText = false
            
            /// 计算插入数据后的位置
            for atUserModel in self.selectedPersonArray {
                atUserModel.yuText = ""
            }
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "@" {
            
            self.isAddText = false
            
            selectPersonAction()
            return false
        }
        
        if text.isEmpty {
            
            let markedTextRange = textView.markedTextRange
            if let _ = markedTextRange {
                
                self.changgeRange = range
                
                ///有预输入
                self.isAddText = true
                self.isDeleteText = true
                
                return true
            } else {
                
                /// 没有预输入
                self.isAddText = false
                
                let selectedRange = textView.selectedRange
                let newRange = NSRange.init(location: 0, length: selectedRange.location)
                let selectFirstStr = (textView.text as NSString).substring(with: newRange)
                
                if selectedRange.length != 0 {
                    /// 删除选择的数据，需判断是否选中人名
                    return !deleteAtUser(range: selectedRange)
                } else {
                    
                    if let lastChar = selectFirstStr.last, "\(lastChar)".containsEmoji, range.length == 1 {
                        /// 删除光标前的需判断是否是表情
                        let location = range.location - 1 >= 0 ? range.location - 1 : range.location
                        let length = range.length + 1 <= selectFirstStr.utf16.count ?  range.length + 1 : range.length
                        let newRange = NSRange(location: location, length: length)
                        return !deleteAtUser(range: newRange)
                    }
                    
                    /// 正常删除需判断是否选中人名
                    return !deleteAtUser(range: range)
                }
            }
            
        } else {
            
            self.addText = text
            
            ///这里先保存，在deleteAtUser中会重新保存
            self.changgeRange = range
            
            /// 表示选中部分，需要先删除后增加
            if range.length != 0 {
                
                let _ = deleteAtUser(range: range)
            }
            
            self.isAddText = true
        }
        
        return true
    }
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        
        /// 增加时不走下面的代码，否则会导致光标位置不对
        if self.isAddText {
            return
        }
        
        // 光标不能点落在@词中间
        let range = textView.selectedRange
        
        if range.length > 0 {
            // 选择文本时可以
            return
        }
        
        for userModel in selectedPersonArray {
            
            let newRange = NSRange.init(location: userModel.startIndex, length: userModel.endIndex - userModel.startIndex)
            if NSLocationInRange(range.location, newRange), range.location > newRange.location {
                textView.selectedRange = NSRange(location: newRange.location + newRange.length, length: 0)
                break
            }
        }
        
    }
    
}


