//
//  ChatMessageCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-12.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit



class ChatMessageCell: UITableViewCell {
    
    var leadingConstraint: NSLayoutConstraint!
    var leadingGroupConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    
    let bubbleBackgroundView = UIView()
    let messageLabel = UILabel()
    
    var message: Message? {
        didSet {
            guard let chatMessage = message, let isIncoming = message?.isIncoming else { return }
            
            bubbleBackgroundView.backgroundColor = isIncoming ? UIColor.rgb(red: 240, green: 240, blue: 240) : .mainBlue()
            messageLabel.textColor = isIncoming ? .black : .white
            
            if let deleted = message?.postDeleted {
                if deleted == 1 {
                    messageLabel.text = "(Post Removed)"
                } else if  deleted == 2 {
                    messageLabel.text = "(Post Expired)"
                } else {
                    messageLabel.text = " "
                }
            } else {
                messageLabel.text = chatMessage.text
            }
            
           if let width = chatMessage.text?.width(withContainedHeight: 1, font: UIFont.systemFont(ofSize: 16)) {
                let maxWidth = UIScreen.main.bounds.width * 0.6038647343
                if width > CGFloat(maxWidth) {
                   self.messageLabel.textAlignment = .left
                } else {
                    self.messageLabel.textAlignment = .center
                }
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
            } else if config == 1 {
                leadingConstraint.isActive = true
                leadingGroupConstraint.isActive = true
                trailingConstraint.isActive = false
            } else {
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
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.layer.cornerRadius = 20
        return iv
    }()
    
    override func prepareForReuse() {
        profileImageView.image = nil
        profileImageView.isHidden = true
        message = nil
        messageLabel.text = nil
        readReceipt.text = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        readReceipt.translatesAutoresizingMaskIntoConstraints = false
    
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        
        addSubview(bubbleBackgroundView)
        addSubview(messageLabel)
        addSubview(readReceipt)
        
        
        let maxWidth = UIScreen.main.bounds.width * 0.6038647343

        let constraints = [
            
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            messageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: frame.height - 8),
            
            bubbleBackgroundView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -8),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8),
            
            readReceipt.topAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: 4),
            readReceipt.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor),
            readReceipt.bottomAnchor.constraint(equalTo: bottomAnchor)
            
            ]
        
        NSLayoutConstraint.activate(constraints)
        
        leadingGroupConstraint = messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12)
        leadingGroupConstraint.isActive = false
        
        leadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        leadingConstraint.isActive = false
        
        trailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        trailingConstraint.isActive = true
        
        bubbleBackgroundView.layer.cornerRadius = (frame.height - 8) / 2
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
        profileImageView.centerYAnchor.constraint(equalTo: bubbleBackgroundView.centerYAnchor).isActive = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
