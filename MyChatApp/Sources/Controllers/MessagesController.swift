//
//  MessagesController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

protocol MessagesControllerDelegate: class {
    func setNavBarTitle()
}

// Show user's messages view - Root
class MessagesController: UITableViewController {
    // MARK:- Properties
    var messages: [Message] = []
    let cellId = "MessagesCellId"
    
    // MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain,
                                                           target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "new_message_icon"), style: .plain,
                                                            target: self, action: #selector(handleNewMessage))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        checkIfUserIsLoggedIn()
        observeMessages()
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showChatController))
//        self.navigationController?.navigationBar.addGestureRecognizer(tapGesture)
    }
    
    // MARK:- Methods
    private func checkIfUserIsLoggedIn() {
        // if user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    private func observeMessages() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let message = Message(dictionary: dictionary) else {
                    return
            }
            self.messages.append(message)
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.delegate = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        loginController.delegate = self
        present(loginController, animated: true, completion: nil)
    }
    
    // MARK:- tableView methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            fatalError("Cell is not proper")
        }
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

}


// MARK:- Regarding Custom LoginControllerDelegate
extension MessagesController: LoginControllerDelegate {
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference()
        // observeSingleEvent : Once this value is returned..this callback no longer listening to any new values..
        ref.child("users").child(uid).observeSingleEvent(of: DataEventType.value) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any] else {
                    return
            }
            self.navigationItem.title = dictionary["name"] as? String
//            self.setupNavBarWithUser(user: user)
        }
    }
    
    func setupNavBar(with name: String) {
        self.navigationItem.title = name
    }
//    func setupNavBarWithUser(user: User) {
//        let containerView = UIView()
//
//        let profileImageView = UIImageView()
//        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        profileImageView.contentMode = .scaleAspectFill
//        profileImageView.layer.cornerRadius = 20
//        profileImageView.clipsToBounds = true
//        guard let urlString = user.profileImageUrl else {
//            return
//        }
//        profileImageView.loadImageUsingCacheWithUrlString(urlString)
//
//        containerView.addSubview(profileImageView)
//        // need x, y, width, height
//        profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
//        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
//
//        let nameLabel = UILabel()
//        nameLabel.text = user.name
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        containerView.addSubview(nameLabel)
//        // need x, y, width, height
//        nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8).isActive = true
//        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
//        nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
//        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
//
//        self.navigationItem.titleView = containerView
//    }
}

extension MessagesController: NewMessageControllerDelegate {
    @objc internal func showChatController(for user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
}

