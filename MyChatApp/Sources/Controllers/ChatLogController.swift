//
//  ChatLogController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 25/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController {
    
    // MARK:- Properties for controller
    let cellId = "ChatLogCellId"
    // User's partner
    var partner: User? {
        didSet {
            guard let partner = partner else {
                return
            }
            navigationItem.title = partner.name
            observeMessages()
        }
    }
    // 사용자 - 대상 간의 채팅 메세지들
    var messages: [Message] = []
    
    // MARK:- ChatLog Screen properties
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Enter message..."
        tf.delegate = self
        return tf
    }()
    
    // MARK:- Life Cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true  // Draggable..
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        setupInputComponents()
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleKeyboardAppear(_:)),
                       name: UIResponder.keyboardWillShowNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(handleKeyboardAppear(_:)),
                       name: UIResponder.keyboardWillHideNotification,
                       object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // In order to fix Notification memory leak.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:- Event Methods
    func observeMessages() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let selectedId = partner?.id else {
                return
        }
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(selectedId)
        userMessagesRef.observe(.childAdded) { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard
                    let self = self,
                    let dictionary = snapshot.value as? [String: Any],
                    let message = Message(dictionary: dictionary) else {
                        return
                }
//                 #warning("need to optimize ..") // -- > Success!
//                print(" ## \(message.text ?? "Something is wrong with message.text")")
                self.messages.append(message)
                DispatchQueue.main.async { [weak self] in
                    self?.collectionView.reloadData()
                }
            })
        }
    }
    
    @objc private func handleSend() {
        let messagesRef = Database.database().reference().child("messages").childByAutoId()
        guard
            let text = inputTextField.text,
            let toId = partner?.id,
            let fromId = Auth.auth().currentUser?.uid else {
                return
        }
        let timestamp = Date().timeIntervalSince1970
        let values = [ "fromId": fromId,
                       "text": text,
                       "timestamp": timestamp,
                       "toId": toId ] as [String : Any]
        
        messagesRef.updateChildValues(values) { [weak self] (error, ref) in
            if let error = error {
                print("@@ messagesRef: \(error.localizedDescription)")
            }
            self?.inputTextField.text = nil
            guard let messageId = messagesRef.key else { return }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            userMessagesRef.updateChildValues([messageId: 1])
            // Counter part
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
            
            self?.inputTextField.resignFirstResponder()
            
        }
    }

    @objc func handleKeyboardAppear(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
                return
        }
        let isKeyboardWillShow: Bool = notification.name == UIResponder.keyboardWillShowNotification
        let safeAreaBottomHeight = view.safeAreaInsets.bottom
        let keyboardHeight = isKeyboardWillShow ? keyboardFrame.cgRectValue.height - safeAreaBottomHeight : 0
        let animationOption = UIView.AnimationOptions.init(rawValue: curve)
        
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       options: animationOption,
                       animations: {
                        self.containerViewBottomAnchor?.constant = -keyboardHeight
                        self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc fileprivate func handleUploadTap() {
        let imagePicker = UIImagePickerController()
        
//        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK:- Setting up layouts methods
    func setupInputComponents() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        
        view.addSubview(containerView)
        // need x, y, w, h
        containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = #imageLiteral(resourceName: "upload_image_icon")
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUploadTap))
        uploadImageView.addGestureRecognizer(tapRecognizer)
        uploadImageView.isUserInteractionEnabled = true
        
        let sendButton = UIButton(type: .system)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        let separatorLineView = UIView()
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        
        [uploadImageView, inputTextField, sendButton, separatorLineView].forEach {
            containerView.addSubview($0)
        }
        // need x, y, w, h
        uploadImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // need x, y, w, h
        inputTextField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // need x, y, w, h
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // need x, y, w, h
        separatorLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}

// MARK:- Extension regarding collectionView
extension ChatLogController: UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else {
            fatalError("ChatMessageCell is not proper..")
        }
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimatedFrame(for: text).width + 32
        }
        
        return cell
    }
    
    func setupCell(cell: ChatMessageCell, message: Message) {
        guard let profileImageUrl = self.partner?.profileImageUrl else {
            return
        }
        cell.profileImageView.loadImageUsingCache(with: profileImageUrl)
        
        if message.fromId == Auth.auth().currentUser?.uid {
            // outgoing blue bubble
            cell.bubbleView.backgroundColor = ChatMessageCell.bubbleBlue
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.bubbleTrailingAnchor?.isActive = true
            cell.bubbleLeadingAnchor?.isActive = false
        } else {
            // incoming lightGray bubble
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            cell.bubbleTrailingAnchor?.isActive = false
            cell.bubbleLeadingAnchor?.isActive = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.item].text {
            height = estimatedFrame(for: text).height + 20
        }
        let width = view.safeAreaLayoutGuide.layoutFrame.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        return NSString(string: text).boundingRect(with: size,
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)],
                                                   context: nil)
    }
}

// MARK:- Extension regarding UITextFieldDelegate
extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        guard let text = inputTextField.text else {
            return false
        }
        if text.isEmpty == false {
            handleSend()
        }
        return true
    }
}


