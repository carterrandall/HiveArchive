//
//  FriendCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-11-09.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol FriendCellDelegate {
    func didChangeFriendStatus(cell: FriendCell, newFriendStatus: Int) //used only by profile, no button is avail in friends search
    func showProfile(cell: FriendCell)
}

class FriendCell: UICollectionViewCell {
    
    var nameLabelToRightAnchor: NSLayoutConstraint!
    var nameLabelToButtonAnchor: NSLayoutConstraint!
    
    var delegate: FriendCellDelegate?
    
    var friend: Friend? {
        didSet {
            
            nameLabel.text = friend?.fullName
            usernameLabel.text = friend?.username
            
            guard let profileImageUrl = friend?.profileImageUrl else { return }
            guard let fid = friend?.uid else {return}
            profileImageView.profileImageCache(url: profileImageUrl, userId: fid)
           
            if let friendStatus = friend?.friendStatus {
                
                if friendStatus == 0 {
                    nameLabelToRightAnchor.isActive = true
                    nameLabelToButtonAnchor.isActive = false
                } else {
                    nameLabelToRightAnchor.isActive = false
                    nameLabelToButtonAnchor.isActive = true
                }
                
                switch friendStatus {
                case 0:
                    friendActionButton.isHidden = true
                case 1:
                    friendActionButton.isHidden = false
                    friendActionButton.titleLabel?.text = "Pending"
                    friendActionButton.setTitle("Pending", for: .normal)
                case 2:
                    friendActionButton.isHidden = false
                    friendActionButton.titleLabel?.text = "Accept"
                    friendActionButton.setTitle("Accept", for: .normal)
                default:
                    friendActionButton.isHidden = false
                    friendActionButton.titleLabel?.text = "Add"
                    friendActionButton.setTitle("Add", for: .normal)
                }
                
            }
            
        }
    }
    
   
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.backgroundColor = .white
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    lazy var profileButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowProfile), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShowProfile() {
        delegate?.showProfile(cell: self)
    }
    
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
    
    lazy var friendActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.mainRed(), for: .normal)
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleSendUpdateFriendStatus), for: .touchUpInside)
        return button
    }()
    
    override func prepareForReuse() {
        friendActionButton.setTitle("", for: .normal)
        friendActionButton.titleLabel?.text = nil
        profileImageView.image = nil
        friend = nil
    }
    
    @objc func handleSendUpdateFriendStatus() {
        guard let friend = friend else { return }
        let friendStatus = friend.friendStatus
        var newFriendStatus: Int!
        //if friend status == 0, no button, users already friends
        if friendStatus == 1 { //current user requested, cancel request
            friendActionButton.setTitle("Add", for: .normal)
            self.friend?.friendStatus = 3
            newFriendStatus = 3
            
        } else if friendStatus == 2 { //other user requested, accept request
            friendActionButton.setTitle("Added", for: .normal)
            self.friend?.friendStatus = 0
            newFriendStatus = 0
            
        } else if friendStatus == 3 { //no requests, send request
            friendActionButton.setTitle("Pending", for: .normal)
            self.friend?.friendStatus = 1 //does using self inside of the cell here cause problems??????
            newFriendStatus = 1
        }
        
        delegate?.didChangeFriendStatus(cell: self, newFriendStatus: newFriendStatus)
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let profileDim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        profileImageView.layer.cornerRadius = profileDim / 2
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: profileDim, height: profileDim)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(friendActionButton)
        friendActionButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 80, height: 25)
        friendActionButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        friendActionButton.isHidden = true
        
        addSubview(nameLabel)
        nameLabel.anchor(top: profileImageView.centerYAnchor, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        nameLabelToRightAnchor = nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        nameLabelToRightAnchor.isActive = false
        
        nameLabelToButtonAnchor = nameLabel.rightAnchor.constraint(equalTo: friendActionButton.leftAnchor, constant: -8)
        nameLabelToButtonAnchor.isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nameLabel.topAnchor, right: nameLabel.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(profileButton)
        profileButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nameLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
