//
//  ShareLogCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-15.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ShareLogCellDelegate {
    func didHitShare(uid: Int)
    func didHitOpen(uid: Int)
    func didHitShareGroup(groupId: String)
    func didHitOpenGroup(groupId: String)
}

class ShareLogCell: UICollectionViewCell {
    
    var delegate: ShareLogCellDelegate?
    
    var log: LogMessage? {
        didSet {
            guard let log = log, let userOne = log.userOne else { return }
            
            profileImageView.profileImageCache(url: userOne.profileImageUrl, userId: userOne.uid)
            
            if let count = log.count {
                
                if (count - 3) != 0 {
                    usernameLabel.text = "\(userOne.username), \(log.secondusername) & \(count - 3) more"
                } else {
                    usernameLabel.text = "\(userOne.username) & \(log.secondusername)"
                }
                
                usernameLabel.numberOfLines = 3
                
                secondProfileImageView.profileImageCache(url: log.secondprofileImageUrl, userId: log.secondId)
                
                stackViewToSecondProfileImageConstaint.isActive = true
                stackViewToFirstProfileImageConstraint.isActive = false
                
            } else {
                
                usernameLabel.text = userOne.username
                nameLabel.text = userOne.fullName
                
                stackViewToSecondProfileImageConstaint.isActive = false
                stackViewToFirstProfileImageConstraint.isActive = true
            }
            
        }
    }
    
    var hasShared: Bool? {
        didSet {
            if let hasShared = hasShared, hasShared {
                shareButton.setTitle("Open", for: .normal)
                shareButton.titleLabel?.text = "Open"
                shareButton.layer.borderColor = UIColor.mainBlue().cgColor
                shareButton.setTitleColor(UIColor.mainBlue(), for: .normal)
            } else {
                shareButton.setTitle("Send", for: .normal)
                shareButton.titleLabel?.text = "Send"
                shareButton.layer.borderColor = UIColor.mainRed().cgColor
                shareButton.setTitleColor(UIColor.mainRed(), for: .normal)
            }
        }
    }
    
    override func prepareForReuse() {
        profileImageView.image = nil
        secondProfileImageView.image = nil
        hasShared = nil
        log = nil
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let secondProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.cornerRadius = 5
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShare() {
        
        guard let uid = log?.userOne?.uid else { return }
        
        if shareButton.titleLabel?.text == "Send" {
            shareButton.setTitle("Open", for: .normal)
            shareButton.layer.borderColor = UIColor.mainBlue().cgColor
            shareButton.setTitleColor(UIColor.mainBlue(), for: .normal)
            shareButton.setTitleColor(UIColor.mainBlue(), for: .disabled)
            if let groupId = log?.groupId, groupId != "" {
                delegate?.didHitShareGroup(groupId: groupId)
            } else {
                delegate?.didHitShare(uid: uid)
            }
            
        } else {
            if let groupId = log?.groupId, groupId != "" {
                delegate?.didHitOpenGroup(groupId: groupId)
            } else {
                delegate?.didHitOpen(uid: uid)
            }
            shareButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.shareButton.isEnabled = true
            }
        }
    }
    
    var stackViewToFirstProfileImageConstraint: NSLayoutConstraint!
    var stackViewToSecondProfileImageConstaint: NSLayoutConstraint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 25
        
        let whiteView = UIView()
        //whiteView.backgroundColor = .white
        insertSubview(whiteView, belowSubview: profileImageView)
        whiteView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 52, height: 52)
        whiteView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        whiteView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        whiteView.layer.cornerRadius = 26
        
        insertSubview(secondProfileImageView, belowSubview: whiteView)
        secondProfileImageView.anchor(top: nil, left: profileImageView.centerXAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        secondProfileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        secondProfileImageView.layer.cornerRadius = 25
        
        addSubview(shareButton)
        shareButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 80, height: 25)
        shareButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, nameLabel])
        stackView.axis = .vertical
        addSubview(stackView)
        
        stackView.anchor(top: nil, left: nil, bottom: nil, right: shareButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        stackViewToFirstProfileImageConstraint = stackView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        stackViewToSecondProfileImageConstaint = stackView.leftAnchor.constraint(equalTo: secondProfileImageView.rightAnchor, constant: 8)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
