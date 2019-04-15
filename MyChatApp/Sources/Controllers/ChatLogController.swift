//
//  ChatLogController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 25/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController {
    
    // MARK:- Properties for controller
    fileprivate let cellId = "ChatLogCellId"
    // User's partner
    var partner: User? {
        didSet {
            observeMessages()
        }
    }
    // 사용자 - 대상 간의 채팅 메세지들
    var messages: [Message] = []
    
    // MARK:- ChatLog Screen properties
    fileprivate var inputContainerViewBottomAnchor: NSLayoutConstraint?
    
    fileprivate var startingFrame: CGRect?
    fileprivate var blackBackgroundView: UIView?
    fileprivate var startingImageView: UIImageView?
    
    let inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
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
        view.backgroundColor = .white
        
        navigationItem.title = partner?.name
        
        // Add gesture
        let tapGesture = UITapGestureRecognizer()
        tapGesture.delegate = self
        collectionView.addGestureRecognizer(tapGesture)
        
        setupKeyboardObservers()
        
        setupCollectionView()
        
        setupInputComponents()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // In order to fix Notification memory leak.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        print("ChatLog Controller \(#function)")
    }
    
    // MARK:- Notification Center
    fileprivate func setupKeyboardObservers() {
        let nc = NotificationCenter.default
        
        nc.addObserver(self, selector: #selector(handleKeyboardWillAppear(_:)),
                       name: UIResponder.keyboardWillShowNotification, object: nil)
        
        nc.addObserver(self, selector: #selector(handleKeyboardWillAppear(_:)),
                       name: UIResponder.keyboardWillHideNotification, object: nil)
        
        nc.addObserver(self, selector: #selector(handleKeyboardDidShow),
                       name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc fileprivate func handleKeyboardWillAppear(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
                return
        }
        let isKeyboardWillShow: Bool = notification.name == UIResponder.keyboardWillShowNotification
        let safeAreaBottomHeight = view.safeAreaInsets.bottom
        let keyboardHeight = isKeyboardWillShow
            ? keyboardFrame.cgRectValue.height - safeAreaBottomHeight
            : 0
        let animationOption = UIView.AnimationOptions.init(rawValue: curve)
        
        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: animationOption,
            animations: {
                
                self.inputContainerViewBottomAnchor?.constant = -keyboardHeight
                self.view.layoutIfNeeded()
                
        }, completion: nil)
    }
    
    @objc fileprivate func handleKeyboardDidShow() {
        if messages.isEmpty == false {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.top, animated: true)
        }
    }
    
    // MARK:- Observe messages that has been changed
    func observeMessages() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let selectedId = partner?.id else {
                return
        }
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(selectedId)
        userMessagesRef.observe(.childAdded) { [weak self] (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard
                    let self = self,
                    let dictionary = snapshot.value as? [String: Any] else { return }
                
                let message = Message(dictionary: dictionary)
//                 #warning("need to optimize ..") // -- > Success!
//                print(" ## \(message.text ?? "Something is wrong with message.text")")
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.bottom, animated: true)
                }
            })
        }
    }
    
    // MARK:- Regarding sending message including images
    @objc private func handleSendMessage() {
        guard let text = self.inputTextField.text else { return }
        let properties = ["text" : text]
        sendMessage(with: properties)
    }
    
    private func sendMessage(with imageUrl: String, _ image: UIImage) {
        let properties: [String : Any] = [
            "imageUrl" : imageUrl,
            "imageWidth" : image.size.width,
            "imageHeight" : image.size.height
        ]
        sendMessage(with: properties)
    }
    
    private func sendMessage(with properties: [String : Any]) {
        let messagesRef = Database.database().reference().child("messages").childByAutoId()
        guard
            let toId = partner?.id,
            let fromId = Auth.auth().currentUser?.uid else { return }
        let timestamp = Date().timeIntervalSince1970
        var values: [String : Any] = [
            "toId" : toId,
            "fromId" : fromId,
            "timestamp" : timestamp
        ]
        
        properties.forEach {
            values[$0] = $1
        }
        
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
    
    @objc fileprivate func handleUploadTap() {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK:- Regarding Setting views and Auto-layout methods
    fileprivate func setupCollectionView() {
        let guide = view.safeAreaLayoutGuide
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true  // Draggable
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
    }
    fileprivate func setupInputComponents() {
        view.addSubview(inputContainerView)
        // need x, y, w, h
        inputContainerView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor).isActive = true
        inputContainerView.widthAnchor.constraint(equalTo: collectionView.widthAnchor).isActive = true
        inputContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        inputContainerViewBottomAnchor = inputContainerView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        inputContainerViewBottomAnchor?.isActive = true
        
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = #imageLiteral(resourceName: "upload_image_icon")
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUploadTap))
        uploadImageView.addGestureRecognizer(tapRecognizer)
        uploadImageView.isUserInteractionEnabled = true
        
        let sendButton = UIButton(type: .system)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(handleSendMessage), for: .touchUpInside)
        
        let separatorLineView = UIView()
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        
        [uploadImageView, inputTextField, sendButton, separatorLineView].forEach {
            inputContainerView.addSubview($0)
        }
        // need x, y, w, h
        uploadImageView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // need x, y, w, h
        inputTextField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor).isActive = true
        
        // need x, y, w, h
        sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor).isActive = true
        
        // need x, y, w, h
        separatorLineView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: inputContainerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}

