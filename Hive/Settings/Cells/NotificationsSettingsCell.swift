//
//  NotificationsSettingsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-25.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class NotificationsSettingsCell: UICollectionViewCell {
    
    var commentsNotifications: Bool? {
        didSet {
            if let commentsNotifications = commentsNotifications, commentsNotifications {
                self.commentsSwitchControl.isOn = true
            } else {
                self.commentsSwitchControl.isOn = false
            }
        }
    }
    
    var likesNotifications: Bool? {
        didSet {
            if let likesNotifications = likesNotifications, likesNotifications {
                self.likesSwitchControl.isOn = true
            } else {
                self.likesSwitchControl.isOn = false
            }
        }
    }
    
    var friendsNotifications: Bool? {
        didSet {
            if let friendsNotifications = friendsNotifications, friendsNotifications {
                self.friendsSwitchControl.isOn = true
            } else {
                self.friendsSwitchControl.isOn = false
            }
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Notifications"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let likesLabel: UILabel = {
        let label = UILabel()
        label.text = "Likes"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    
    lazy var likesSwitchControl: UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.isOn = true
        sc.addTarget(self, action: #selector(handleSwitchLikes), for: .valueChanged)
        return sc
    }()
    
    @objc func handleSwitchLikes() {
        var params = [String: Any]()
        if likesSwitchControl.isOn {
            params["bool"] = 1
        } else {
            params["bool"] = 0
        }
        
        toggleNotificationsWithParams(params: params, urlString: "/Hive/api/toggleLikeNotifications")
    }
    
    let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = "Comments"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var commentsSwitchControl: UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.addTarget(self, action: #selector(handleSwitchComments), for: .valueChanged)
        return sc
    }()
    
    @objc func handleSwitchComments() {
        var params = [String: Any]()
        if commentsSwitchControl.isOn {
            params["bool"] = 1
        } else {
            params["bool"] = 0
        }
        
        toggleNotificationsWithParams(params: params, urlString: "/Hive/api/toggleCommentNotifications")
    }
    
    let friendsLabel: UILabel = {
        let label = UILabel()
        label.text = "Friend Activity"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var friendsSwitchControl : UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.addTarget(self, action: #selector(handleSwitchFriends), for: .valueChanged)
        return sc
    }()
    
    @objc func handleSwitchFriends() {
        var params = [String: Any]()
        if friendsSwitchControl.isOn {  //valueChanges before getting to here 
            params["bool"] = 1
        } else {
            params["bool"] = 0
        }
       
        toggleNotificationsWithParams(params: params, urlString: "/Hive/api/toggleFriendNotifications")
    }
    
    fileprivate func toggleNotificationsWithParams(params: [String: Any], urlString: String) {
        RequestManager().makeResponseRequest(urlString: urlString, params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("toggled notifications")
            } else {
                print("failed to toggle notifications")
            }
        }
    }
    
    let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(likesLabel)
        likesLabel.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(likesSwitchControl)
        likesSwitchControl.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        likesSwitchControl.centerYAnchor.constraint(equalTo: likesLabel.centerYAnchor).isActive = true
        
        addSubview(commentsSwitchControl)
        commentsSwitchControl.anchor(top: likesSwitchControl.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        
        addSubview(commentsLabel)
        commentsLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentsLabel.centerYAnchor.constraint(equalTo: commentsSwitchControl.centerYAnchor).isActive = true
        
        addSubview(friendsSwitchControl)
        friendsSwitchControl.anchor(top: commentsSwitchControl.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        
        addSubview(friendsLabel)
        friendsLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        friendsLabel.centerYAnchor.constraint(equalTo: friendsSwitchControl.centerYAnchor).isActive = true
        
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: titleLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
