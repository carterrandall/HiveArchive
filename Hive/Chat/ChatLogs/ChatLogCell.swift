//
//  ChatLogCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class ChatLogCell: UITableViewCell {
    
    var usernameToFirstProfileImageConstraint: NSLayoutConstraint!
    var usernameToSecondProfileImageConstaint: NSLayoutConstraint!
    
    var logMessage: LogMessage? {
        didSet {
            guard let log = logMessage, let message = log.message, let userOne = log.userOne else { return }

            if message.text != nil, message.text != "" {
                messageLabel.text = message.text
            } else if let postUsername = log.postUsername {
                let lastChar = postUsername.last
                messageLabel.text = "Shared \(postUsername)\(lastChar == "s" ? "'" : "'s") post."
            } else if logMessage?.pid != nil {
                messageLabel.text = "Shared a post."
            } else {
                messageLabel.text = ""
            }
            
            sentDateLabel.text = message.sentDate.timeAgoDisplay()
            
            if let count = log.count, count > 1 {
                if (count - 2) > 0 {
                    usernameLabel.text = "\(userOne.username), \(log.secondusername) & \(count - 2) more"
                } else {
                    usernameLabel.text = "\(userOne.username) & \(log.secondusername)"
                }
                
                usernameToSecondProfileImageConstaint.isActive = true
                usernameToFirstProfileImageConstraint.isActive = false
                
                profileImageView.profileImageCache(url: userOne.profileImageUrl, userId: userOne.uid)
                
                secondProfileImageView.profileImageCache(url: log.secondprofileImageUrl, userId: log.secondId)
                
            } else {
                
                usernameLabel.text = userOne.username
                
                usernameToSecondProfileImageConstaint.isActive = false
                usernameToFirstProfileImageConstraint.isActive = true
                
                profileImageView.profileImageCache(url: userOne.profileImageUrl, userId: userOne.uid)
              
            }
            
        }
    }
    
    var showNotificationView: Bool? {
        didSet {
            if let showNotification = showNotificationView, showNotification {
                notificationView.isHidden = false
            } else {
                notificationView.isHidden = true
            }
        }
    }
    
    override func prepareForReuse() {
        
        profileImageView.image = nil
        secondProfileImageView.image = nil
        usernameLabel.text = nil
        sentDateLabel.text = nil
        messageLabel.text = nil
        logMessage = nil
        showNotificationView = nil
    }
    
   
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 30
        return iv
    }()
    
    let secondProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 30
        
        return iv
    }()
    
    let notificationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.mainRed()
        view.layer.cornerRadius = 7
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        return view
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.numberOfLines = 2
        return label
    }()
    
    let sentDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: UIScreen.main.bounds.width <  375 ? 10 : 20, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let whiteView = UIView()
        whiteView.backgroundColor = .white
        whiteView.layer.cornerRadius = 31
        insertSubview(whiteView, belowSubview: profileImageView)
        whiteView.anchor(top: nil, left: profileImageView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 62, height: 62)
        whiteView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
       
        insertSubview(secondProfileImageView, belowSubview: whiteView)
        secondProfileImageView.anchor(top: nil, left: profileImageView.centerXAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft:0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        secondProfileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(notificationView)
        notificationView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 14, height: 14)
        let padding: CGFloat = -(CGFloat(30) * cos((CGFloat.pi / 4)))
        notificationView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor, constant: padding).isActive = true
        notificationView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: padding).isActive = true
        
        addSubview(sentDateLabel)
        sentDateLabel.anchor(top: profileImageView.topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)

        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.topAnchor, left: nil, bottom: nil, right: sentDateLabel.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
    
        usernameToFirstProfileImageConstraint = usernameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        usernameToFirstProfileImageConstraint.isActive = true
        
        usernameToSecondProfileImageConstaint = usernameLabel.leftAnchor.constraint(equalTo: secondProfileImageView.rightAnchor, constant: 8)
        usernameToSecondProfileImageConstaint.isActive = false
        
        addSubview(messageLabel)
        messageLabel.anchor(top: usernameLabel.bottomAnchor, left: usernameLabel.leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0.5)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
