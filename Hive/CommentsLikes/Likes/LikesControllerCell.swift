//
//  LikeControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.


import UIKit

protocol LikesControllerCellDelegate: class {
    func showProfile(profileController: ProfileMainController)
}

class LikesControllerCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    weak var delegate: LikesControllerCellDelegate?
    
    fileprivate let likesCellId = "likesCellId"
    
    fileprivate var selectedProfileItem: Int?
    
    var post: Post? {
        didSet {
            guard post != nil else { return }
            DispatchQueue.main.async {
                self.paginateLikes()
            }
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.backgroundColor = .clear 
        cv.delegate = self
        cv.contentInset.top = 0.0
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {

        collectionView.register(LikesCell.self, forCellWithReuseIdentifier: likesCellId)

        addSubview(collectionView)
        collectionView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    var likedUsers = [User]()
    var isFinishedPagingLikes: Bool = false
    var lastIndexLikes: Int = 0
    func paginateLikes() {
        guard let pid = self.post?.id else { return }
        let params = ["PID": pid, "lastIndex": lastIndexLikes] as [String: Any]
        self.lastIndexLikes += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateSecretLikesOnPost", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPagingLikes = true) : (self.isFinishedPagingLikes = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    
                    var user = User(dictionary: snapshot)
                    if let myId = MainTabBarController.currentUser?.uid {
                        print(snapshot, "SNAPSHOT")
                        if let status = snapshot["status"] as? Int {
                            user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: myId)
                        } else if user.uid == myId {
                            user.friendStatus = 0
                        } else {
                            user.friendStatus = 3
                        }
                    }
                    
                    self.likedUsers.append(user)
                })
                
                self.collectionView.reloadData()
            }
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return likedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == likedUsers.count - 1 && !isFinishedPagingLikes {
            self.paginateLikes()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: likesCellId, for: indexPath) as! LikesCell
        
        cell.user = likedUsers[indexPath.item]
        cell.delegate = self
        
        return cell 
    }
    
    let height: CGFloat = UIScreen.main.bounds.width <  375 ? 70 : 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension LikesControllerCell: LikesCellDelegate {
    
    func didChangeFriendStatusInLikeCell(cell: LikesCell, newFriendStatus: Int) {
        //3 0 or 1
        guard let user = cell.user , let indexPath = collectionView.indexPath(for: cell) else { return }
        
        var updatedUser = likedUsers[indexPath.item]
        updatedUser.friendStatus = newFriendStatus
        likedUsers[indexPath.item] = updatedUser
        self.collectionView.reloadItems(at: [indexPath])
        
        if newFriendStatus == 0 { //accept request
            user.uid.acceptFriendRequest()
            
        } else if newFriendStatus == 1 { //send friend request
            user.uid.sendFriendRequest()
            
        } else if newFriendStatus == 3 { //cancel friend request
            user.uid.cancelFriendRequest()
            
        }
    }
    
    func showProfile(cell: LikesCell) {
        guard let user = cell.user else { return }
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        profileController.wasPushed = true
        profileController.delegate = self
        delegate?.showProfile(profileController: profileController)
        
        self.selectedProfileItem = collectionView.indexPath(for: cell)?.item
    }
    
}

extension LikesControllerCell: ProfileMainControllerDelegate {
    
    func didChangeFriendStatusInProfile(friendStatus: Int, userId: Int) {
     
        guard let item = selectedProfileItem else { return }
        var user = likedUsers[item]
        user.friendStatus = friendStatus
        likedUsers[item] = user
        
        DispatchQueue.main.async {
            self.collectionView.reloadItems(at: [IndexPath(item: item, section: 0)])
        }
    }
}
