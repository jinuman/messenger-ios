//
//  NewMessageController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

protocol NewMessageControllerDelegate: class {
    func showChatController(for user: User)
}

// Show new message view in terms of sending messages
class NewMessageController: UITableViewController {
    
    weak var delegate: NewMessageControllerDelegate?
    
    // MARK:- Properties
    private let cellId = "NewMessageCellId"
    private var users = [User]()
    
    // MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                           target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.allowsSelection = true
        fetchUser()
    }
    
    private func fetchUser() {
        let ref = Database.database().reference()
        ref.child("users").observe(DataEventType.childAdded) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let user = User(dictionary: dictionary) else {
                    return
            }
            user.id = snapshot.key
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
            fatalError("User cell is not proper")
        }
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        guard let urlString = user.profileImageUrl else {
            fatalError("url string is not proper..")
        }
        cell.profileImageView.loadImageUsingCache(with: urlString)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            let user = self.users[indexPath.row]
            self.delegate?.showChatController(for: user)
        }
    }
    
}
