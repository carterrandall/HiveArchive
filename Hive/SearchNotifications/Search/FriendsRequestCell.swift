//
//  FriendsRequestCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-22.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol FriendsRequestCellDelegate {
    func didAcceptFriendRequest(cell: FriendsRequestCell)
    func didHideFriendRequest(cell: FriendsRequestCell)
}

class FriendsRequestCell: UICollectionViewCell {
    
    var hideButtonRightAnchor: NSLayoutConstraint!
    var stackViewToRightAnchor: NSLayoutConstraint!
    var stackViewToAddButton: NSLayoutConstraint!
    
    var delegate: FriendsRequestCellDelegate?
    
    var user: User? {
        didSet {
            
            nameLabel.text = user?.fullName
            usernameLabel.text = user?.username
            
            guard let profileImageUrl = user?.profileImageUrl, let userid = user?.uid else { return }
            profileImageView.profileImageCache(url: profileImageUrl, userId: userid)
            
            if user?.friendStatus == 0 {
                self.addButton.isHidden = true
                self.hideButton.isHidden = true
                self.friendsButton.isHidden = false
                stackViewToAddButton.isActive = false
                stackViewToRightAnchor.isActive = true
            } else {
                self.addButton.isHidden = false
                self.addButton.isHidden = false
                self.friendsButton.isHidden = true
                stackViewToAddButton.isActive = true
                stackViewToRightAnchor.isActive = false
            }
        }
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
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accept", for: .normal)
        button.titleLabel?.text = "Accept"
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.mainRed(), for: .normal)
        //button.backgroundColor = .mainRed()
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        return button
    }()
    
    @objc func handleAdd() {
        self.hideButtonRightAnchor.constant = 200
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            self.delegate?.didAcceptFriendRequest(cell: self)
        }
    }
    
    lazy var hideButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Hide", for: .normal)
        button.titleLabel?.text = "Hide"
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.lightGray, for: .normal)
     //   button.backgroundColor = .lightGray
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleHide), for: .touchUpInside)
        return button
    }()
    
    @objc func handleHide() {
    
        delegate?.didHideFriendRequest(cell: self)
    }
    
    let friendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "minus"), for: .normal)
        button.tintColor = .gray
        button.isEnabled = false
        return button
    }()
    
    override func prepareForReuse() {
        profileImageView.image = nil
        usernameLabel.text = nil
        nameLabel.text = nil
        user = nil
        hideButton.isHidden = false
        addButton.isHidden = false
        friendsButton.isHidden = true
        hideButtonRightAnchor.constant = -8
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        let profileImageDim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        profileImageView.layer.cornerRadius = profileImageDim / 2
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: profileImageDim, height: profileImageDim)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(friendsButton)
        friendsButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
        friendsButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(hideButton)
        hideButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 25)
        hideButtonRightAnchor = hideButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        hideButtonRightAnchor.isActive = true
        hideButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(addButton)
        addButton.anchor(top: nil, left: nil, bottom: nil, right: hideButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 70, height: 25)
        addButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, nameLabel])
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        stackViewToRightAnchor = stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        stackViewToRightAnchor.isActive = false
        
        stackViewToAddButton = stackView.rightAnchor.constraint(equalTo: addButton.leftAnchor, constant: -8)
        stackViewToAddButton.isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
