//
//  BlockedUsersController.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

class BlockedUsersController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let blockedUserCellId = "blockedUserCellId"
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        return cv
    }()
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        tf.autocapitalizationType = .none
        return tf
    }()
    
    @objc func handleEditingChanged() {
        
        blockButton.isEnabled = false
        
        guard let text = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        let count = text.count
        
        if count > 30 {
            usernameTextField.deleteBackward()
        }
        
        if count >= 5 {
            checkIfUsernameValidAndGetId(username: text) { (valid, uid) in
                if valid {
                    guard let currentUid = MainTabBarController.currentUser?.uid, uid != currentUid else { return }
                    self.blockButton.isEnabled = true
                    self.currentId = uid
                } else {
                    self.blockButton.isEnabled = false
                }
            }
            
        } else {
            blockButton.isEnabled = false
        }
    }
    
    
    let blockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Block", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleBlock), for: .touchUpInside)
        return button
    }()
    
    @objc func handleBlock() {
        blockButton.isEnabled = false
        guard let id = self.currentId else { return }
        blockUserWithId(id: id)
        
    }

    var currentId: Int?
    fileprivate func checkIfUsernameValidAndGetId(username: String, completion: @escaping(Bool, Int) -> ()) {
        if let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/idForUserWithUsername") {
            let params = ["username": username.lowercased()]
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
                
                if let json = data.result.value as? [String: Int]{
                    guard let id = json["id"] else { return }
                    completion(true, id)
                    print("valid", username)
                } else {
                    completion(false, -1)
                    print("notvalid", username)
                }
            }
        }
        
    }
    
    fileprivate func blockUserWithId(id: Int) {
        let params = ["blockId": id]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/blockUserWithId", params: params) { (response) in
            if response.response?.statusCode == 200 {
                guard let username = self.usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                let dict = ["id": id, "username": username] as [String: Any]
                let blockedUser = BlockedUser(dictionary: dict)
                self.blockedUsers.append(blockedUser)
                self.collectionView.reloadData()
                print("blocked user")

            } else {
                print("Failed to block user")
                self.blockButton.isEnabled = true
            }
        }

    }
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.backgroundColor = .white
        collectionView.backgroundColor = .white
        collectionView.register(BlockedUserCell.self, forCellWithReuseIdentifier: blockedUserCellId)
        
        setupNavBar()
        setupViews()
        paginateBlockedUsers()
        
    }
    
 
    fileprivate func setupViews() {
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        view.addGestureRecognizer(swipeGesture)
        view.isUserInteractionEnabled = true
       
        view.addSubview(blockButton)
        blockButton.isEnabled = false
        blockButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 50, height: 40)
        view.addSubview(usernameTextField)
        usernameTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: blockButton.leftAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 16, width: 0, height: 40)
        view.addSubview(collectionView)
        collectionView.anchor(top: usernameTextField.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    fileprivate func setupNavBar() {
        navigationItem.title = "Blocked Users"
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    var blockedUsers = [BlockedUser]()
    var lastIndex: Int = 0
    var isFinishedPaging: Bool = false
    fileprivate func paginateBlockedUsers() {
        let params = ["lastIndex": lastIndex]
        self.lastIndex += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/paginateBlockedUsers", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    let blockedUser = BlockedUser(dictionary: snapshot)
                    self.blockedUsers.append(blockedUser)
                })
                
                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: blockedUserCellId, for: indexPath) as! BlockedUserCell
        
        if indexPath.item == blockedUsers.count - 1 && !isFinishedPaging {
            self.paginateBlockedUsers()
        }
        
        cell.backgroundColor = .white
        cell.user = blockedUsers[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}

extension BlockedUsersController: BlockedUserCellDelegate {
    
    func unblockUser(cell: BlockedUserCell) {
        guard let id = cell.user?.id else { return }
        let params = ["blockId": id]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/unblockUserWithId", params: params) { (response) in
            if response.response?.statusCode == 200 {
                guard let index = self.collectionView.indexPath(for: cell) else { return }
                self.blockedUsers.remove(at: index.item)
                self.collectionView.reloadData()
            }
        }
    }
}


