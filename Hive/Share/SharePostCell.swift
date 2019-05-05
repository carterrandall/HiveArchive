//
//  SharePostCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-06.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit


protocol SharePostCellDelegate {
    func didHitShare(uid: Int)
    func didHitOpen(uid: Int)
}

class SharePostCell: UICollectionViewCell {
    
    var delegate: SharePostCellDelegate?
    
    var hasShared: Bool? {
        didSet {
            if let hasShared = hasShared, hasShared {
                shareButton.setTitle("Open", for: .normal)
                shareButton.titleLabel?.text = "Open"
                shareButton.backgroundColor = .mainBlue()
            } else {
                shareButton.setTitle("Send", for: .normal)
                shareButton.titleLabel?.text = "Send"
                shareButton.backgroundColor = .mainRed()
            }
        }
    }
    
    override func prepareForReuse() {
        shareButton.setTitle(nil, for: .normal)
        shareButton.titleLabel?.text = nil
        friend = nil
        hasShared = nil
        profileImageView.image = nil
        usernameLabel.text = nil
        nameLabel.text = nil
    }
    
    var friend: Friend? {
        didSet {
            guard let friend = friend else { return }
            self.profileImageView.profileImageCache(url: friend.profileImageUrl, userId: friend.uid)
            self.usernameLabel.text = friend.username
            self.nameLabel.text = friend.fullName
        }
    }

    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
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
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = .mainRed()
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShare() {
        
        guard let friend = friend else { return }
        
        if shareButton.titleLabel?.text == "Send" {
            shareButton.setTitle("Open", for: .normal)
            shareButton.backgroundColor = .mainBlue()
            delegate?.didHitShare(uid: friend.uid)
            
        } else {
            delegate?.didHitOpen(uid: friend.uid)
            shareButton.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.shareButton.isEnabled = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        let width = UIScreen.main.bounds.width
        let profileImagePadding = width * 0.04830917874
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: profileImagePadding, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(shareButton)
        shareButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 80, height: 25)
        shareButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(nameLabel)
        nameLabel.anchor(top: profileImageView.centerYAnchor, left: profileImageView.rightAnchor, bottom: nil, right: shareButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nameLabel.topAnchor, right: shareButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


