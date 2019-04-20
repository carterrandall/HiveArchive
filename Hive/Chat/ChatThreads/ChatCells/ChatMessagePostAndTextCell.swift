//
//  ChatMessagePostAndTextCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-11-08.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

protocol ChatMessagePostAndTextCellDelegate {
    func didTapExpandPost(cell: ChatMessagePostAndTextCell)
}

class ChatMessagePostAndTextCell: UITableViewCell {
    
    var delegate: ChatMessagePostAndTextCellDelegate?
    
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    
    var leadingGroupConstraint: NSLayoutConstraint!
    var leadingGroupTextConstraint: NSLayoutConstraint!
    
    var textLeadingConstraint: NSLayoutConstraint!
    var textTrailingConstraint: NSLayoutConstraint!
    
    var profileLeftConstraint: NSLayoutConstraint!
    var profileRightConstraint: NSLayoutConstraint!
    
    var isVideoPaused: Bool = false
    
    let bubbleBackgroundView = UIView()
    let messageLabel = UILabel()
    
    var message: Message? {
        didSet {
            
            guard let chatMessage = message, let isIncoming = message?.isIncoming, let imageUrl = message?.post?.imageUrl, let postId = message?.post?.id else { return }
            
            bubbleBackgroundView.backgroundColor = isIncoming ? UIColor.rgb(red: 240, green: 240, blue: 240) : .mainBlue()
            messageLabel.textColor = isIncoming ? .black: .white
            
            messageImageView.postImageCache(url: imageUrl, postId: postId)
            
            chatMessage.post?.videoUrl != nil ? (playButton.isHidden = false) : (playButton.isHidden = true)
            
            chatMessage.text != nil ? (messageLabel.text = chatMessage.text) : (messageLabel.removeFromSuperview())
            
            guard let profileImageUrl = chatMessage.post?.user?.profileImageUrl, let uid = chatMessage.post?.user?.uid else { return }
            self.profileImageView.profileImageCache(url: profileImageUrl, userId: uid) { (_) in
                self.profileImageContainerView.backgroundColor = .white
            }
        
            if let width = chatMessage.text?.width(withContainedHeight: 1, font: UIFont.systemFont(ofSize: 16)) {
                let maxWidth = UIScreen.main.bounds.width * 0.6038647343
                if width > CGFloat(maxWidth) {
                    self.messageLabel.textAlignment = .left
                } else {
                    self.messageLabel.textAlignment = .center
                }
            }
//
        }
    }
    
    var constraintConfig: Int? {
        didSet {
            guard let config = constraintConfig else { return }
            
            if config == 0 {
                leadingConstraint.isActive = false
                trailingConstraint.isActive = false
                leadingGroupConstraint.isActive = true
                leadingGroupTextConstraint.isActive = true
                textLeadingConstraint.isActive = false
                textTrailingConstraint.isActive = false
                profileRightConstraint.isActive = true
                profileLeftConstraint.isActive = false
            } else if config == 1 {
                leadingConstraint.isActive = true
                trailingConstraint.isActive = false
                leadingGroupConstraint.isActive = false
                leadingGroupTextConstraint.isActive = false
                textLeadingConstraint.isActive = true
                textTrailingConstraint.isActive = false
                profileRightConstraint.isActive = true
                profileLeftConstraint.isActive = false
            } else {
                leadingConstraint.isActive = false
                trailingConstraint.isActive = true
                leadingGroupConstraint.isActive = false
                leadingGroupTextConstraint.isActive = false
                textLeadingConstraint.isActive = false
                textTrailingConstraint.isActive = true
                profileRightConstraint.isActive = false
                profileLeftConstraint.isActive = true
            }
            
        }
    }
    
    var readReceiptTime: Date? {
        didSet {
            if let time = readReceiptTime {
                readReceipt.isHidden = false
                readReceipt.text = "Read \(time.timeAgoDisplay())"
            } else {
                readReceipt.isHidden = true
            }
        }
    }
    
