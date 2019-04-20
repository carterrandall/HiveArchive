//
//  ChatBarCollectionView.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-09.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ChatBarCollectionViewDelegate {
    func showProfile(user: User)
    func showGroupDetail(users: [User], isFinishedPaging: Bool, lastIndex: Int, allIds: [Int], uids: [Int])
}


class ChatBarCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var cvDelegate: ChatBarCollectionViewDelegate?
    
    let barCellId = "barCellId"
    
    var groupId: String? {
        didSet {
            if let id = groupId {
                paginateGroupUsers(groupId: id)
            }
        }
    }
    

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        backgroundColor = .clear
        delegate = self
        dataSource = self
        
        isScrollEnabled = true
        
        register(ChatBarCell.self, forCellWithReuseIdentifier: barCellId)
        
        showsHorizontalScrollIndicator = false
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var users = [User]()
    var lastIndex: Int = 0
    var isFinishedPagingUsers: Bool = false
    var allIds = [Int]()
    var uids = [Int]()
    fileprivate func paginateGroupUsers(groupId: String) {
        let params = ["groupId": groupId, "lastIndex": 0] as [String: Any]
        self.lastIndex += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/fetchGroupUsers", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            
            if let userJson = json["Users"] as? [[String: Any]] {
                self.isFinishedPagingUsers = (userJson.count < 10 ? true: false)
                if userJson.count > 0 {
                    userJson.forEach({ (snapshot) in
                        let user = User(dictionary: snapshot)
                        if !self.uids.contains(user.uid) {
                            self.uids.append(user.uid)
                        } else {
                            return
                        }
                        
                        self.users.append(user)
                    })
                    self.reloadData()
                }
            }
            if let uidArray = json["uids"] as? [Int] {
                self.allIds = uidArray
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if users.count == 1 && self.groupId == nil {
            cvDelegate?.showProfile(user: users[indexPath.item])
        } else {
            cvDelegate?.showGroupDetail(users: self.users, isFinishedPaging: self.isFinishedPagingUsers, lastIndex: self.lastIndex, allIds: self.allIds, uids: self.uids)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if users.count <= 3 {
            return users.count
        } else {
            return 3
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: barCellId, for: indexPath) as! ChatBarCell
        
        if users.count != 1 {
            
            cell.profileImageView.layer.borderColor = UIColor.white.cgColor
            cell.profileImageView.layer.borderWidth = 1
        }
        
        cell.user = users[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 65, height: 65)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return -32.5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var count: Int!
        if users.count <= 3 {
            count = users.count
        } else {
            count = 3
        }
        
        let totalCellWidth = CGFloat(65 * count)
        let totalSpacingWidth = CGFloat(-32.5) * CGFloat(count - 1)
        let inset = (frame.width - (totalCellWidth + totalSpacingWidth)) / 2
        return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
        
    }
    
    
}