// MARK:- Regarding collectionView methods
extension ChatLogController: UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else {
            fatalError("Chat Log cell is bad.")
        }
        
        #warning("나중에 delegate 로 바꿔야 함")
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        cell.messageTextView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimatedFrame(for: text).width + 32
            cell.messageTextView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.messageTextView.isHidden = true
        }
        
        return cell
    }
    
    // MARK:- Custom zooming logic
    func performZoomIn(for startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        // 이미지 bumping 현상 방지
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        guard let startingFrame = startingFrame else { return }
        
        let zoomingImageView = UIImageView(frame: startingFrame)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut(_:))))
        
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        blackBackgroundView = UIView(frame: keyWindow.frame)
        guard let blackBackgroundView = blackBackgroundView else { return }
        blackBackgroundView.backgroundColor = .black
        blackBackgroundView.alpha = 0
        
        [blackBackgroundView, zoomingImageView].forEach {
            keyWindow.addSubview($0)
        }
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: .curveEaseOut,
            animations: {
                
                blackBackgroundView.alpha = 1
                self.inputContainerView.alpha = 0
                
                // scale math
                // h2 = h1 / w1 * w2
                let height = startingFrame.height / startingFrame.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
        }, completion: nil)
    }
    
    @objc func handleZoomOut(_ tapGesture: UITapGestureRecognizer) {
        guard let zoomOutImageView = tapGesture.view else { return }
        // cornerRadius issue 해결
        zoomOutImageView.layer.cornerRadius = 16
        zoomOutImageView.clipsToBounds = true
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: .curveEaseOut,
            animations: {
                
                guard let startingFrame = self.startingFrame else { return }
                zoomOutImageView.frame = startingFrame
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
        }) { (completed: Bool) in
            zoomOutImageView.removeFromSuperview()
            self.startingImageView?.isHidden = false
        }
    }
    
    func setupCell(cell: ChatMessageCell, message: Message) {
        guard let profileImageUrl = self.partner?.profileImageUrl else { return }
        cell.profileImageView.loadImageUsingCache(with: profileImageUrl)
        
        if message.fromId == Auth.auth().currentUser?.uid {
            // outgoing blue bubble
            cell.bubbleView.backgroundColor = ChatMessageCell.bubbleBlue
            cell.messageTextView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.profileWidth?.isActive = false
            cell.bubbleTrailingAnchor?.isActive = true
            cell.bubbleLeadingAnchor?.isActive = false
        } else {
            // incoming lightGray bubble
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.messageTextView.textColor = .black
            cell.profileImageView.isHidden = false
            cell.profileWidth?.isActive = true
            cell.bubbleTrailingAnchor?.isActive = false
            cell.bubbleLeadingAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCache(with: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = messages[indexPath.item].text {
            height = estimatedFrame(for: text).height + 20
        } else if
            let imageWidth = message.imageWidth,
            let imageHeight = message.imageHeight {
            
            // get h1 by equal ratio
            // h1 = h2 / w2 * w1
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        let width = view.frame.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        return NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
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
            handleSendMessage()
        }
        return true
    }
}

// MARK:- Regarding Image Picker
extension ChatLogController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoFileUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            
            handleVideoSelected(for: videoFileUrl)
            
        } else {
            
            handleImageSelected(for: info)
        }
       
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelected(for fileUrl: URL) {
        let videoName = UUID().uuidString + ".mov"
        let videoRef = Storage.storage().reference().child("message_videos").child(videoName)
        let uploadTask: StorageUploadTask = videoRef.putFile(from: fileUrl, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Upload video failed: ", error.localizedDescription)
                return
            }
            
            videoRef.downloadURL(completion: { [weak self] (url, err) in
                if let err = err {
                    print("Video download url is not proper: ", err.localizedDescription)
                    return
                }
                guard
                    let self = self,
                    let videoUrl = url?.absoluteString else { return }
                
                guard let thumbnailImage = self.thumbnailImage(for: fileUrl) else { return }
                
                self.uploadToFirebaseStorage(using: thumbnailImage, completion: { [weak self] (result) in
                    guard let self = self else { return }
                    switch result {
                    case .success(let imageUrl):
                        
                        let properties: [String : Any] = [
                            "imageUrl" : imageUrl,
                            "imageWidth" : thumbnailImage.size.width,
                            "imageHeight" : thumbnailImage.size.height,
                            "videoUrl" : videoUrl
                        ]
                        self.sendMessage(with: properties)
                    
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                })
            })
        }
        
        uploadTask.observe(.progress) { [weak self] (snapshot) in
            guard
                let self = self,
                let completedUnitCount = snapshot.progress?.completedUnitCount else {
                    return
            }
            self.navigationItem.title = String(completedUnitCount)
        }
        
        uploadTask.observe(.success) { [weak self] (snapshot) in
            guard let self = self else { return }
            self.navigationItem.title = self.partner?.name
        }
    }
    
    
    
    private func thumbnailImage(for videoFileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: videoFileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // CMTime(1, 60) : First frame of the video file of file url
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60),
                                                                  actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print(err.localizedDescription)
        }
        return nil
    }
    
    private func handleImageSelected(for info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            //            profileImageView.image = selectedImage
            uploadToFirebaseStorage(using: selectedImage) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let imageUrl):
                    self.sendMessage(with: imageUrl, selectedImage)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func uploadToFirebaseStorage(using image: UIImage, completion: @escaping (Result<String, Error>) -> ()) {
        let imageName = UUID().uuidString + ".png"
        let storageRef = Storage.storage().reference().child("message_images").child(imageName)
        
        guard let uploadData = image.jpegData(compressionQuality: 0.05) else {
            return
        }
        
        storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("@@ Message image upload error: \(error.localizedDescription)")
                return
            }
            print("!! Successfully put data to Firebase storage")
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("@@ Download url error: \(err.localizedDescription)")
                    return
                }
                guard let imageUrl = url?.absoluteString else { return }
                #warning("나중에 에러 핸들링 해야 함")
                completion(.success(imageUrl))
            }
        }
    }
}

// MARK:- Regarding Gesture Recognizer in order to resign keyboard
extension ChatLogController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

