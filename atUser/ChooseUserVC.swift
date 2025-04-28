//
//  ChooseUserVC.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//

import UIKit

class ChooseUserVC: UIViewController {
    
    // 回调闭包
    var selectBlock: ((Any) -> Void)?
    var leftCallBack: (() -> Void)?
    
    // 用户数据
    private var userList: [BCUserInfoModel] = []
    
    // UI组件
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.rowHeight = 60
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()
    
    private lazy var navBar: UIView = {
        let navBar = UIView()
        navBar.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "选择用户"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        
        let backButton = UIButton(type: .system)
        backButton.setTitle("返回", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        navBar.addSubview(titleLabel)
        navBar.addSubview(backButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            backButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 15),
            backButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor)
        ])
        
        return navBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateRandomUsers()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(navBar)
        view.addSubview(tableView)
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: MVStatusScreenHeight),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func backButtonTapped() {
        leftCallBack?()
        dismiss(animated: true, completion: nil)
    }
    
    // 生成随机用户数据
    private func generateRandomUsers() {
        // 中文名字库
        let chineseFirstNames = ["张", "王", "李", "赵", "刘", "陈", "杨", "黄", "周", "吴", "郑", "孙", "马", "朱", "胡", "林", "郭", "何", "高", "罗"]
        let chineseLastNames = ["伟", "芳", "娜", "秀英", "敏", "静", "丽", "强", "磊", "军", "洋", "勇", "艳", "杰", "娟", "涛", "明", "超", "秀兰", "霞"]
        
        // 英文名字库
        let englishNames = ["John", "Mary", "James", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth"]
        
        // 数字
        let numbers = ["007", "123", "666", "888", "999", "520", "1314", "110", "119", "120"]
        
        // 表情
        let emojis = ["😀", "😂", "😍", "🥰", "😎", "🤩", "🤔", "🤗", "🤫", "🤭"]
        
        // 特殊字符
        let specialChars = ["★", "☆", "✪", "✯", "✰", "❤️", "♠️", "♣️", "♥️", "♦️"]
        
        for i in 1...100 {
            var userName = ""
            
            // 随机决定用户名类型
            let nameType = Int.random(in: 0...2)
            
            switch nameType {
            case 0:
                // 中文名
                userName = chineseFirstNames.randomElement()! + chineseLastNames.randomElement()!
            case 1:
                // 英文名
                userName = englishNames.randomElement()!
            case 2:
                // 中文+数字
                userName = chineseFirstNames.randomElement()! + numbers.randomElement()!
            case 3:
                // 英文+表情
                userName = englishNames.randomElement()! + emojis.randomElement()!
            case 4:
                // 中文+表情+数字
                userName = chineseFirstNames.randomElement()! + emojis.randomElement()! + numbers.randomElement()!
            case 5:
                // 特殊字符+名字
                userName = specialChars.randomElement()! + chineseFirstNames.randomElement()! + chineseLastNames.randomElement()!
            default:
                userName = "用户\(i)"
            }
            
            let user = BCUserInfoModel(uid: 1000 + i, userName: userName)
            userList.append(user)
        }
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChooseUserVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        
        let user = userList[indexPath.row]
        
        // 配置单元格
        cell.textLabel?.text = "\(user.BCuserName) (ID: \(user.BCuid))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // 添加头像（简单圆形背景）
        if cell.imageView?.image == nil {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            imageView.backgroundColor = randomColor()
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            
            // 显示用户名首字母或表情
            let label = UILabel(frame: imageView.bounds)
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 18)
            
            if let firstChar = user.BCuserName.first {
                label.text = String(firstChar)
            }
            
            imageView.addSubview(label)
            
            let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)
            let image = renderer.image { ctx in
                imageView.layer.render(in: ctx.cgContext)
            }
            
            cell.imageView?.image = image
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedUser = userList[indexPath.row]
        selectBlock?(selectedUser)
        dismiss(animated: true, completion: nil)
    }
    
    // 生成随机颜色
    private func randomColor() -> UIColor {
        let red = CGFloat.random(in: 0.4...0.8)
        let green = CGFloat.random(in: 0.4...0.8)
        let blue = CGFloat.random(in: 0.4...0.8)
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
