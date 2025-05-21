//
//  TextViewController.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//


import UIKit

class TextViewController: UIViewController {
    
    /// @人数组
    var selectedPersonArray: [BCAtUserInfoModel] = [BCAtUserInfoModel]()
    
    /// 输入框内容修改 增加或者删除
    private var isAddText = false
    /// 是否是删除，当删除时为 true ，为了区分中文输入删除完预输入内容 和 中文输入用户确定的内容
    private var isDeleteText = false
    private var changeRange: NSRange?
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
        let navBarView = NavBarView.init(frame: CGRect(x: 0, y: MVStatusScreenHeight, width: self.view.frame.size.width, height: 44))
        navBarView.titleLabel.text = "UITextView添加@事件"
        navBarView.vc = self
        return navBarView
    } ()
    
    lazy var textView: UITextView = {
        
        let view = UITextView.init(frame: CGRect(x: 20, y: 200, width: self.view.frame.size.width - 40, height: 200))
        view.backgroundColor = UIColor.white
        view.delegate = self
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.textColor = .black
        return view
    } ()
    
}

// MARK: - @用户管理相关方法
extension TextViewController {
    
    /// 更新编辑状态
    private func updateEditingState(isAdding: Bool, isDeletion: Bool = false, range: NSRange? = nil, text: String = "") {
        self.isAddText = isAdding
        self.isDeleteText = isDeletion
        self.changeRange = range
        self.addText = text
    }
    
    /// 在光标位置插入文本并更新@用户位置信息
    private func insertTextAtCursor(_ text: String, isNewAtUser: Bool = false, atUserInfo: BCAtUserInfoModel? = nil) {
        // 获取当前光标位置
        let cursorPosition = self.textView.selectedRange.location
        
        // 在光标位置插入文本
        let currentText = self.textView.text ?? ""
        let nsText = NSMutableString(string: currentText)
        
        // 添加边界检查
        if cursorPosition <= nsText.length {
            nsText.insert(text, at: cursorPosition)
            self.textView.text = nsText as String
            
            // 更新光标位置到插入的文本之后
            self.textView.selectedRange = NSRange(location: cursorPosition + text.utf16.count, length: 0)
            
            // 更新所有在插入位置之后的@用户名的位置信息
            updateAtUserPositions(afterPosition: cursorPosition, offset: text.utf16.count, excludeUser: atUserInfo)
            
            self.highlightAtUserNames()
        }
    }
    
    /// 更新指定位置后的@用户位置信息
    private func updateAtUserPositions(afterPosition position: Int, offset: Int, excludeUser: BCAtUserInfoModel? = nil) {
        for model in self.selectedPersonArray where model !== excludeUser {
            if model.startIndex >= position {
                model.startIndex += offset
                model.endIndex += offset
            }
        }
    }
    
    /// @人点击
    @objc func selectPersonAction() {
        
        let vc = ChooseUserVC.init()
        vc.selectBlock = { [weak self] data in
            
            guard let self = self else {return}
            
            guard let userInfoModel = data as? BCUserInfoModel else {
                return
            }
            
            self.textView.unmarkText()
            
            // 获取当前光标位置
            let index = self.textView.selectedRange.location
            
            let atStr: String = "@\(userInfoModel.BCuserName)"
            
            let atUserInfoModel = BCAtUserInfoModel.init()
            atUserInfoModel.userId = userInfoModel.BCuid
            atUserInfoModel.userName = userInfoModel.BCuserName
            atUserInfoModel.startIndex = index
            atUserInfoModel.endIndex = atStr.utf16.count + index
            self.selectedPersonArray.append(atUserInfoModel)
            
            // 使用辅助方法插入文本并更新位置信息
            self.insertTextAtCursor(atStr, isNewAtUser: true, atUserInfo: atUserInfoModel)
        }
        
        vc.leftCallBack = { [weak self] in
            /// 返回时增加 艾特符号
            
            guard let self = self else {return}
            
            self.updateEditingState(isAdding: false)
            
            // 使用辅助方法插入@符号并更新位置信息
            self.insertTextAtCursor("@")
        }
        
        self.present(vc, animated: true)
    }
    
    
    /// 高亮@用户名
    @objc func highlightAtUserNames() {
        
        /// 当有预输入时不使用富文本，否则中文第一个字母处理不了
        if let markedTextRange = textView.markedTextRange {
            if let newText = textView.text(in: markedTextRange), !newText.isEmpty {
                return
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
        
        ///结束后状态需要调整
        if textView.markedTextRange == nil {
            self.isAddText = false
        }
    }
    
    /// 计算受影响的@用户和新的删除范围
    private func calculateAffectedUsers(_ range: NSRange) -> (affected: [BCAtUserInfoModel], unaffected: [BCAtUserInfoModel], newRange: NSRange) {
        var affectedUsers = [BCAtUserInfoModel]()
        var unaffectedUsers = [BCAtUserInfoModel]()
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
                unaffectedUsers.append(atUserModel)
                continue
            }
            
            ///删除后的位置需要调整
            if location + length <= start {
                atUserModel.startIndex = start - newRange.length
                atUserModel.endIndex = end - newRange.length
                unaffectedUsers.append(atUserModel)
                continue
            }
            
            // 这是受影响的@用户
            affectedUsers.append(atUserModel)
            
            if location < end, isLocation == false {
                selectStart = location < start ? location : start
                newRange.location = selectStart
                isLocation = true
            }
            
            if location + length > start {
                newRange.length = location + length > end ? location + length - selectStart : end - selectStart
            }
        }
        
        return (affectedUsers, unaffectedUsers, newRange)
    }
    
