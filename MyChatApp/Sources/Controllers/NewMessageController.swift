//
//  NewMessageController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    private let cellId = "userCell"
    private var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                           target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // need "dequeue" cells for memory efficiency!!
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            fatalError("User cell is not valid")
        }
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let profileImageUrl = user.profileImageUrl {
            // better way using cache
            cell.profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
            
            // old way...
//            guard let url = URL(string: profileImageUrl) else {
//                fatalError("url error")
//            }
//            cell.profileImageView.image = nil
//            URLSession.shared.dataTask(with: url) { (data, response, error) in
//                if error != nil {
//                    print("@@@ \(error?.localizedDescription ?? "")")
//                }
//                guard let data = data else {
//                    return
//                }
//                DispatchQueue.main.async {
//                    cell.profileImageView.image = UIImage(data: data)
//                }
//            }.resume()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
}

class UserCell: UITableViewCell {
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.0
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        setupProfileImageViewInCell()
    }
    
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
