//
//  UserCell.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 27/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseDatabase

// MARK:- Using in ChatPartnersController, MessagesController 
class UserCell: UITableViewCell {
    // MARK:- User Cell properties
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.0
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    // Handling message property
    var message: Message? {
        didSet {
            setupNameAndProfileImage()
            
            guard let timestamp = message?.timestamp else {
                return
            }
            detailTextLabel?.text = message?.text
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            timeLabel.text = dateFormatter.string(from: timestamp)
        }
    }
    
    private func setupNameAndProfileImage() {
        
        guard let partnerId = message?.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(partnerId)
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let urlString = dictionary["profileImageUrl"] as? String else {
                    return
            }
            self.textLabel?.text = dictionary["name"] as? String
            self.profileImageView.loadImageUsingCache(with: urlString)
        }
    }
    
    // You should use the same reuse identifier for all cells of the same form.
    // MARK:- Cell Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        // need x, y, width, height
        profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        // need x, y, w, h
        timeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        timeLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard
            let textLabel = textLabel,
            let detailTextLabel = detailTextLabel else {
                return
        }
        textLabel.frame = CGRect(x: 64, y: textLabel.frame.origin.y - 2,
                                 width: textLabel.frame.width, height: textLabel.frame.height)
        detailTextLabel.frame = CGRect(x: 64, y: detailTextLabel.frame.origin.y + 2,
                                       width: detailTextLabel.frame.width, height: detailTextLabel.frame.height)
    }
    
}
