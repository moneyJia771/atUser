# UITextView 实现@人功能说明文档

## 概述

本文档详细说明了如何在 iOS 应用中为 UITextView 添加@人功能。该功能允许用户在文本输入过程中通过输入@符号来选择并插入用户名，并以特殊颜色高亮显示。

## 核心功能

1. 检测用户输入的@符号并触发用户选择界面
2. 在光标位置插入@用户名
3. 高亮显示@用户名
4. 处理@用户名的删除
5. 防止光标落在@用户名中间

## 实现步骤

### 1. 检测@符号并跳转选择人界面

当用户在 UITextView 中输入@符号时，我们需要拦截这个输入并跳转到用户选择界面：

```swift
func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if text == "@" {
        self.updateEditingState(isAdding: false)
        selectPersonAction()
        return false
    }
    
    // ... existing code ...
}
```

这段代码在 UITextViewDelegate 的方法中检测输入的文本是否为@符号。如果是，则调用 `selectPersonAction()` 方法并返回 false 以阻止@符号被直接添加到文本中。

### 2. 选择人后处理逻辑

选择人界面返回后，我们需要处理两种情况：
- 用户选择了一个人：插入完整的@用户名
- 用户未选择人直接返回：仅插入@符号

```swift
/// @人点击
@objc func selectPersonAction() {
    let vc = ChooseUserVC.init()
    
    // 用户选择了一个人的回调
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
    
    // 用户未选择人直接返回的回调
    vc.leftCallBack = { [weak self] in
        guard let self = self else {return}
        
        self.updateEditingState(isAdding: false)
        
        // 使用辅助方法插入@符号并更新位置信息
        self.insertTextAtCursor("@")
    }
    
    self.present(vc, animated: true)
}
```

为了避免代码重复，我们提取了一个辅助方法 `insertTextAtCursor` 来处理在光标位置插入文本的逻辑：

```swift
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
```

### 3. 状态变量的作用

在实现过程中，我们使用了几个关键的状态变量来跟踪文本变化：

# isAddText 变量的作用
isAddText 是一个布尔类型变量，用于标记当前是否正在添加文本。具体作用包括：

1. 在用户输入或粘贴文本时设置为 true ，用于区分添加和删除操作
2. 在 textViewDidChangeSelection 方法中，当 isAddText 为 true 时，不执行光标位置调整逻辑，避免在输入过程中光标位置错误
3. 在中文输入法完成输入后，重置为 false ，表示输入完成

# isDeleteText 变量的作用
isDeleteText 也是一个布尔类型变量，专门用于处理删除操作：

1. 当用户删除文本时设置为 true
2. 特别用于区分中文输入法中"删除预输入内容"和"删除已确认内容"的情况
3. 与 addText 变量配合使用，当 addText 为空且 isDeleteText 为 true 时，表示用户正在删除内容

# changeRange 变量的作用
changeRange 是一个 NSRange? 类型的可选变量，用于记录文本变化的范围：

1. 存储文本变化的位置（location）和长度（length）
2. 在计算 @用户名位置调整时提供参考点
3. 在删除 @用户名时，用于记录新的光标位置

# addText 变量的作用
addText 是一个字符串变量，用于存储添加的文本内容：

1. 在处理文本变化时用于更新 @用户名的位置
2. 当为空字符串且 isDeleteText 为 true 时，表示正在执行删除操作
3. 在中文输入法预输入状态下，会被重置为空字符串

这些状态变量在处理复杂的文本编辑操作时非常重要，特别是在处理中文输入法和表情符号等特殊情况时。我们通过 `updateEditingState` 方法统一管理这些状态：

```swift
private func updateEditingState(isAdding: Bool, isDeletion: Bool = false, range: NSRange? = nil, text: String = "") {
    self.isAddText = isAdding
    self.isDeleteText = isDeletion
    self.changeRange = range
    self.addText = text
}
```

### 4. 处理@用户名的删除

当用户尝试删除文本时，我们需要检查是否会影响到@用户名，如果是，则需要完整删除整个@用户名：

```swift
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
```

为了确定哪些@用户名会受到删除操作的影响，我们实现了 `calculateAffectedUsers` 方法：

```swift
private func calculateAffectedUsers(_ range: NSRange) -> (affected: [BCAtUserInfoModel], unaffected: [BCAtUserInfoModel], newRange: NSRange) {
    var affectedUsers = [BCAtUserInfoModel]()
    var unaffectedUsers = [BCAtUserInfoModel]()
    var newRange = range
    var isLocation = false
    var selectStart = 0
    
    // ... existing code ...
    
    return (affectedUsers, unaffectedUsers, newRange)
}
```

## 关键技术点

### 1. 中文输入法支持

为了正确处理中文输入法的预输入状态，我们使用 `markedTextRange` 来检测：

```swift
if let markedTextRange = textView.markedTextRange {
    if let newText = textView.text(in: markedTextRange), !newText.isEmpty {
        return
    }
}
```

在处理文本变化时，我们需要特别关注中文输入法的预输入状态，以确保@用户名的位置信息正确更新：

```swift
if let markedTextRange = textView.markedTextRange {
    let newText = textView.text(in: markedTextRange) ?? ""
    
    /// 计算插入数据后的位置
    for atUserModel in self.selectedPersonArray {
        // ... existing code ...
        
        atUserModel.yuText = newText
    }
    
    self.isDeleteText = false
}
```

### 2. 位置索引计算

在处理文本位置时，我们使用 `utf16.count` 而不是 `count` 来计算字符串长度，以正确处理 Unicode 字符：

```swift
atUserInfoModel.endIndex = atStr.utf16.count + index
```

### 3. 防止光标落在@用户名中间

为了保持@用户名的完整性，我们需要防止光标落在@用户名中间：

```swift
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
```

### 4. 表情符号处理

为了正确处理表情符号的删除，我们添加了一个扩展来检测字符串是否包含表情符号：

```swift
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
```

在删除操作中，我们需要特别处理表情符号：

```swift
if let lastChar = selectFirstStr.last, "\(lastChar)".containsEmoji, range.length == 1 {
    /// 删除光标前的需判断是否是表情
    let location = range.location - 1 >= 0 ? range.location - 1 : range.location
    let length = range.length + 1 <= selectFirstStr.utf16.count ?  range.length + 1 : range.length
    let newRange = NSRange(location: location, length: length)
    return !deleteAtUser(range: newRange)
}
```

## 总结

实现 UITextView 的@人功能需要处理多种复杂情况，包括文本插入、删除、光标控制和中文输入法支持等。通过合理使用状态变量和辅助方法，我们可以实现一个功能完善、用户体验良好的@人功能。

关键是要确保：
1. @用户名在插入时位置正确（在光标位置）
2. @用户名高亮显示
3. @用户名删除时完整删除
4. 光标不能落在@用户名中间
5. 正确处理中文输入法和表情符号等特殊情况

通过这些技术点的实现，我们可以为用户提供一个流畅的@人体验。
