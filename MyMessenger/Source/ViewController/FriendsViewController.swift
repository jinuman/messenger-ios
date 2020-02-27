//
//  FriendsViewController.swift
//  MyMessenger
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit

import SnapKit
import FirebaseAuth
import FirebaseDatabase

/// Similar to Kakaotalk

class FriendsViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: UI
    
    private lazy var guide = self.view.safeAreaLayoutGuide
    
    private lazy var usersTableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.backgroundColor = .white
        tableView.register([UserTableViewCell.self])
        return tableView
    }()
    
    // MARK: General
    
    private var messages = [Message]()
    private var messagesDictionary = [String : Message]()
    private var timer: Timer?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkUserIsLoggedIn()
        self.configureLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.isEnableAllOrientation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.isEnableAllOrientation = false
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }

    // MARK: - Methods
    
    private func checkUserIsLoggedIn() {
        // if user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            self.perform(
                #selector(self.handleLogout),
                with: nil,
                afterDelay: 0
            )
        } else {
            self.fetchCurrentUserNameForTitle()
        }
    }
    
    private func configureLayout() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(self.handleLogout)
        )
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "new_message_icon"),
            style: .plain,
            target: self,
            action: #selector(self.handleNewMessage)
        )
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.usersTableView)
        
        self.usersTableView.snp.makeConstraints {
            $0.edges.equalTo(self.guide)
        }
    }
    
    private func fetchCurrentUserNameForTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        /// observeSingleEvent: Once this value is returned,
        /// this callback no longer listening to any new values.
        Database.database().reference()
            .child("users")
            .child(uid)
            .observeSingleEvent(of: DataEventType.value) { [weak self] (snapshot: DataSnapshot) in
                
            guard let `self` = self,
                let dictionary = snapshot.value as? [String: Any] else { return }
                
            self.navigationItem.title = dictionary["name"] as? String
            
            // 메세지들 싹 다 지우고, 다시 불러오기
            self.messages.removeAll()
            self.messagesDictionary.removeAll()
            self.usersTableView.reloadData()
            self.observeUserMessages() // 메인에 해당 유저의 메세지들 불러오기
        }
    }
    
    // MARK: Fetching user messages into FriendsViewController screen
    // 항목 목록에 대한 추가를 수신 대기. 즉 여기선 메세지들이 추가되는 것을 수신 대기한다.
    private func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let reference = Database.database().reference().child("user-messages").child(uid)
        
        reference.observe(.childAdded) { [weak self] (snapshot: DataSnapshot) in
            let partnerId = snapshot.key
            
            // For partner
            Database.database().reference().child("user-messages").child(uid).child(partnerId)
                .observe(.childAdded) { [weak self] (snapshot: DataSnapshot) in
                    guard let `self` = self else { return }
                    
                    let messageId = snapshot.key
                    self.fetchMessage(with: messageId)
            }
            
        }
        
        reference.observe(.childRemoved) { [weak self] (snapshot) in
            guard let `self` = self else { return }
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptToReloadTableView()
            
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
            self.attemptToReloadTableView()
        })
    }
    
    // Fix bug: too much relaoding table into reload table just once.
    // Continuously cancel timer..and setup a new timer
    // Finally, no longer cancel the timer. -> Because timer is working with main thread run loop..? Almost right
    // So it fires the block after 0.1 sec
    func attemptToReloadTableView() {
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
                guard let `self` = self else { return }
                self.usersTableView.reloadData()
                print("!! tableView reloaded after 0.1 seconds")
            }
        })
//        print("Getting messages?")
    }
    
    @objc private func handleNewMessage() {
        let newMessageController = ChatPartnersController()
        newMessageController.delegate = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginRegisterController()
        loginController.fetchUserAndSetupNavBarTitle = self.fetchCurrentUserNameForTitle
        present(loginController, animated: true, completion: nil)
    }
}

// MARK: - Extensions

extension FriendsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int)
        -> Int
    {
        return messages.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(cellType: UserTableViewCell.self, for: indexPath)
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath)
        -> CGFloat
    {
        return 84
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath)
    {
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
            self.showChatRoomController(for: partner)
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath)
    {
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
                self.attemptToReloadTableView()
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath)
        -> String?
    {
        return "Remove"
    }
}

extension FriendsViewController: ChatPartnersControllerDelegate {
    
    func showChatRoomController(for user: User) {
        let chatRoomController = ChatRoomController(collectionViewLayout: UICollectionViewFlowLayout())
        chatRoomController.partner = user
        
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로"
        navigationItem.backBarButtonItem = backItem
        
        navigationController?.pushViewController(chatRoomController, animated: true)
    }
}

