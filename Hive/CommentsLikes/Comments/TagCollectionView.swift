//
//  TagCollectionView.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-21.
//  Copyright © 2019 Carter Randall. All rights reserved.


import UIKit

protocol TagCollectionViewDelegate: class {
    func didSelectName(username: String)
    func didDeselectName(username: String)
    func updateText(text: String)
    func updateTags(ids: [Int])
    
}

extension TagCollectionViewDelegate {
    func updateTags(ids: [Int]) {
        
    }
}

class TagCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var tagDelegate: TagCollectionViewDelegate?
    
    let tagCellId = "tagFriendCellId"
    
    var shouldShowSearchedUsers: Bool = false
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        register(TagCell.self, forCellWithReuseIdentifier: tagCellId)
        
        backgroundColor = .clear
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false
        delegate = self
        dataSource = self
        
        paginateFriends()
        
    }
    
    var hasSearchedUsers: Bool = false
    var previousQueryString = ""
    func textDidChange(searchText: String, tagging: Bool) {


        if !tagging { return }
        
        let queryText = self.pruneString(text: searchText)
        if queryText.count > 0 {
            
            self.shouldShowSearchedUsers = true
            
            if queryText.lowercased().range(of: previousQueryString.lowercased()) == nil && previousQueryString.lowercased().range(of: queryText.lowercased()) == nil {
                print("removing")
                self.lastIndexSearch = 0
                self.searchedUsers.removeAll()
                self.searchedUids.removeAll()
                self.filteredSearchedUsers.removeAll()
                self.hasSearchedUsers = false
 
            } else {
                print("not nil")
            }
            
            if !self.hasSearchedUsers {
                self.hasSearchedUsers = true
                paginateSearchedUsers(searchText: queryText)
            }
            
            self.previousQueryString = queryText
            
            filteredSearchedUsers = self.searchedUsers.filter({ (user) -> Bool in
                return (user.username.lowercased().contains(queryText.lowercased().trimmingCharacters(in: .whitespaces))) || (user.fullName.lowercased().contains(queryText.lowercased().trimmingCharacters(in: .whitespaces)))
            })
            
            self.updateTags(text: searchText)
        
        } else {
            self.filteredSearchedUsers = searchedUsers
            self.shouldShowSearchedUsers = false
        }
        
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    fileprivate func pruneString(text: String) -> String {
        guard let index = text.lastIndex(of: "@") else { return "" }
        let substring = String(text[index...])
        var words = substring.components(separatedBy: " ")
        return String(words[0].dropFirst().lowercased())
    }
    
    fileprivate func updateTags(text: String) {
        
        let tags = text.tags()
        for username in selectedIdToUserDict.keys {
            if !tags.contains(where: { (string) -> Bool in
                return string.contains(username)
            }) {
                
               //the username is not contained in our tags. remove it from the username list
                self.selectedIdToUserDict[username] = nil
            } else {
                 //the username is contained in our tags, all gucci
            }
        }
    
        //tags has an extra ut oh better go find it!
        if tags.count > selectedIdToUserDict.count {
            for tag in tags {
                if !selectedIdToUserDict.keys.contains(tag) {
                    
                    if let uid = self.findUserWithUsername(username: tag) {
                        self.selectedIdToUserDict[tag] = uid
                    }
                }
            }
        }
        self.reloadData()
    }
    
    fileprivate func findUserWithUsername(username: String)->Int? {
        if shouldShowSearchedUsers {
            if let user = self.filteredSearchedUsers.first(where: { (user) -> Bool in
                return user.username == username
            }) {
                return user.uid
            }
        } else {
            if let user = self.friends.first(where: { (user) -> Bool in
                return user.username == username
            }) {
                return user.uid
            }
        }
        return nil
    }
    
    
    var friends = [User]()
    var isFinishedPaging: Bool = false
    var lastIndex = 0
    fileprivate func paginateFriends() {
        guard let id = MainTabBarController.currentUser?.uid else { return }
        let params = ["UID": id, "lastIndex": lastIndex] as [String: Any]
        self.lastIndex += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/paginateFriendsOnProfile", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            self.isFinishedPaging = (json.count < 10 ? true : false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    self.friends.append(User(dictionary: snapshot))
                })
                print("done pagianting")
                self.reloadData()
            }
        }
        
    }
    
    var searchedUsers = [User]()
    var filteredSearchedUsers = [User]()
    var isFinishedPagingSearch: Bool = false
    var lastIndexSearch = 0
    var queryText: String?
    var searchedUids = [Int]()
    fileprivate func paginateSearchedUsers(searchText: String) {
        print(searchText, "search text", lastIndex, "lastIndex")
        //self.previousQueryString = searchText
        let params = ["search": searchText, "lastIndex": lastIndexSearch, "added": []] as [String : Any]
        self.lastIndexSearch += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/searchFriends", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPagingSearch = true) : (self.isFinishedPagingSearch = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    let user = User(dictionary: snapshot)
                    
                    if !self.searchedUids.contains(user.uid) {
                        self.searchedUids.append(user.uid)
                    } else {
                        return
                    }
                    
                    self.searchedUsers.append(user)
                })
                self.filteredSearchedUsers = self.searchedUsers
                
                self.reloadData()
            } else {
             
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectedIdToUserDict = [String: Int]() {
        didSet {
            if selectedIdToUserDict.values.count > 0 {
                tagDelegate?.updateTags(ids: Array(Set(selectedIdToUserDict.values)))
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var selectedUser: User!
        if shouldShowSearchedUsers {
            selectedUser = filteredSearchedUsers[indexPath.item]
        } else {
            selectedUser = friends[indexPath.item]
        }
        
        let selectedUsername = selectedUser.username
        let selectedUid = selectedUser.uid
        if selectedIdToUserDict[selectedUsername] == nil { //add them
            selectedIdToUserDict[selectedUsername] = selectedUid
            

            self.tagDelegate?.didSelectName(username: selectedUsername)
            
        } else {
            selectedIdToUserDict[selectedUsername] = nil
            self.tagDelegate?.didDeselectName(username: selectedUsername)
        }
        
        self.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowSearchedUsers ? filteredSearchedUsers.count : friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: tagCellId, for: indexPath) as! TagCell
        
        if indexPath.item == self.friends.count - 1 && !isFinishedPaging && !shouldShowSearchedUsers {
            self.paginateFriends()
        }
        
        if indexPath.item == self.filteredSearchedUsers.count - 1 && !isFinishedPagingSearch && shouldShowSearchedUsers {
            self.paginateSearchedUsers(searchText: self.previousQueryString)
        }
        
        var friend: User!
        if shouldShowSearchedUsers {
            friend = filteredSearchedUsers[indexPath.item]
        } else {
            friend = friends[indexPath.item]
        }
       
        cell.user = friend
        
        if Array(selectedIdToUserDict.keys).contains(friend.username) {
            cell.container.layer.borderColor = UIColor.mainRed().cgColor
            cell.profileImageView.layer.borderColor = UIColor.mainRed().cgColor
        } else {
            cell.container.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
            cell.profileImageView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = frame.height - 10
        var width: CGFloat!
        if shouldShowSearchedUsers {
            width = filteredSearchedUsers[indexPath.item].username.width(withContainedHeight: height, font: UIFont.systemFont(ofSize: 14))
        } else {
            width = friends[indexPath.item].username.width(withContainedHeight: height, font: UIFont.systemFont(ofSize: 14))
        }
        return CGSize(width: width + 40, height: height)
    }
    
}
