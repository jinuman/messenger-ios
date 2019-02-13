//
//  User.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation

class User: NSObject {
    var name: String?
    var email: String?
    
    init(name: String = "", email: String = "") {
        self.name = name
        self.email = email
    }
}

extension User {
    convenience init?(dictionary: [String: Any]) {

        guard
            let name = dictionary["name"] as? String,
            let email = dictionary["email"] as? String
            else { return nil }

        self.init(name: name, email: email)
    }
}
