//
//  HivePreviewCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-31.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

protocol HivePreviewCellDelegate: class {
    func closePreview()
    func showProfileCell(user: User)
}

class HivePreviewCell: UICollectionViewCell {
    
    weak var delegate: HivePreviewCellDelegate?
    
    var post: Post? {
        didSet {
            guard let post = post, post.id != -1 else { return }
        
            postImageView.postImageCache(url: post.imageUrl, postId: post.id)
            
            if let user = post.user {
                profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid) { (_) in
                    self.profileImageContainerView.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
                }
                
                usernameLabel.text = user.username
            }
        }
    }
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    func handlePlay() {
        DispatchQueue.main.async {
            if let videoUrl = self.post?.videoUrl {
                self.activityIndicatorView.isHidden = false
                self.activityIndicatorView.startAnimating()
                self.player = AVPlayer(url: videoUrl)
                
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.videoGravity = .resizeAspect
                self.playerLayer?.frame = self.containerView.bounds
                
                self.containerView.layer.addSublayer(self.playerLayer!)
                
                self.activityIndicatorView.stopAnimating()
                self.activityIndicatorView.isHidden = true
                self.playerLayer?.name = "playerLayer"
                self.player?.play()
                
            }
        }
        
    }
    
    override func prepareForReuse() {
        post = nil
        postImageView.image = nil
        profileImageView.image = nil
        usernameLabel.text = nil
        activityIndicatorView.isHidden = true
        if let sublayers = containerView.layer.sublayers {
            for layer in sublayers {
                if layer.name == "playerLayer" {
                    layer.removeFromSuperlayer()
                    return
                }
            }
        }
    }
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        return aiv
    }()
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 2
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let profileImageContainerView = UIView()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return label
    }()
    
    let containerView: UIView = {
        let cv = UIView()
        cv.layer.cornerRadius = 2
        cv.layer.masksToBounds = true
        cv.clipsToBounds = true
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width: CGFloat = (frame.width - 20)
        let height: CGFloat = (width) * (4/3)
        addSubview(containerView)
        containerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: width, height: height)
        containerView.addSubview(postImageView)
        postImageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: height)
        
        let downGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDown))
        downGesture.direction = .down
        postImageView.addGestureRecognizer(downGesture)
        
        addSubview(profileImageContainerView)
        profileImageContainerView.layer.cornerRadius = 20
        profileImageContainerView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 14, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.centerXAnchor.constraint(equalTo: profileImageContainerView.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 20
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 14, width: 0, height: 0)
        usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        let profileButton = UIButton()
        profileButton.addTarget(self, action: #selector(handleProfile), for: .touchUpInside)
        
        addSubview(profileButton)
        profileButton.anchor(top: topAnchor, left: profileImageView.leftAnchor, bottom: nil, right: usernameLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        containerView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
        activityIndicatorView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        activityIndicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func handleDown() {
        delegate?.closePreview()
    }
    
    @objc fileprivate func handleProfile() {
        guard let user = self.post?.user else { return }
        delegate?.showProfileCell(user: user)
    }
    
}
