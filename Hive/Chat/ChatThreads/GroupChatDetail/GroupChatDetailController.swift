//
//  GroupChatDetailController.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-11.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol GroupChatDetailControllerDelegate: class {
    func didLeaveGroupChat(groupId: String)
    func didAddUsersToGroupChat(idToUserDict: [Int: User])
}

class GroupChatDetailController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: GroupChatDetailControllerDelegate?
    
    let groupChatCellId = "groupChatCellId"
    let inviteCellId = "inviteCellId"
    
    var isNewMessage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(GroupChatDetailCell.self, forCellWithReuseIdentifier: groupChatCellId)
        collectionView.register(InviteCell.self, forCellWithReuseIdentifier: inviteCellId)
        collectionView.showsVerticalScrollIndicator = false
        
        setupNavBar()
        
    }
    
    fileprivate func setupNavBar() {
        
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.shadowImage = UIImage.imageWithColor(color: UIColor(white: 0, alpha: 0.1))
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
        
        if !isNewMessage && self.uids.count > 2 {
            let leaveButton = UIBarButtonItem(title: "Leave", style: .plain, target: self, action: #selector(handleLeave))
            navigationItem.rightBarButtonItem = leaveButton
        }
        
        navigationItem.title = "Group Members"
        
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func handleLeave() {
        guard let groupId = self.groupId else { return }
        let params = ["groupId": groupId]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/leaveGroupChat", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("left group chat")
            } else {
                print("failed to leave group chat")
            }
        }
        
        delegate?.didLeaveGroupChat(groupId: groupId)
        
        navigationController?.popToRootViewController(animated: true)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.makeTransparent()
    }
    
    var groupId: String?
    
    var users = [User]()
    var lastIndex: Int = 0
    var isFinishedPagingUsers: Bool = false
    var uids = [Int]()
    var allIds = [Int]()
    fileprivate func paginateGroupUsers(groupId: String) {
        let params = ["groupId": groupId, "lastIndex": lastIndex] as [String: Any]
        self.lastIndex += 1
        print(params, "PARAMS")

        RequestManager().makeJsonRequest(urlString: "/Hive/api/fetchGroupUsers", params: params) { (json, _) in
            guard let json = json as? [String: Any] else {print("wrong form!"); return }
            if let userJson = json["Users"] as? [[String: Any]] {
                userJson.count < 10 ? (self.isFinishedPagingUsers = true):(self.isFinishedPagingUsers = false)
                if userJson.count > 0 {
                    userJson.forEach({ (snapshot) in
                        let user = User(dictionary: snapshot)
                        
                        if !(self.uids.contains(user.uid)) {
                            self.uids.append(user.uid)
                            self.users.append(user)
                        } else {
                            return
                        }
                        
                    })
                    
                    self.collectionView.reloadData()
                }
            }
           
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isNewMessage { //can reduce this code
            let user = users[indexPath.item]
            let profileController = ProfileMainController()
            profileController.wasPushed = true
            profileController.userId = user.uid
            profileController.partialUser = user
            navigationController?.pushViewController(profileController, animated: true)
        } else {
            if indexPath.item == 0 {
                handleAdd()
            } else {
                let user = users[indexPath.item - 1]
                let profileController = ProfileMainController()
                profileController.wasPushed = true
                profileController.userId = user.uid
                profileController.partialUser = user
                navigationController?.pushViewController(profileController, animated: true)
            }
        }
    }
    
    fileprivate func handleAdd() {
        let newChatController = NewChatController()
        newChatController.isNewMessage = false
        newChatController.addUserDelegate = self
        let newChatNavController = UINavigationController(rootViewController: newChatController)
        if let groupId = self.groupId {
            newChatController.groupId = groupId
            newChatController.groupIds = self.allIds
            self.present(newChatNavController, animated: true, completion: nil)
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isNewMessage ? users.count : users.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == users.count - 1 && !isFinishedPagingUsers, let groupId = self.groupId {
            self.paginateGroupUsers(groupId: groupId)
        }
        
        if isNewMessage {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupChatCellId, for: indexPath) as! GroupChatDetailCell
            
            cell.user = users[indexPath.item]
            
            return cell
        } else {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: inviteCellId, for: indexPath) as! InviteCell
                
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupChatCellId, for: indexPath) as! GroupChatDetailCell
                
                cell.user = users[indexPath.item - 1]
                
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension GroupChatDetailController: AddUserChatControllerDelegate {
    
    func addUserToGroup(idToUserDict: [Int: User]) {
        guard let groupId = self.groupId else { return }
        idToUserDict.forEach { (id, user) in
            self.users.append(user)
            self.uids.append(id)
        }
        
        let usersToAdd = idToUserDict.values
        self.users = self.users + usersToAdd
        let idsToAdd = idToUserDict.keys
        
        let params = ["groupId": groupId, "addArray": [idsToAdd]] as [String: Any]
        
        RequestManager().makeResponseRequest(urlString: "/Hive/api/addUserToGroup", params: params) { (response) in
            if response.response?.statusCode == 200 {
                self.delegate?.didAddUsersToGroupChat(idToUserDict: idToUserDict)
                print("added user(s) to group,", idsToAdd)
            } else {
                print("Failed to add user(s) to group")
            }
        }
        
        DispatchQueue.main.async {
            self.users.sort { (u1, u2) -> Bool in
                return u1.username.compare(u2.username) == .orderedAscending
            }
            self.collectionView.reloadData()
        }
        
       
    }
}