    /// 删除@用户
    func deleteAtUser(range: NSRange) -> Bool {
        // 计算受影响的@用户和新的删除范围
        let result = calculateAffectedUsers(range)
        
        // 如果没有受影响的@用户，返回false
        if result.affected.isEmpty {
            return false
        }
        
        // 更新selectedPersonArray
        self.selectedPersonArray = result.unaffected
        
        // 更新文本和光标位置
        let text = NSMutableString.init(string: textView.text ?? "")
        text.replaceCharacters(in: result.newRange, with: "")
        
        let newCurrentText: String = text as String
        textView.text = newCurrentText
        textView.selectedRange = NSRange(location: result.newRange.location, length: 0)
        
        self.changeRange = NSRange(location: result.newRange.location, length: 0)
        
        self.highlightAtUserNames()
        
        return true
    }
}

// MARK: - UITextViewDelegate
extension TextViewController: UITextViewDelegate {
    
    /// 输入框内容变化
    @objc
    private func mv_textChange(_ userInfo: NSNotification) {
        
        guard let _: NSString = textView.text as NSString? else {
            self.highlightAtUserNames()
            return
        }
        
        if self.isAddText {
            
            if let markedTextRange = textView.markedTextRange {
                let newText = textView.text(in: markedTextRange) ?? ""
                
                /// 计算插入数据后的位置
                for atUserModel in self.selectedPersonArray {
                    
                    let rangeLocation = self.changeRange?.location ?? 0
                    
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
                    
                    self.updateEditingState(isAdding: false, isDeletion: false)
                    
                    /// 计算插入数据后的位置
                    for atUserModel in self.selectedPersonArray {
                        
                        let rangeLocation = self.changeRange?.location ?? 0
                        
                        if rangeLocation < atUserModel.endIndex {
                            
                            let start = atUserModel.yuStartIndex
                            let end = atUserModel.yuStartIndex + "@\(atUserModel.userName)".utf16.count
                            
                            if start <= atUserModel.startIndex {
                                
                                atUserModel.startIndex = start
                                atUserModel.endIndex = end
                            }
                            
                            atUserModel.yuText = ""
                        }
                    }
                    
                } else {
                    
                    /// 计算插入数据后的位置
                    let location = self.changeRange?.location ?? 0
                    let length = addText.utf16.count
                    
                    updateAtUserPositions(afterPosition: location, offset: length)
                }
            }
        }
        
        self.highlightAtUserNames()
        
        ///结束后状态需要调整
        if let _ = textView.markedTextRange {
            addText = ""
        } else {
            self.isAddText = false
            
            /// 重置所有@用户的预输入状态
            for atUserModel in self.selectedPersonArray {
                atUserModel.yuText = ""
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "@" {
            self.updateEditingState(isAdding: false)
            selectPersonAction()
            return false
        }
        
        if text.isEmpty {
            
            if let _ = textView.markedTextRange {
                self.updateEditingState(isAdding: true, isDeletion: true, range: range)
                return true
            } else {
                self.updateEditingState(isAdding: false)
                
                let selectedRange = textView.selectedRange
                
                if selectedRange.length != 0 {
                    /// 删除选择的数据，需判断是否选中人名
                    return !deleteAtUser(range: selectedRange)
                } else {
                    let newRange = NSRange.init(location: 0, length: selectedRange.location)
                    let selectFirstStr = (textView.text as NSString).substring(with: newRange)
                    
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
            self.updateEditingState(isAdding: true, range: range, text: text)
            
            /// 表示选中部分，需要先删除后增加
            if range.length != 0 {
                let _ = deleteAtUser(range: range)
            }
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


extension String {
    
    var containsEmoji: Bool {
        // 检查字符串是否为空
        guard !self.isEmpty else { return false }
        
        // 检查每个字符是否都是表情符号
        let nonEmojiCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters).union(CharacterSet.whitespacesAndNewlines)
        let filteredString = self.components(separatedBy: nonEmojiCharacterSet).joined()
        
        // 如果过滤后的字符串长度为0，说明原字符串只包含表情符号
        return !filteredString.isEmpty && self.count == filteredString.count
    }
}
