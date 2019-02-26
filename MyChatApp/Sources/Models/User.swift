//
//  User.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation

class User: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    
    init(name: String, email: String, profileImageUrl: String) {
        self.name = name
        self.email = email
        self.profileImageUrl = profileImageUrl
    }
}

extension User {
    convenience init?(dictionary: [String: Any]) {
        guard
            let name = dictionary["name"] as? String,
            let email = dictionary["email"] as? String,
            let profileImageUrl = dictionary["profileImageUrl"] as? String else {
                return nil
        }
        self.init(name: name, email: email, profileImageUrl: profileImageUrl)
    }
}

