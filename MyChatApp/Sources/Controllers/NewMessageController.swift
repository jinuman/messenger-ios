//
//  NewMessageController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

// Show new message view in terms of sending messages
class NewMessageController: UITableViewController {
    
    // MARK:- Properties
    private let cellId = "userCell"
    private var users = [User]()
    
    // MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                           target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUser()
    }
    
    private func fetchUser() {
        Database.database().reference().child("users").observe(DataEventType.childAdded) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let user = User(dictionary: dictionary) else {
                    return
            }
            self.users.append(user)
            
            // 비동기 작업 안에서 화면을 동기화하는 방법.. DispatchQueue.main 쓰자..
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()    // tableView 동기화
            }
        }
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK:- Regarding tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            fatalError("User cell is not valid")
        }
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let profileImageUrl = user.profileImageUrl {
            // better way using cache
            cell.profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
}

// MARK:- Inside NewMessageController table view
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
    
    // You should use the same reuse identifier for all cells of the same form.
    // MARK:- Cell Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        setupProfileImageViewInCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Setting up cell properties
    private func setupProfileImageViewInCell() {
        // need x, y, width, height
        profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
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
