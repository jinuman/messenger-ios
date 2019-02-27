//
//  Message.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 26/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation

class Message {
    var fromId: String?
    var text: String?
    var timestamp: Date?
    var toId: String?
    
    init(fromId: String, text: String, timestamp: Date, toId: String) {
        self.fromId = fromId
        self.text = text
        self.timestamp = timestamp
        self.toId = toId
    }
}

extension Message {
    convenience init?(dictionary: [String: Any]) {
        guard
            let fromId = dictionary["fromId"] as? String,
            let text = dictionary["text"] as? String,
            let timestamp = dictionary["timestamp"] as? Double,
            let toId = dictionary["toId"] as? String else {
                return nil
        }
        self.init(fromId: fromId, text: text, timestamp: Date(timeIntervalSince1970: timestamp), toId: toId)
    }
}


