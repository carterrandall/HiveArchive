//
//  ProfileFriendsControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-23.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ProfileFriendsControllerCellDelegate: class {
    func showProfile(profileController: ProfileMainController)
    func updateFriendCount(friendCount: Int)

}

class ProfileFriendsControllerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: ProfileFriendsControllerCellDelegate?
    
    fileprivate let friendCellId = "friendCellId"
    
    var user: User?
    
    var friendJson: [[String: Any]]? {
        didSet {
            if self.friends.count > 0 { return }
            if let json = friendJson {
                self.processFriendJson(json: json)
            }
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .white
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        collectionView.register(FriendCell.self, forCellWithReuseIdentifier: friendCellId)
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func paginateFriends() {
        guard let uid = self.user?.uid else { return }
        let params = ["UID": uid, "lastIndex": lastIndex] as [String: Any]
        self.lastIndex += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateFriendsOnProfile", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            self.processFriendJson(json: json)
        }
    }
    
    fileprivate var isFinishedPaging: Bool = false
    fileprivate var friends = [Friend]()
    fileprivate var lastIndex: Int = 0
    fileprivate var uids = [Int]()
    fileprivate func processFriendJson(json: [[String: Any]]) {
        json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
        if json.count > 0 {
            json.forEach({ (snapshot) in
                guard let id = snapshot["id"] as? Int else { return }
        
                var friend = Friend(uid: id, dictionary: snapshot)
                if !uids.contains(friend.uid) {
                    self.uids.append(friend.uid)
                } else {
                    return
                }
                
                if friend.uid == MainTabBarController.currentUser?.uid {
                    friend.friendStatus = 0
                    self.friends.append(friend)
                } else {
                   
                    if let status = snapshot["status"] as? Int, let myId = MainTabBarController.currentUser?.uid {
                        friend.friendStatus = status.getFriendStatusFromInt(friendId: friend.uid, myId: myId)
                    } else {
                        friend.friendStatus = 3
                    }
                    self.friends.append(friend)
                }
            })
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == friends.count - 1 && !isFinishedPaging {
           self.paginateFriends()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: friendCellId, for: indexPath) as! FriendCell
        cell.friend = friends[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       
        return .zero
    }
    
    let height: CGFloat = UIScreen.main.bounds.width <  375 ? 70 : 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width, height: height)
    }
    
    func updateFriends(uid: Int, added: Bool) {
        if added {
            
            DispatchQueue.main.async {
                uid.fetchUser { (user) in
                    let friend = Friend(uid: user.uid, dictionary: ["fullName": user.fullName, "username": user.username, "profileImageUrl": user.profileImageUrl.absoluteString] as [String : Any])
                    self.friends.append(friend)
                    self.friends.sort(by: { (f1, f2) -> Bool in
                        return f1.username.compare(f2.username) == .orderedAscending
                    })
                    self.collectionView.reloadData()
                }
                
                if let friendCount = self.user?.friends {
                    self.user?.friends = friendCount + 1
                    self.delegate?.updateFriendCount(friendCount: friendCount + 1)
                }
                
            }
            
            self.uids.append(uid)
            
        } else {
            
            let index = friends.firstIndex { (friend) -> Bool in
                return friend.uid == uid
            }
            
            if let index = index {
                if let i = uids.firstIndex(of: uid) {
                    uids.remove(at: i)
                }
                friends.remove(at: index)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                if let friendCount = self.user?.friends {
                    self.user?.friends = friendCount - 1
                    self.delegate?.updateFriendCount(friendCount: friendCount - 1)
                }
                
            }
            
        }
    }

    
    
}

extension ProfileFriendsControllerCell: FriendCellDelegate {

    func didChangeFriendStatus(cell: FriendCell, newFriendStatus: Int) {
        guard let userFriend = cell.friend, let indexPath = collectionView.indexPath(for: cell) else { return }
       
        friends.remove(at: indexPath.item)
        friends.insert(userFriend, at: indexPath.item)

        if newFriendStatus == 0 { //user accepted request, update friend cell, notifty current user profile to update and friends search to update
            print("ADD NOTIFICATION")
            let userInfoDict: [String: Any] = ["uid": userFriend.uid, "added": true]
            NotificationCenter.default.post(name: ProfileMainController.addedRemovedFriendNotificationName, object: nil, userInfo: userInfoDict)
            userFriend.uid.acceptFriendRequest()
        } else if newFriendStatus == 1 { //user sent request, update friend cell
            userFriend.uid.sendFriendRequest()
        } else if newFriendStatus == 3 { //user cancelled request, update friend cell
            userFriend.uid.cancelFriendRequest()
        }

        DispatchQueue.main.async {
            self.collectionView.reloadItems(at: [indexPath])
        }

    }
    
    func showProfile(cell: FriendCell) {
        guard let user = cell.friend else { return }
        let profileController = ProfileMainController()
        if self.user?.uid != MainTabBarController.currentUser?.uid {
            profileController.delegate = self
        }
        profileController.userId = user.uid
        let userObject = User(dictionary: ["id": user.uid, "profileImageUrl": user.profileImageUrl.absoluteString, "username": user.username, "fullName": user.fullName])
        profileController.partialUser = userObject
        profileController.wasPushed = true
        delegate?.showProfile(profileController: profileController)
        
    }

}

extension ProfileFriendsControllerCell: ProfileMainControllerDelegate {
    func didChangeFriendStatusInProfile(friendStatus: Int, userId: Int) {
        let index = friends.firstIndex(where: { (f) -> Bool in
            return f.uid == userId
        })
        
        if let index = index {
            var friend = friends[index]
            friend.friendStatus = friendStatus
            friends[index] = friend
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    
}

