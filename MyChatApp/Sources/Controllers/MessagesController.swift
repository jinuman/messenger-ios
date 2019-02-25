//
//  MessagesController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    let chatLogController: ChatLogController = {
        let vc = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        return vc
    }()
    
    // MARK:- View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain,
                                                           target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "new_message_icon"), style: .plain,
                                                            target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showChatController))
        self.navigationController?.navigationBar.addGestureRecognizer(tapGesture)
    }
    
    @objc private func showChatController() {
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc private func handleNewMessage() {
        let newMessageController = NewMessageController()
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    private func checkIfUserIsLoggedIn() {
        // if user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid)
            // observeSingleEvent : Once this value is returned..this callback no longer listening to any new values..
            .observeSingleEvent(of: DataEventType.value) { [weak self] (snapshot: DataSnapshot) in
                guard
                    let self = self,
                    let dic = snapshot.value as? [String: Any],
                    let user = User(dictionary: dic) else {
                        return
                }
                
                self.setupNavBarWithUser(user: user)
        }
    }
    
    func setupNavBarWithUser(user: User) {
        
        let containerView = UIView()
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        guard let urlString = user.profileImageUrl else {
            return
        }
        profileImageView.loadImageUsingCacheWithUrlString(urlString)
        
        containerView.addSubview(profileImageView)
        // need x, y, width, height
        profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)
        // need x, y, width, height
        nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        self.navigationItem.titleView = containerView
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }

}

