//
//  ChooseFriendsController.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-22.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class ChooseFriendsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let friendCellId = "friendCellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        collectionView.register(ChooseFriendCell.self, forCellWithReuseIdentifier: friendCellId)
        collectionView.showsVerticalScrollIndicator = false
        
        setupNavBar()
        
        paginateFriends()
    }
    
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if whiteView != nil { return }
        whiteView = UIView()
        whiteView.backgroundColor = .white
        view.addSubview(whiteView)
        whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height)!)
        
    }
    
    fileprivate func setupNavBar() {
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        self.navigationController?.navigationBar.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        self.navigationItem.title = "Location Sharing"
    }
    
    fileprivate func paginateFriends() {
        guard let uid = MainTabBarController.currentUser?.uid else { return }
        let params = ["UID": uid, "lastIndex": lastIndex] as [String: Any]
        self.lastIndex += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateFriendsOnProfile", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            self.processFriendJson(json: json)
        }
    }
    
    fileprivate var isFinishedPaging: Bool = false
    fileprivate var friends = [User]()
    fileprivate var lastIndex: Int = 0
    fileprivate var uids = [Int]()
    fileprivate func processFriendJson(json: [[String: Any]]) {
        json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
        if json.count > 0 {
            json.forEach({ (snapshot) in
               
                let friend = User(dictionary: snapshot)
                if !uids.contains(friend.uid) {
                    self.uids.append(friend.uid)
                } else {
                    return
                }
                
                self.friends.append(friend)
    
            })
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
    }
    
    @objc fileprivate func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var friend = friends[indexPath.item]
        if let sharing = friend.sharingLocation {
            friend.sharingLocation = !sharing
            self.updateSharingWithUser(id: friend.uid)
            self.friends[indexPath.item] = friend
            self.collectionView.reloadData()
        }
    }
    
    fileprivate func updateSharingWithUser(id: Int) {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friends.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: friendCellId, for: indexPath) as! ChooseFriendCell
        
        if indexPath.item == self.friends.count - 1 && !isFinishedPaging {
            self.paginateFriends()
        }
        
        cell.user = friends[indexPath.item]
        return cell
    }
    
    let height: CGFloat = UIScreen.main.bounds.width <  375 ? 70 : 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
