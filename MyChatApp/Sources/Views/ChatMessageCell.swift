//
//  ChatMessageCell.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 01/03/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
    
    weak var message: Message?
    
    weak var chatLogController: ChatLogController?
    
    static let bubbleBlue = UIColor(r: 0, g: 137, b: 249)
    
    let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handlePlayVideo), for: .touchUpInside)
        return button
    }()
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    lazy var messageImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap(_:))))
        return iv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = bubbleBlue
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleTrailingAnchor: NSLayoutConstraint?
    var bubbleLeadingAnchor: NSLayoutConstraint?
    var profileWidth: NSLayoutConstraint?
    
    let messageTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.isUserInteractionEnabled = false
        tv.isEditable = false
        return tv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        [profileImageView, bubbleView, messageTextView].forEach {
            addSubview($0)
        }
        
        [messageImageView, playButton, indicatorView].forEach {
            bubbleView.addSubview($0)
        }
        
        // need x, y, w, h
        // set width anchor inside ChatLogController
        profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        profileWidth = profileImageView.widthAnchor.constraint(equalToConstant: 32)
        profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
        
        // need x, y, w, h
        // set leading and trailing anchor inside ChatLogController
        bubbleLeadingAnchor = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        bubbleTrailingAnchor = bubbleView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8)
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        // need x, y, w, h
        messageTextView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8).isActive = true
        messageTextView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        messageTextView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
        messageTextView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        // x, y, w, h
        messageImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        
        // after messageImageView
        playButton.centerInSuperview(size: CGSize(width: 50, height: 50))
        
        indicatorView.centerInSuperview()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- Handling methods
    @objc fileprivate func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
        if message?.videoUrl != nil {
            return
        }
        
        // PRO tip: Don't perform a lot of custom logic inside of a view class
        guard let imageView = tapGesture.view as? UIImageView else { return }
        self.chatLogController?.performZoomIn(for: imageView)
    }
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    @objc fileprivate func handlePlayVideo() {
        guard
            let videoUrl = message?.videoUrl,
            let url = URL(string: videoUrl) else { return }
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        guard
            let playerLayer = playerLayer,
            let player = player else { return }
        
        playerLayer.frame = bubbleView.bounds
        bubbleView.layer.addSublayer(playerLayer)
        
        player.play()
        
        indicatorView.startAnimating()
        playButton.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        guard
            let playerLayer = playerLayer,
            let player = player else { return }
        
        playerLayer.removeFromSuperlayer()
        player.pause()
        indicatorView.stopAnimating()
    }
}

