//
//  ChatMessageCell.swift
//  MyMessenger
//
//  Created by Jinwoo Kim on 01/03/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import AVFoundation

protocol ChatMessageCollectionViewCellDelegate: class {
    func performZoomIn(for startingImageView: UIImageView)
}

class ChatMessageCollectionViewCell: UICollectionViewCell {
    
    // MARK:- Properties
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    weak var message: Message?
    weak var delegate: ChatMessageCollectionViewCellDelegate?
    
    // MARK:- Screen properties
    private let indicatorView: UIActivityIndicatorView = {
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
        view.backgroundColor = .bubbleBlue
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
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
    
    // MARK:- LayoutConstraint properties
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleTrailingAnchor: NSLayoutConstraint?
    var bubbleLeadingAnchor: NSLayoutConstraint?
    var profileWidth: NSLayoutConstraint?
    
    // MARK:- Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        [profileImageView, bubbleView, messageTextView].forEach {
            addSubview($0)
        }
        
        [messageImageView, playButton, indicatorView].forEach {
            bubbleView.addSubview($0)
        }
        
        // need x, y, w, h
        // set width anchor inside ChatRoomViewController
        profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        profileWidth = profileImageView.widthAnchor.constraint(equalToConstant: 32)
        profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
        
        // need x, y, w, h
        // set leading and trailing anchor inside ChatRoomViewController
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
    
    // MARK: - Methods
    
//    private func initializeLayout() {
//        self.addSubviews([
//            self.profileImageView,
//            self.bubbleView,
//            self.messageTextView
//        ])
//        
//        self.bubbleView.addSubviews([
//            self.messageImageView,
//            self.playButton,
//            self.indicatorView
//        ])
//        
//        self.profileImageView.snp.makeConstraints {
//            $0.leading.equalToSuperview().offset(8)
//            $0.centerY.equalTo(self.bubbleView.snp.centerY)
//            $0.height.equalTo(self.profileImageView.snp.width)
//        }
//        
//        self.profileWidthConstraint = self.profileImageView.widthAnchor.constraint(equalToConstant: 32)
//        
//        self.bubbleView.snp.makeConstraints {
//            $0.top.equalToSuperview()
//            $0.height.equalToSuperview()
//        }
//        
//        self.bubbleLeadingConstraint = self.bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
//        self.bubbleTrailingConstraint = self.bubbleView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8)
//        self.bubbleWidthConstraint = self.bubbleView.widthAnchor.constraint(equalToConstant: 200)
//        self.bubbleWidthConstraint?.isActive = true
//        
//        self.messageTextView.snp.makeConstraints {
//            $0.top.height.equalToSuperview()
//            $0.leading.trailing.equalTo(self.bubbleView).inset(8)
//        }
//        
//        self.messageImageView.snp.makeConstraints {
//            $0.edges.equalTo(self.bubbleView)
//        }
//        
//        self.playButton.snp.makeConstraints {
//            $0.center.equalToSuperview()
//            $0.size.equalTo(CGSize(all: 50))
//        }
//        
//        self.indicatorView.snp.makeConstraints {
//            $0.center.equalToSuperview()
//        }
//    }
    
    @objc fileprivate func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
        if message?.videoUrl != nil {
            return
        }
        
        // PRO tip: Don't perform a lot of custom logic inside of a view class
        guard let imageView = tapGesture.view as? UIImageView else { return }
        self.delegate?.performZoomIn(for: imageView)
    }
    
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
    
    // In order to fix cell reuse issues^^
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

