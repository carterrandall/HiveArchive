//
//  ProfileHeaderCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-23.
//  Copyright © 2018 Carter Randall. All rights reserved.


import UIKit

protocol ProfileHeaderViewDelegate {
    func editProfile(state: ProfileState)
    func editProfileImage()
    func didChangeFriendStatus(friendStatus: Int, userId: Int)
    func displayUserActionSheet(friends: Bool, sharingLocation: Bool)
}

enum ProfileState {
    case normal, editing
}

class ProfileHeaderView: UIView {
    
    var delegate: ProfileHeaderViewDelegate?
    
    
    fileprivate var profileState = ProfileState.normal
    
    fileprivate var indicatorButton: UIButton!
    fileprivate var indicatorLabel: UILabel!
    fileprivate var isIndicatorOpen: Bool = false
    fileprivate var indicatorButtonWidth: NSLayoutConstraint!
    fileprivate var indicatorButtonLeft: NSLayoutConstraint!
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            
            setInfoForUser(user: user)
            
            setupEditAddButton()
        }
    }
    
    var partialUser: User? {
        didSet {
            guard let partial = partialUser else { return }
            
            setInfoForUser(user: partial)
            
        }
    }
    
    func setInfoForUser(user: User, override:Bool=false) {
        if profileImageView.image == nil {
            profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid) { (_) in
                DispatchQueue.main.async {
                    self.profileImageContainerView.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
                    
                    if self.backgroundImageView.image == nil {
                        self.backgroundImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
                    }
                }
                
            }
        } else if backgroundImageView.image == nil {
            self.backgroundImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
        }
        
        if nameLabel.text == nil || override {
            nameLabel.text = user.fullName
        }
        
        if usernameLabel.text == nil || override {
            usernameLabel.text = user.username
        }
        
    }
    
    let profileImageContainerView = UIView()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    let backgroundImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    let editProfilePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "add"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleEditProfilePhoto), for: .touchUpInside)
        button.backgroundColor = UIColor.rgb(red: 30, green: 30, blue: 30).withAlphaComponent(0.5)
        button.clipsToBounds = true
        return button
    }()
    
    
    @objc fileprivate func handleEditProfilePhoto() {
        delegate?.editProfileImage()
    }
    
    
    let profileEditAddButton = ProfileEditAddButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        setupViews()
      
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let profileDim: CGFloat = UIScreen.main.bounds.width <  375 ? 80 : 100
    
    let userActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "downArrow"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(handleUserAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    @objc fileprivate func handleUserAction() {
        if let sharingLocation = self.user?.sharingLocation, self.profileEditAddButton.friendState == .friends {
            delegate?.displayUserActionSheet(friends: true, sharingLocation: sharingLocation)
        }else{
             delegate?.displayUserActionSheet(friends: false, sharingLocation: false)
        }
    }

    fileprivate func setupViews() {
        
        addSubview(backgroundImageView)
        backgroundImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.height)
        
        let blackView = UIView()
        blackView.backgroundColor = .white
        addSubview(blackView)
        blackView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(blurView)
        blurView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.height)
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        addSubview(profileImageContainerView)
        profileImageContainerView.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 24 + (statusBarHeight == 0 ? self.fakeStatusBarHeight() : statusBarHeight), paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: profileDim, height: profileDim)
        
        profileImageContainerView.layer.cornerRadius = profileDim / 2
        profileImageContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        profileImageContainerView.addSubview(profileImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleEditProfilePhoto))
        profileImageView.addGestureRecognizer(tapGesture)
        
        profileImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: profileDim, height: profileDim)
        profileImageView.layer.cornerRadius = profileDim / 2
        profileImageView.centerXAnchor.constraint(equalTo: profileImageContainerView.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
        
        addSubview(profileEditAddButton)
        profileEditAddButton.delegate = self
        profileEditAddButton.anchor(top: nil, left: profileImageContainerView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileEditAddButton.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
        
        addSubview(nameLabel)
        nameLabel.anchor(top: profileImageContainerView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let actionGesture = UITapGestureRecognizer(target: self, action: #selector(handleUserAction))
        nameLabel.addGestureRecognizer(actionGesture)
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nameLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        usernameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        addSubview(userActionButton)
        userActionButton.anchor(top: nil, left: nameLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: -6, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        userActionButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        
    }
    
    fileprivate func fakeStatusBarHeight() -> CGFloat {
        if (UIScreen.main.bounds.height / UIScreen.main.bounds.width) > 16/9 { return 44 } else { return 20 }
    }
    

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isIndicatorOpen && self.profileEditAddButton.friendState != .otherRequested && self.profileState == .normal {
            self.hideIndicatorView(friendState: nil, delay: 0)
        }
        
    }
    
    func checkIfShouldShowIndicatorView() {
        if self.profileEditAddButton.friendState == .otherRequested && !isIndicatorOpen {
            self.showIndicatorView(title: "Accept")
        }
    }
    
    
    fileprivate func setupEditAddButton() {
        
        guard let currentLoggedInUserId = MainTabBarController.currentUser?.uid else {return}
        
        guard let userId = user?.uid else { return }
        
        if currentLoggedInUserId == userId {
            
            self.profileEditAddButton.friendState = .currentUser
            
        } else {
            
            self.userActionButton.isHidden = false
            
            guard let statusCode = user?.friendStatus else { return }
            print(statusCode, "STATUS CODE")
            switch statusCode {
            case 0:
                self.profileEditAddButton.friendState = .friends
            case 1:
                self.profileEditAddButton.friendState = .currentRequested
            case 2:
                self.profileEditAddButton.friendState = .otherRequested
            default:
                self.profileEditAddButton.friendState = .noRelation
            }
        }
        
    }
}

extension ProfileHeaderView: ProfileEditAddButtonDelegate {
    
    func editProfile() {
        
        showIndicatorView(title: "Done")
        
        profileState = .editing
        profileImageView.isUserInteractionEnabled = true
        setupEditPhotoButton()
        
        delegate?.editProfile(state: profileState)
      
    
    }
    
    fileprivate func setupEditPhotoButton() {
        DispatchQueue.main.async {
            self.editProfilePhotoButton.alpha = 0.0
            
            self.profileImageView.addSubview(self.editProfilePhotoButton)
            self.editProfilePhotoButton.anchor(top: self.profileImageView.centerYAnchor, left: self.profileImageView.leftAnchor, bottom: self.profileImageView.bottomAnchor, right: self.profileImageView.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            UIView.animate(withDuration: 0.3) {
                self.editProfilePhotoButton.alpha = 1.0
            }
        }
        
    }
    
    fileprivate func removeEditPhotoButton() {
        UIView.animate(withDuration: 0.3, animations: {
            self.editProfilePhotoButton.alpha = 0.0
        }) { (_) in
            self.editProfilePhotoButton.removeFromSuperview()
        }
    }
    
    
    func changeFriendStatus() {
        guard let uid = self.user?.uid else { return }
        if profileEditAddButton.friendState == .friends {
            showIndicatorView(title: "Remove")
            indicatorButton.isEnabled = true
            
        } else if profileEditAddButton.friendState == .otherRequested {
           
            showIndicatorView(title: "Added")
            indicatorButton.isEnabled = false
            uid.acceptFriendRequest()
            delegate?.didChangeFriendStatus(friendStatus: 0, userId: uid)
            print("add notification")

        } else if profileEditAddButton.friendState == .noRelation {
            showIndicatorView(title: "Sent")
            indicatorButton.isEnabled = false
            uid.sendFriendRequest()
            delegate?.didChangeFriendStatus(friendStatus: 1, userId: uid)
        } else {
            showIndicatorView(title: "Cancel")
            indicatorButton.isEnabled = true
        }
    }
    
    
   
    func showIndicatorView(title: String) {
        
        if indicatorLabel != nil && indicatorButton != nil {
            indicatorLabel.removeFromSuperview()
            indicatorButton.removeFromSuperview()
        }
        
        isIndicatorOpen = true
    
        indicatorButton = UIButton(type: .custom)
        indicatorButton.backgroundColor = .white
        indicatorButton.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        indicatorButton.addTarget(self, action: #selector(handleIndicatorViewAction), for: .touchUpInside)
        
        indicatorLabel = UILabel()
        indicatorLabel.textColor = .mainRed()
        indicatorLabel.font = UIFont.boldSystemFont(ofSize: 14)
        indicatorLabel.textAlignment = .center
        indicatorLabel.text = title
        
        insertSubview(indicatorButton, belowSubview: profileImageContainerView)
        insertSubview(indicatorLabel, aboveSubview: indicatorButton)
        
        indicatorButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        indicatorButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        indicatorButtonWidth = indicatorButton.widthAnchor.constraint(equalToConstant: profileDim - 20)
        indicatorButtonWidth.isActive = true
        indicatorButtonLeft = indicatorButton.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: -profileDim + 20)
        indicatorButtonLeft.isActive = true
        
        indicatorLabel.anchor(top: indicatorButton.topAnchor, left: nil, bottom: indicatorButton.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        indicatorLabel.centerXAnchor.constraint(equalTo: indicatorButton.centerXAnchor).isActive = true
        
        self.layoutIfNeeded()
    
        self.profileEditAddButton.alpha = 0.0
        
        indicatorButtonWidth.constant = profileDim
        indicatorButtonLeft.constant = -5.0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.layoutIfNeeded()

            self.profileEditAddButton.isEnabled = false
            
        }) { (_) in
            
            if title == "Added" {
                self.hideIndicatorView(friendState: .friends, delay: 1.5)
            } else if title == "Sent" {
                self.hideIndicatorView(friendState: .currentRequested, delay: 1.5)
            }
        }
        
    }
    
    @objc fileprivate func handleIndicatorViewAction() {
        
        guard let uid = self.user?.uid else { return }
        
        
        indicatorButton.isEnabled = false
        
        let title = indicatorLabel.text
        if title == "Remove" {
            print("remove notification")
            let userInfoDict: [String: Any] = ["uid":uid,"added":false]
            NotificationCenter.default.post(name: ProfileMainController.addedRemovedFriendNotificationName, object: nil, userInfo: userInfoDict)
            
            uid.removeFriend()
            delegate?.didChangeFriendStatus(friendStatus: 3, userId: uid)
            
            DispatchQueue.main.async {
                self.indicatorLabel.text = "Removed"
            }
            
            
            self.hideIndicatorView(friendState: .noRelation, delay: 1.5)
        } else if title == "Cancel" {
            uid.cancelFriendRequest()
            delegate?.didChangeFriendStatus(friendStatus: 3, userId: uid)
            
            DispatchQueue.main.async {
                self.indicatorLabel.text = "Cancelled"
            }
            
            
            self.hideIndicatorView(friendState: .noRelation, delay: 1.5)
        } else if title == "Accept" {
            let userInfoDict: [String: Any] = ["uid":uid,"added":true]
            NotificationCenter.default.post(name: ProfileMainController.addedRemovedFriendNotificationName, object: nil, userInfo: userInfoDict)
            print("ACCEPTING FRIEND REQUEST")
            uid.acceptFriendRequest()
            delegate?.didChangeFriendStatus(friendStatus: 0, userId: uid)
            
            DispatchQueue.main.async {
                self.indicatorLabel.text = "Added"
            }
            
            self.hideIndicatorView(friendState: .friends, delay: 1.0)
        } else if title == "Done" {
            self.profileState = .normal
            self.profileImageView.isUserInteractionEnabled = false
            self.removeEditPhotoButton()
            self.hideIndicatorView(friendState: nil, delay: 0)
            self.delegate?.editProfile(state: profileState)
        }
        
    }
    
    fileprivate func hideIndicatorView(friendState: FriendState?, delay: Double) {
        
        isIndicatorOpen = false
        
        indicatorButtonWidth.constant = profileDim - 20
        indicatorButtonLeft.constant = -profileDim + 20
        UIView.animate(withDuration: 0.3, delay: delay, options: .curveEaseOut, animations: {
            
            self.layoutIfNeeded()
          
            if let state = friendState {
                self.profileEditAddButton.friendState = state
            }
            
        }) { (_) in
            
            self.profileEditAddButton.isEnabled = true
            self.profileEditAddButton.alpha = 1.0
            self.indicatorButton.removeFromSuperview()
            self.indicatorLabel.removeFromSuperview()
        }
        
    }
    
    
}

