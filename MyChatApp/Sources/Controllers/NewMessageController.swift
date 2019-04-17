//
//  NewMessageController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol NewMessageControllerDelegate: class {
    func showChatController(for user: User)
}

// Show new message view in terms of sending messages
class NewMessageController: UITableViewController {
    
    // MARK:- Properties
    weak var delegate: NewMessageControllerDelegate?
    private let cellId = "NewMessageCellId"
    private var users = [User]()
    
    // MARK:- Life Cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationItem.title = "Chatting Partners"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                           target: self, action: #selector(handleCancel))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.allowsSelection = true
        fetchUser()
    }
    
    // MARK:- Fetching chattable users.
    private func fetchUser() {
        Database.database().reference().child("users").observe(DataEventType.childAdded) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let user = User(dictionary: dictionary) else {
                    return
            }
            user.id = snapshot.key
            self.users.append(user)
            
            // Inside asynchronous background work .. Wanna sync tableView: DispatchQueue.main.async
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK:- Regarding tableView of NewMessageController
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
        
        if let imageUrl = user.profileImageUrl {
            cell.profileImageView.loadImageUsingCache(with: imageUrl)
        }
        
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
            // MessagesController 에서 구현하고 사용헀던 method 재사용
            self.delegate?.showChatController(for: user)
        }
    }
    
}
