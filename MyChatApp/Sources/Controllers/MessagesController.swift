//
//  MessagesController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

protocol MessagesControllerDelegate: class {
    func fetchUserAndSetupNavBarTitle()
    
    func showChatController(for user: User)
}

// Show user's messages view - Root
class MessagesController: UITableViewController {
    // MARK:- Properties
    private var messages = [Message]()
    private var messagesDictionary = [String : Message]()
    fileprivate let cellId = "MessagesCellId"
    fileprivate var timer: Timer?
    
    // MARK:- Life Cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserIsLoggedIn()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain,
                                                           target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "new_message_icon"), style: .plain,
                                                            target: self, action: #selector(handleNewMessage))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.enableAllOrientation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.enableAllOrientation = false
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }

    // MARK:- Handling methods
    private func checkUserIsLoggedIn() {
        // if user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    // MARK:- Fetching user messages into MessagesController Screen
    // 항목 목록에 대한 추가를 수신 대기. 즉 여기선 메세지들이 추가되는 것을 수신 대기.
    private func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let meReference = Database.database().reference().child("user-messages").child(uid)
        meReference.observe(.childAdded) { [weak self] (snapshot: DataSnapshot) in
            let partnerId = snapshot.key
            
            let partnerReference = Database.database().reference().child("user-messages").child(uid).child(partnerId)
            partnerReference.observe(.childAdded, with: { [weak self] (snapshot) in
                guard let self = self else { return }
                
                let messageId = snapshot.key
                self.fetchMessage(with: messageId)
                
            })
        }
        
        meReference.observe(.childRemoved) { [weak self] (snapshot) in
            guard let self = self else { return }
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }
    }
    
    // Fetch Message whenever user send message -> updateChildValues
    private func fetchMessage(with messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        messagesReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any] else { return }
            let message = Message(dictionary: dictionary)
            guard let chatPartnerId = message.chatPartnerId() else { return }
                
            self.messagesDictionary[chatPartnerId] = message
            self.messages.append(message)
            self.attemptReloadOfTable()
        })
    }
    
    // Fix bug: too much relaoding table into reload table just once.
    // Continuously cancel timer..and setup a new timer
    // Finally, no longer cancel the timer. -> Because timer is working with main thread run loop..? Almost right
    // So it fires the block after 0.1 sec
    func attemptReloadOfTable() {
        self.timer?.invalidate()
//        print("Canceled timer just before.")
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] (timer: Timer) in
            guard let self = self else {
                return
            }
            self.messages = Array(self.messagesDictionary.values)
            self.messages.sort(by: { (message1, message2) -> Bool in
                if
                    let time1 = message1.timestamp,
                    let time2 = message2.timestamp {
                    return time1 > time2
                } else {
                    return false
                }
            })
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                print("!! tableView reloaded after 0.1 seconds")
            }
        })
//        print("Getting messages?")
    }
    
    // MARK :- Presenting another ViewController
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
        let loginController = LoginRegisterController()
        loginController.delegate = self
        present(loginController, animated: true, completion: nil)
    }
}

// MARK:- Regarding tableView methods
extension MessagesController {
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
        return 84
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let partnerId = message.chatPartnerId() else {
            return
        }
        // Get partner info.
        let ref = Database.database().reference().child("users").child(partnerId)
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any],
                let partner = User(dictionary: dictionary) else {
                    return
            }
            partner.id = partnerId
            self.showChatController(for: partner)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let message = self.messages[indexPath.row]

        guard let chatPartnerId = message.chatPartnerId() else { return }

        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId)
            .removeValue { [weak self] (error, ref) in
                if let error = error {
                    print("Failed to delete message: \(error.localizedDescription)")
                    return
                }

                guard let self = self else { return }

                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
}



// MARK:- MessagesController delegate methods
extension MessagesController: MessagesControllerDelegate {
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // observeSingleEvent : Once this value is returned..this callback no longer listening to any new values..
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: DataEventType.value) { [weak self] (snapshot: DataSnapshot) in
            guard
                let self = self,
                let dictionary = snapshot.value as? [String: Any] else {
                    return
            }
            self.navigationItem.title = dictionary["name"] as? String
            
            // 메세지들 싹 다 지우고, 다시 불러오기
            self.messages.removeAll()
            self.messagesDictionary.removeAll()
            self.tableView.reloadData()
            self.observeUserMessages() // 메인에 해당 유저의 메세지들 불러오기
        }
    }
    
    // 재사용
    func showChatController(for user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.partner = user
        
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로"
        navigationItem.backBarButtonItem = backItem
        
        navigationController?.pushViewController(chatLogController, animated: true)
    }
}

