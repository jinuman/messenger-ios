//
//  UserTableViewCell.swift
//  MyMessenger
//
//  Created by Jinwoo Kim on 27/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseDatabase

/// 두 곳에서 사용하는 셀이다.

class UserTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
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
    
    var message: Message? {
        didSet {
            self.setupNameAndProfileImage()
            
            guard let timestamp = self.message?.timestamp else {
                return
            }
            self.detailTextLabel?.text = self.message?.text
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            self.timeLabel.text = dateFormatter.string(from: timestamp)
        }
    }
    
    
    // MARK: - Initializing
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.initializeLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()

        guard let textLabel = self.textLabel,
            let detailTextLabel = self.detailTextLabel else { return }
        
        textLabel.frame = CGRect(
            x: 64,
            y: textLabel.frame.origin.y - 2,
            width: textLabel.frame.width,
            height: textLabel.frame.height
        )
        
        detailTextLabel.frame = CGRect(
            x: 64,
            y: detailTextLabel.frame.origin.y + 2,
            width: detailTextLabel.frame.width,
            height: detailTextLabel.frame.height
        )
    }
    
    private func initializeLayout() {
        self.addSubviews([
            self.profileImageView,
            self.timeLabel
        ])
        
        self.profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8.0)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(all: 48.0))
        }
        
        self.timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(100)
        }
    }
    
    private func setupNameAndProfileImage() {
        
        guard let partnerId = message?.chatPartnerId() else { return }
        
        Database.database().reference()
            .child("users")
            .child(partnerId)
            .observeSingleEvent(of: .value) { [weak self] (snapshot) in
                
            guard let `self` = self,
                let dictionary = snapshot.value as? [String: Any],
                let urlString = dictionary["profileImageUrl"] as? String else {
                    return
            }
            self.textLabel?.text = dictionary["name"] as? String
            self.profileImageView.loadImageUsingCache(with: urlString)
        }
    }
    
}