    let readReceipt: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    
    lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleExpand), for: .touchUpInside)
        button.setShadow(offset: .zero, opacity: 0.2, radius: 2, color: UIColor.black)
        return button
    }()
    
    @objc func handleExpand() {
        player?.pause()
        delegate?.didTapExpandPost(cell: self)
    }
    
    let messageImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        return iv
    }()
    
    let profileImageContainerView = UIView()
    
    let senderImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.layer.cornerRadius = 20
        return iv
    }()
    
    lazy var playButton: UIButton = { //handles initial play
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "video"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        
        return button
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        return aiv
    }()
    
    lazy var pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(handlePausePlay), for: .touchUpInside)
        return button
    }()
    
    @objc func handlePausePlay() {
        
        if !isVideoPaused {
            
            isVideoPaused = true
            player?.pause()
            
            bubbleBackgroundView.bringSubviewToFront(expandButton)
        } else {
         
            isVideoPaused = false
            player?.play()
        }
        
        
    }
    
    @objc func handlePlay() {
        
        if isVideoPaused {
            player?.play()
            
        } else {
            
            if let videoUrl = message?.post?.videoUrl {
                activityIndicatorView.startAnimating()
                player = AVPlayer(url: videoUrl)
                
                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.videoGravity = .resizeAspectFill
                playerLayer?.frame = messageImageView.bounds
                bubbleBackgroundView.layer.addSublayer(playerLayer!)
                
                playButton.isHidden = true
                
                
                player?.play()
                activityIndicatorView.stopAnimating()
                bubbleBackgroundView.addSubview(pausePlayButton)
                pausePlayButton.anchor(top: bubbleBackgroundView.topAnchor, left: bubbleBackgroundView.leftAnchor, bottom: bubbleBackgroundView.bottomAnchor, right: bubbleBackgroundView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
                
                self.playerLayer?.name = "playerLayer"
                
            }
            
            
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        readReceipt.text = nil
        messageImageView.image = nil
        message = nil 
        activityIndicatorView.stopAnimating()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        pausePlayButton.removeFromSuperview()
        isVideoPaused = false
        profileImageContainerView.backgroundColor = .clear
        
        if let sublayers = bubbleBackgroundView.layer.sublayers {
            for layer in sublayers {
                if layer.name == "playerLayer" {
                    layer.removeFromSuperlayer()
                    return
                }
            }
        }
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        print("here")
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
        }
        
        backgroundColor = .clear
        
        addSubview(senderImageView)
        
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageLabel)
        bubbleBackgroundView.addSubview(messageImageView)/////
        
        addSubview(readReceipt)
        readReceipt.translatesAutoresizingMaskIntoConstraints = false
        
        let maxWidth = UIScreen.main.bounds.width * 0.6038647343
        
        let constraints = [
            
            messageImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageImageView.widthAnchor.constraint(equalToConstant: maxWidth),
            messageImageView.heightAnchor.constraint(equalToConstant: maxWidth * (4/3)),
            
            messageLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 12),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            messageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: frame.height - 8),
            
            bubbleBackgroundView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -8),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -8),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            
            readReceipt.topAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: 4),
            readReceipt.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor),
            readReceipt.bottomAnchor.constraint(equalTo: bottomAnchor)
            
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        leadingGroupConstraint = messageImageView.leadingAnchor.constraint(equalTo: senderImageView.trailingAnchor, constant: 12)
        leadingGroupConstraint.isActive = false
        
        leadingGroupTextConstraint = messageLabel.leadingAnchor.constraint(equalTo: senderImageView.trailingAnchor, constant: 20)
        leadingGroupTextConstraint.isActive = false
        
        leadingConstraint = messageImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        leadingConstraint.isActive = false
        
        trailingConstraint = messageImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        trailingConstraint.isActive = true
        
        textLeadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        textLeadingConstraint.isActive = false
        
        textTrailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        textTrailingConstraint.isActive = true
        
        
        addSubview(expandButton)
        expandButton.anchor(top: messageImageView.topAnchor, left: messageImageView.leftAnchor, bottom: messageImageView.bottomAnchor, right: messageImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(playButton)
        playButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        playButton.centerYAnchor.constraint(equalTo: messageImageView.centerYAnchor).isActive = true
        playButton.centerXAnchor.constraint(equalTo: messageImageView.centerXAnchor).isActive = true
        
        addSubview(activityIndicatorView)
        activityIndicatorView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        activityIndicatorView.centerXAnchor.constraint(equalTo: messageImageView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: messageImageView.centerYAnchor).isActive = true
        
        senderImageView.anchor(top: nil, left: leftAnchor, bottom: messageImageView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
        
        profileImageContainerView.layer.cornerRadius = 27
        addSubview(profileImageContainerView)
        profileImageContainerView.anchor(top: messageImageView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: -12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 54, height: 54)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: messageImageView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: -10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: profileImageContainerView.centerXAnchor).isActive = true
        
        profileLeftConstraint = profileImageContainerView.leftAnchor.constraint(equalTo: messageImageView.leftAnchor, constant: -12)
        profileLeftConstraint.isActive = true
        profileRightConstraint = profileImageContainerView.rightAnchor.constraint(equalTo: messageImageView.rightAnchor, constant: 12)
        profileRightConstraint.isActive = false
        
        
        bubbleBackgroundView.layer.cornerRadius = (frame.height - 8) / 2
        messageImageView.layer.cornerRadius = 2
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
