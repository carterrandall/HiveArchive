//
//  ChatMessagePostCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-09.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

protocol ChatMessagePostCellDelegate {
    func didTapExpandPost(cell: ChatMessagePostCell)
}

class ChatMessagePostCell: UITableViewCell {
    
    var delegate: ChatMessagePostCellDelegate?
    
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    var leadingGroupConstraint: NSLayoutConstraint!
    
    var profileLeftConstraint: NSLayoutConstraint!
    var profileRightConstraint: NSLayoutConstraint!

    var isVideoPaused: Bool = false
    
    let bubbleBackgroundView = UIView()
    
    var message: Message? {
        didSet {
            
            guard let chatMessage = message, let imageUrl = message?.post?.imageUrl, let postId = message?.post?.id else { return }
         
            messageImageView.postImageCache(url: imageUrl, postId: postId)
            
            chatMessage.post?.videoUrl != nil ? (playButton.isHidden = false) : (playButton.isHidden = true)
            
           
            guard let profileImageUrl = chatMessage.post?.user?.profileImageUrl, let uid = chatMessage.post?.user?.uid else { return }
            self.profileImageView.profileImageCache(url: profileImageUrl, userId: uid) { (_) in
                self.profileImageContainerView.backgroundColor = .white
            }
            
        }
    }
    
    var constraintConfig: Int? {
        didSet {
            guard let config = constraintConfig else { return }
           
            if config == 0 {
                leadingConstraint.isActive = false
                leadingGroupConstraint.isActive = true
                trailingConstraint.isActive = false
                profileLeftConstraint.isActive = false
                profileRightConstraint.isActive = true
            } else if config == 1 {
                leadingConstraint.isActive = true
                leadingGroupConstraint.isActive = true
                trailingConstraint.isActive = false
                profileLeftConstraint.isActive = false
                profileRightConstraint.isActive = true
            } else {
                profileRightConstraint.isActive = false
                profileLeftConstraint.isActive = true
                senderImageView.isHidden = true
                trailingConstraint.isActive = true
                leadingConstraint.isActive = false
                leadingGroupConstraint.isActive = false
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
            print("Pausing video")
            isVideoPaused = true
            player?.pause()
            
            bubbleBackgroundView.bringSubviewToFront(expandButton)
        } else {
            print("playing videooooo")
            isVideoPaused = false
            player?.play()
        }
    
    }
    
    @objc func handlePlay() {
        print("PLAYING")
        if isVideoPaused {
            player?.play()
            
        } else {
            
            DispatchQueue.main.async {
                if let videoUrl = self.message?.post?.videoUrl {
                    self.activityIndicatorView.startAnimating()

                    self.player = AVPlayer(url: videoUrl)
                    
                    self.playerLayer = AVPlayerLayer(player: self.player)
                    self.playerLayer?.videoGravity = .resizeAspectFill
                    self.playerLayer?.frame = self.messageImageView.bounds
                    self.bubbleBackgroundView.layer.addSublayer(self.playerLayer!)
                    
                    self.playButton.isHidden = true
                    
                    self.player?.play()
                    self.activityIndicatorView.stopAnimating()

                    self.bubbleBackgroundView.addSubview(self.pausePlayButton)
                    self.pausePlayButton.anchor(top: self.bubbleBackgroundView.topAnchor, left: self.bubbleBackgroundView.leftAnchor, bottom: self.bubbleBackgroundView.bottomAnchor, right: self.bubbleBackgroundView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
                    self.playerLayer?.name = "playerLayer"
                }
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
        
        print("here1")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
        }
        
        backgroundColor = .clear
        
        addSubview(senderImageView)
        
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageImageView)
        
        addSubview(readReceipt)
        readReceipt.translatesAutoresizingMaskIntoConstraints = false
        
        let maxWidth = UIScreen.main.bounds.width * 0.6038647343
        let constraints = [
            
            messageImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageImageView.widthAnchor.constraint(equalToConstant: maxWidth),
            messageImageView.heightAnchor.constraint(equalToConstant: maxWidth * (4/3)),
            
            bubbleBackgroundView.topAnchor.constraint(equalTo: messageImageView.topAnchor, constant: 0),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageImageView.leadingAnchor, constant: 0),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageImageView.trailingAnchor, constant: 0),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 0),
            
            readReceipt.topAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: 4),
            readReceipt.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor),
            readReceipt.bottomAnchor.constraint(equalTo: bottomAnchor)
            
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        leadingGroupConstraint = messageImageView.leadingAnchor.constraint(equalTo: senderImageView.trailingAnchor, constant: 12)
        leadingGroupConstraint.isActive = false
        
        leadingConstraint = messageImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        leadingConstraint.isActive = false
        
        trailingConstraint = messageImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        trailingConstraint.isActive = true
        
        
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
        profileImageView.centerXAnchor.constraint(equalTo: profileImageContainerView.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
        
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
