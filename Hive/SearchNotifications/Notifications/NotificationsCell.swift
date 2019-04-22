//
//  NotificationsCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol NotificationsCellDelegate {
    func showProfile(user: User)
    func showPost(cell: NotificationsCell)
}

class NotificationsCell: UITableViewCell {
    
    var textLabelToRightAnchor: NSLayoutConstraint!
    var textLabelToPostLeftAnchor: NSLayoutConstraint!
    
    var delegate: NotificationsCellDelegate?
    
    var notification: HiveNotification? {
        didSet {
            guard let notification = notification else { return }
            
            profileImageView.profileImageCache(url: notification.profileImageUrl, userId: notification.uid)
            
            let attributedString = NSMutableAttributedString(string: notification.username, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
            let attributes =  [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]
            
            switch notification.type {
            case 1:
                
                textLabelToPostLeftAnchor.isActive = true
                textLabelToRightAnchor.isActive = false
                postView.isHidden = false
                attributedString.append(NSAttributedString(string: " secret liked your post.", attributes: attributes))
                
                if let post = notification.post {
                    postView.postImageCache(url: post.imageUrl, postId: post.id)
                }
                
            case 2:
                textLabelToPostLeftAnchor.isActive = true
                textLabelToRightAnchor.isActive = false
                postView.isHidden = false
                
                attributedString.append(NSAttributedString(string: " commented on your post: '\(notification.message)'." , attributes: attributes))
                
                if let post = notification.post {
                    postView.postImageCache(url: post.imageUrl, postId: post.id)
                }
                
            case 3:
                
                textLabelToPostLeftAnchor.isActive = false
                textLabelToRightAnchor.isActive = true
                postView.isHidden = true
                
                attributedString.append(NSAttributedString(string: " accepted your friend request.", attributes: attributes))
                
            case 4:
                textLabelToPostLeftAnchor.isActive = true
                textLabelToRightAnchor.isActive = false
                postView.isHidden = false
                
                attributedString.append(NSAttributedString(string: " tagged you in a comment: '\(notification.message)'." , attributes: attributes))
                
                if let post = notification.post {
                    postView.postImageCache(url: post.imageUrl, postId: post.id)
                }
            case 5:
                textLabelToPostLeftAnchor.isActive = true
                textLabelToRightAnchor.isActive = false
                postView.isHidden = false
                attributedString.append(NSAttributedString(string: " tagged you in a post.", attributes: attributes))
                if let post = notification.post {
                    postView.postImageCache(url: post.imageUrl, postId: post.id)
                }
                
            default:
                break
            }
            
            attributedString.append(NSAttributedString(string: "\n" + notification.creationDate.timeAgoDisplay(), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
            
            notificationLabel.attributedText = attributedString
            
            if !notification.seen {
                notificationView.isHidden = false
            } else {
                notificationView.isHidden = true
            }
        }
    }
    
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 30
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let notificationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    let notificationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.mainRed()
        view.layer.cornerRadius = 7
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    let postView: CustomImageView = {
        let pv = CustomImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        pv.layer.cornerRadius = 2
        pv.isUserInteractionEnabled = true
        return pv
    }()
    
    override func prepareForReuse() {
        postView.image = nil
        profileImageView.image = nil
        notificationLabel.text = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        
        let dim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        profileImageView.layer.cornerRadius = dim / 2
        addSubview(profileImageView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfile))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: dim, height: dim)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(postView)
        let postTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleShowPost))
        postView.addGestureRecognizer(postTapGesture)
        postView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: dim, height: dim)
        postView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(notificationView)
        notificationView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 14, height: 14)
        let padding: CGFloat = -(CGFloat(30) * cos((CGFloat.pi / 4)))
        
        notificationView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor, constant: padding).isActive = true
        notificationView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: padding).isActive = true
        
        addSubview(notificationLabel)
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        notificationLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        notificationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        notificationLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: dim).isActive = true
        
        textLabelToRightAnchor = notificationLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        textLabelToRightAnchor.isActive = false
        
        textLabelToPostLeftAnchor = notificationLabel.rightAnchor.constraint(equalTo: postView.leftAnchor, constant: -8)
        textLabelToPostLeftAnchor.isActive = true
        
        backgroundColor = .white
    }
    
    @objc fileprivate func handleProfile() {
        guard let id = notification?.uid, let username = notification?.username, let fullName = notification?.fullName, let profileImageUrl = notification?.profileImageUrl.absoluteString else { return }
        let user = User(dictionary: ["id": id, "username": username, "fullName": fullName, "profileImageUrl": profileImageUrl])
        delegate?.showProfile(user: user)
    }
    
    @objc fileprivate func handleShowPost() {
        
        delegate?.showPost(cell: self)
    }
    
}
