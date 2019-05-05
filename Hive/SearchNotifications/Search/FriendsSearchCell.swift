//
//  FriendsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-07.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol FriendSearchCellDelegate {
    func didChangeFriendStatusInSearchCell(cell: FriendsSearchCell, newFriendStatus: Int) //or request
    func showProfile(cell: FriendsSearchCell)
}

class FriendsSearchCell: UICollectionViewCell {
    
    var stackViewToRightAnchor: NSLayoutConstraint!
    var stackViewToButtonAnchor: NSLayoutConstraint!
    
    var delegate: FriendSearchCellDelegate?
    
    var user: User? {
        didSet {
            
            nameLabel.text = user?.fullName
            usernameLabel.text = user?.username
            
            guard let profileImageUrl = user?.profileImageUrl, let userid = user?.uid else { return }
            
            profileImageView.profileImageCache(url: profileImageUrl, userId: userid)

            if let friendStatus = user?.friendStatus {
                
                switch friendStatus {
                case 0:
                    friendActionButton.isHidden = true
                case 1:
                    friendActionButton.isHidden = false
                    friendActionButton.titleLabel?.text = "Pending" //set both for system type button to avoid flickering
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
       // button.backgroundColor = .mainRed()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleSendUpdateFriendStatus), for: .touchUpInside)
        return button
    }()
    
    override func prepareForReuse() {
        user = nil
        friendActionButton.titleLabel?.text = nil
        friendActionButton.setTitle(nil, for: .normal)
        nameLabel.text = nil
        usernameLabel.text = nil
        profileImageView.image = nil
        
    }
    
    @objc func handleSendUpdateFriendStatus() {
        guard let user = user else { return }
        let friendStatus = user.friendStatus
        var newFriendStatus: Int!
        
        if friendStatus == 1 { //current user requested, cancel friend request
            friendActionButton.titleLabel?.text = "Add"
            friendActionButton.setTitle("Add", for: .normal)
            self.user?.friendStatus = 3
            newFriendStatus = 3
        } else if friendStatus == 2 { //other user requested, accept friend request
            friendActionButton.titleLabel?.text = "Added"
            friendActionButton.setTitle("Added", for: .normal) //can get rid of changing label here as cell will be reloaded
            self.user?.friendStatus = 0
            newFriendStatus = 0
        } else if friendStatus == 3 { //no requests, send friend request
            friendActionButton.titleLabel?.text = "Pending"
            friendActionButton.setTitle("Pending", for: .normal)
            self.user?.friendStatus = 1
            newFriendStatus = 1
        }
        
        delegate?.didChangeFriendStatusInSearchCell(cell: self, newFriendStatus: newFriendStatus)
            
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let profileImageDim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        profileImageView.layer.cornerRadius = profileImageDim / 2
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: profileImageDim, height: profileImageDim)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(friendActionButton)
        friendActionButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 80, height: 25)
        friendActionButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        friendActionButton.isHidden = true
        
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, nameLabel])
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        stackViewToButtonAnchor = stackView.rightAnchor.constraint(equalTo: friendActionButton.leftAnchor, constant: -8)
        stackViewToButtonAnchor.isActive = true
        
        stackViewToRightAnchor = stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        stackViewToRightAnchor.isActive = false
        
        addSubview(profileButton)
        profileButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
