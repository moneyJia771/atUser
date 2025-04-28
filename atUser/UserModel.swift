//
//  UserModel.swift
//  atUser
//
//  Created by blackCat on 2025/4/28.
//

import Foundation

class BCAtUserInfoModel: HandyJSON {
    
    var startIndex = 0
    var endIndex = 0
    var userId = 0
    var userName = ""
    
    
    var yuStartIndex = 0
    var yuText = ""
    
    required init() {}
}

class BCUserInfoModel {
    var BCuid: Int = 0
    var BCuserName: String = ""
    
    init(uid: Int, userName: String) {
        self.BCuid = uid
        self.BCuserName = userName
    }
}
