//
//  ChooseFriendCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-22.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class ChooseFriendCell: UICollectionViewCell {
    
    var nameLabelToRightAnchor: NSLayoutConstraint!
    var nameLabelToButtonAnchor: NSLayoutConstraint!
    var user: User? {
        didSet {
            guard let user = user else { return }
            profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
            usernameLabel.text = user.username
            nameLabel.text = user.fullName
            if let sharing = user.sharingLocation, sharing {
                nameLabelToRightAnchor.isActive = false
                nameLabelToButtonAnchor.isActive = true
                showingButton.isHidden = false
            } else {
                nameLabelToRightAnchor.isActive = true
                nameLabelToButtonAnchor.isActive = false
                disabledButton()
            }

        }
    }
    
    override func prepareForReuse() {
        profileImageView.image = nil
        user = nil
        nameLabel.text = nil
        usernameLabel.text = nil
        showingButton.isHidden = true
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let showingButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .mainRed()
        button.setTitle("Enabled", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.addTarget(self, action: #selector(handleStopSharingLocation), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    fileprivate func disabledButton(){
        user?.sharingLocation = false
        showingButton.addTarget(self, action: #selector(handleStartSharingLocation), for: .touchUpInside)
        showingButton.setTitle("Disabled", for: .normal)
        showingButton.setTitleColor(UIColor.lightGray  , for: .normal)
        
    }
    fileprivate func enabledButton(){
        user?.sharingLocation = true
        // ^^^^^^ This is the part where I need you to set this on the user ovject in the thing.
        showingButton.addTarget(self, action: #selector(handleStopSharingLocation), for: .touchUpInside)
        showingButton.setTitle("Enabled", for: .normal)
        showingButton.setTitleColor(UIColor.mainRed(), for: .normal)
    }
    
    
    
    @objc fileprivate func handleStopSharingLocation(){
        // set the user attribute to true probably, although not sure how to do that and shit. (should be the same user both spots I assume though).
        print("stop sharing location")
        if let uid = self.user?.uid {
            MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/stopSharingLocationWithUser", params: ["UID":uid]) { (response) in
                if response.response?.statusCode == 200 {
                    self.disabledButton()
                }
            }
            
        }
    }
    
    @objc fileprivate func handleStartSharingLocation(){
        if let uid = self.user?.uid {
            MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/startSharingLocationWithUser", params: ["UID":uid]) { (response) in
                if response.response?.statusCode == 200 {
                    self.enabledButton()
                }
            }
            
        }
    }
    
    
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let profileDim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        profileImageView.layer.cornerRadius = profileDim / 2
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: profileDim, height: profileDim)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(showingButton)
        showingButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 80, height: 40)
        showingButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        showingButton.isHidden = true
        
        
        addSubview(nameLabel)
        nameLabel.anchor(top: profileImageView.centerYAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        nameLabelToRightAnchor = nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        nameLabelToRightAnchor.isActive = false
        
        nameLabelToButtonAnchor = nameLabel.rightAnchor.constraint(equalTo: showingButton.leftAnchor, constant: -8)
        nameLabelToButtonAnchor.isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nameLabel.topAnchor, right: nameLabel.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
