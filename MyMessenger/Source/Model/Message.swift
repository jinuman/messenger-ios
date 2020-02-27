//
//  Message.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 26/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation
import FirebaseAuth

class Message {
    var fromId: String?
    var toId: String?
    var timestamp: Date?
    var text: String?
    
    var imageUrl: String?
    var imageWidth: Double?
    var imageHeight: Double?
    
    var videoUrl: String?
    
    init(dictionary: [String : Any]) {
        self.fromId = dictionary["fromId"] as? String
        self.toId = dictionary["toId"] as? String
        
        if let timestamp = dictionary["timestamp"] as? Double {
            self.timestamp = Date(timeIntervalSince1970: timestamp)
        } else {
            self.timestamp = nil
        }
        
        self.text = dictionary["text"] as? String
        
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? Double
        self.imageHeight = dictionary["imageHeight"] as? Double
        
        self.videoUrl = dictionary["videoUrl"] as? String
    }
    
    // Based in currentUser, if it is toId or fromId
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid
            ? toId
            : fromId
    }
}
