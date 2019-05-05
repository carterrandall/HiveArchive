
//
//  SearchControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol SearchControllerCellDelegate: class {
    func showProfile(profileController: ProfileMainController)
    func updateNotificationCount(count: Int)
    
}

class SearchControllerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    fileprivate let searchHeaderId = "headerId"
    fileprivate let searchCellId = "searchCellId"
    let requestCellId = "requestCellId"
    let friendCellId = "friendCellId"
    
    fileprivate var shouldDisplaySearchedUsers: Bool = false
    fileprivate var haveSearchedUsers: Bool = false
    fileprivate let searchTextThreshold = 1
    fileprivate let placeholderWidth: CGFloat = 110.0 //calculate this value instead of hard code
    fileprivate var offset = UIOffset()
    
    fileprivate var friendRequestCount: Int?
    
    fileprivate var hideRequestHeaderAtZero: Bool = true
    
    var selectedProfileIndex: IndexPath?
    
    weak var delegate: SearchControllerCellDelegate?
    
    var user: User?
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.barTintColor = .clear
        sb.backgroundImage = UIImage()
        sb.backgroundColor = .clear
        sb.autocapitalizationType = .none
        
        let textField = sb.value(forKey: "searchField") as? UITextField
        textField?.textColor = .black
        textField?.font = UIFont.systemFont(ofSize: 16)
        textField?.backgroundColor = .clear
        
        let placeholderLabel = textField?.value(forKey: "placeholderLabel") as? UILabel
        placeholderLabel?.font = UIFont.systemFont(ofSize: 16)
        
        sb.delegate = self
        return sb
    }()
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let noOffset = UIOffset(horizontal: 0, vertical: 0)
        searchBar.setPositionAdjustment(noOffset, for: .search)
        return true
    }
    
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setPositionAdjustment(offset, for: .search)
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if (searchBar.text?.count)! >= searchTextThreshold {
            
            shouldDisplaySearchedUsers = true
            
            if let queryText = self.queryText { //check if text acutally matches query text (user might backspace and type different search)
                if searchText.lowercased().range(of: queryText.lowercased()) == nil {
                    print("nil clearing out")
                    self.lastIndexSearchedUsers = 0
                    self.haveSearchedUsers = false
                    self.searchedUsers.removeAll()
                    self.searchUids.removeAll()
                    self.searchedFilteredUsers.removeAll()
                } else {
                    print("not nil")
                }
            }
            
            
            if !haveSearchedUsers { //fetch if we havent
                self.haveSearchedUsers = true
                print("havesearched? paginating")
                paginateUsers()
                
            }
            
            searchedFilteredUsers = self.searchedUsers.filter { (user) -> Bool in //filter them on further typing
                return (user.username.lowercased().contains(searchText.lowercased()) || user.fullName.lowercased().contains(searchText.lowercased()))
            }
            
            
            
        } else { //show friends and friend requests
            
            shouldDisplaySearchedUsers = false
            searchedFilteredUsers = searchedUsers //reset filetered searchedUsers
            if !((searchBar.text?.isEmpty)!) {
                
                filteredFriendRequests = self.friendRequests.filter({ (user) -> Bool in
                    return (user.username.lowercased().contains(searchText.lowercased()) || user.fullName.lowercased().contains(searchText.lowercased()))
                })
                
                filteredSuggestedFriends = self.suggestedFriends.filter({ (user) -> Bool in
                    return (user.username.lowercased().contains(searchText.lowercased()) || user.fullName.lowercased().contains(searchText.lowercased()))
                })
                
                filteredRecentUsers = self.recentUsers.filter({ (user) -> Bool in
                    return (user.username.lowercased().contains(searchText.lowercased()) || user.fullName.lowercased().contains(searchText.lowercased()))
                })
                
            } else {
                filteredFriendRequests = friendRequests
                filteredSuggestedFriends = suggestedFriends
                filteredRecentUsers = recentUsers
            }
        }
        self.collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchedUsers.removeAll()
        self.searchedFilteredUsers.removeAll()
        shouldDisplaySearchedUsers = true
        paginateUsers()
    }
    
    var queryText: String?
    var searchedFilteredUsers = [User]()
    var searchedUsers = [User]()
    var lastIndexSearchedUsers: Int = 0
    var isFinishedPagingUsers: Bool = false
    var searchUids = [Int]()
    func paginateUsers() {
        print("paginating HERE!")
        if let queryText = searchBar.text?.lowercased() {
            self.queryText = queryText
            
            let params = ["search": queryText, "lastIndex": lastIndexSearchedUsers] as [String : Any]
            self.lastIndexSearchedUsers += 1
            
            MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/searchUsers", params: params) { (json, _) in
                guard let json = json as? [[String : Any]] else { return }
                
                json.count < 10 ? (self.isFinishedPagingUsers = true) : (self.isFinishedPagingUsers = false)
                
                if json.count > 0 {
                    
                    json.forEach({ (snapshot) in
                        var user = User(dictionary: snapshot)
                        
                        if !(self.searchUids.contains(user.uid)) {
                            if let status = snapshot["status"] as? Int, let myId = MainTabBarController.currentUser?.uid {
                                user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: myId)
                                
                            } else {
                                user.friendStatus = 3
                            }
                            self.searchUids.append(user.uid)
                            self.searchedUsers.append(user)
                        } else {
                            
                            print("already had uid")
                        }
                        
                    })
                    
                    // self.searchedFilteredUsers = self.searchedUsers
                    if (self.searchBar.text?.count ?? 1) >= queryText.count, let searchText = self.searchBar.text?.lowercased() {
                        self.searchedFilteredUsers = self.searchedUsers.filter { (user) -> Bool in //filter them on further typing
                            return (user.username.lowercased().contains(searchText) || user.fullName.lowercased().contains(searchText))
                        }
                    } else {
                        self.searchedFilteredUsers = self.searchedUsers.filter { (user) -> Bool in //filter them on further typing
                            return (user.username.lowercased().contains(queryText.lowercased()) || user.fullName.lowercased().contains(queryText.lowercased()))
                        }
                    }
                    
                    
                    self.collectionView.reloadData()
                }
            }
            
        }
        
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.keyboardDismissMode = .onDrag
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        
        setupViews()
        setupCollectionView()
        paginateSearchValues()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupCollectionView() {
        
        collectionView.register(FriendsSearchCell.self, forCellWithReuseIdentifier: searchCellId)
        collectionView.register(FriendsRequestCell.self, forCellWithReuseIdentifier: requestCellId)
        collectionView.register(FriendCell.self, forCellWithReuseIdentifier: friendCellId)
        collectionView.register(FriendsSearchHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: searchHeaderId)
        collectionView.contentInset.top = 48.0
        collectionView.contentInset.bottom = 40.0
    }
    
    fileprivate func setupViews() {
        
        addSubview(collectionView)
        backgroundColor = .clear
        let searchBarContainerView = UIView()
        searchBarContainerView.backgroundColor = UIColor.rgb(red: 245, green: 245, blue: 245)
        searchBarContainerView.setShadow(offset: .zero, opacity: 0.1, radius: 3, color: UIColor.black)
        searchBarContainerView.layer.cornerRadius = 15
        addSubview(searchBarContainerView)
        searchBarContainerView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16.0, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 30)
        
        addSubview(searchBar)
        searchBar.anchor(top: nil, left: searchBarContainerView.leftAnchor, bottom: nil, right: searchBarContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        searchBar.centerYAnchor.constraint(equalTo: searchBarContainerView.centerYAnchor).isActive = true
        
        //searchbar centre placeholder
        let searchBarWidth = frame.width - 80
        offset = UIOffset(horizontal: (searchBarWidth - placeholderWidth) / 2, vertical: 0)
        searchBar.setPositionAdjustment(offset, for: .search)
        
        collectionView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)//searchBarContainerView.bottomAnchor
    }
    
    var newestFriendRequest: Double = 0.0
    var oldestFriendRequest: Double = 0.0
    var isFirst = true
    func paginateSearchValues() {
        print("Paginating search values")
        guard let location = MapRender.mapView.userLocation?.coordinate else { return }
        let oldestFriendRequest = (self.friendRequests.last?.requestCreationDate ?? 0.0)
        let newestFriendRequest = (self.friendRequests.first?.requestCreationDate ?? 0.0)
        let params = ["latitude": location.latitude, "longitude": location.longitude, "oldestFriendRequest": oldestFriendRequest, "suggestedLastIndex": lastIndexSuggestedFriends, "isFinishedPagingFriendRequests": isFinishedPagingFriendRequests, "newestFriendRequest": newestFriendRequest, "isFirst": isFirst] as [String: Any]
        
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateSearchValues", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            
            self.isFirst = false
            print(json)
            if let count = json["Count"] as? Int {
                self.friendRequestCount = count
            }
            
            if let suggested = json["Suggested"] as? [[String: Any]] {
                
                self.processSuggested(json: suggested)
            } else {
                self.isFinishedPagingSuggestedFriends = true
            }
            
            if let requests = json["Requests"] as? [[String: Any]] {
                if let newRequests = json["newRequests"] as? [[String: Any]] {
                    self.processRequests(json: requests, new: false, completion: {
                        DispatchQueue.main.async {
                            self.processRequests(json: newRequests, new: true)
                        }
                    })
                } else {
                    self.processRequests(json: requests, new: false)
                }
            } else if let newRequests = json["newRequests"] as? [[String: Any]] {
                self.processRequests(json: newRequests, new: true)
            }
            
            if let notificationCount = json["Notifications"] as? Int, notificationCount > 0 {
                self.delegate?.updateNotificationCount(count: notificationCount)
            }
            
            if let recents = json["Recents"] as? [[String:Any]]{
                self.processRecentUsers(json: recents)
            }
        }
        
    }
    
    var friendRequests = [User]()
    var filteredFriendRequests = [User]()
    var isFinishedPagingFriendRequests: Int = 0
    var tempNewFriendRequests = [User]()
    var requestUids = [Int]()
    fileprivate func processRequests(json: [[String: Any]], new: Bool, completion: @escaping() ->() = {}) {
        print("processing new?:", new, "JSON COUNT", json.count)
        
        if !new {
            json.count < 10 ? (self.isFinishedPagingFriendRequests = 1) : (self.isFinishedPagingFriendRequests = 0)
        }
        if json.count > 0 {
            json.forEach({ (snapshot) in
                var user = User(dictionary: snapshot)
                
                if !requestUids.contains(user.uid) {
                    self.requestUids.append(user.uid)
                } else {
                    return
                }
                
                if let requestDate = snapshot["creationDate"] as? Double {
                    user.requestCreationDate = requestDate
                }
                user.friendStatus = 2
                if new {
                    print(user.username, "USERNAME")
                    self.tempNewFriendRequests.insert(user, at: 0)
                } else {
                    self.friendRequests.append(user)
                }
                
            })
            
            if new { //have and requests > 0 here before not sure why but if crash figure out why, dont want that here cause you might not have > 0 as compared to the algorithm in the feed.
                self.reloadForNewRequests(requests: self.tempNewFriendRequests)
            } else {
                
                self.filteredFriendRequests = self.friendRequests
                self.collectionView.reloadData()
                self.collectionView.performBatchUpdates(nil) { (_) in
                    completion()
                }
            }
        }
    }
    
    fileprivate func reloadForNewRequests(requests: [User]) {
        print("reloading for new items")
        self.tempNewFriendRequests.removeAll()
        let contentHeight = self.collectionView.contentSize.height
        let offsetY = self.collectionView.contentOffset.y
        
        if offsetY < self.collectionView.frame.height {
            requests.forEach { (post) in
                self.friendRequests.insert(post, at: 0)
                self.filteredFriendRequests = self.friendRequests
                print("inserted request")
            }
            self.collectionView.reloadData()
            return
        }
        
        let bottomOffset = contentHeight - offsetY
        
        
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.collectionView.performBatchUpdates({
            
            var indexPaths = [IndexPath]()
            for i in 0..<requests.count {
                self.friendRequests.insert(requests[i], at: 0)
                indexPaths.append(IndexPath(item: i, section: 0))
            }
            self.filteredFriendRequests = self.friendRequests
            if indexPaths.count > 0 {
                self.collectionView.insertItems(at: indexPaths)
            } else {
                self.collectionView.reloadData()
            }
        }) { (complete) in
            DispatchQueue.main.async {
                self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - bottomOffset)
                CATransaction.commit()
            }
        }
    }
    
    var recentUsers = [User]()
    var filteredRecentUsers = [User]()
    fileprivate func processRecentUsers(json: [[String: Any]]) {
        if let currentUID = MainTabBarController.currentUser?.uid {
            if json.count > 0 {
                print(json.count, "JSON RECENT COUNT")
                json.forEach { (snapshot) in
                    var user = User(dictionary: snapshot)
                    if let status = snapshot["status"] as? Int {
                        user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: currentUID)
                    }
                    self.recentUsers.append(user)
                }
                self.filteredRecentUsers = self.recentUsers
                self.collectionView.reloadData()
            } else {
                print("JSON COUNT 0")
            }
        }
    }
    
    var suggestedFriends = [User]()
    var filteredSuggestedFriends = [User]()
    var isFinishedPagingSuggestedFriends: Bool = false
    var lastIndexSuggestedFriends: Int = 0
    var suggestedIds = [Int]()
    fileprivate func processSuggested(json: [[String: Any]]) {
        lastIndexSuggestedFriends += 1
        if let currentUid = MainTabBarController.currentUser?.uid {
            json.count < 10 ? (self.isFinishedPagingSuggestedFriends = true) : (self.isFinishedPagingSuggestedFriends = false)
            if json.count > 0 {
                print(json.count, "JSON COUNT")
                json.forEach({ (snapshot) in
                    var user = User(dictionary: snapshot)
                    if !suggestedIds.contains(user.uid) {
                        suggestedIds.append(user.uid)
                    } else {
                        return
                    }
                    if let status = snapshot["status"] as? Int {
                        user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: currentUid)
                    }
                    self.suggestedFriends.append(user)
                })
                self.filteredSuggestedFriends = self.suggestedFriends
                self.collectionView.reloadData()
            } else {
                print("JSON 0 COUNT")
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if !shouldDisplaySearchedUsers && indexPath.section == 0 {
            self.selectedProfileIndex = indexPath
            let profileController = ProfileMainController()
            profileController.delegate = self
            profileController.wasPushed = true
            let requestFriend = friendRequests[indexPath.item]
            profileController.userId = requestFriend.uid
            profileController.user = requestFriend
            delegate?.showProfile(profileController: profileController)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: searchHeaderId, for: indexPath) as! FriendsSearchHeader
        
        if !shouldDisplaySearchedUsers {
            
            if indexPath.section == 0 {
                //either fetch this or add to user property
                if var count = self.friendRequestCount {
                    if count < 0 { count = 0 }
                    if friendRequestCount != 0 || (!hideRequestHeaderAtZero) {
                        count == 1 ? (header.title = String(count) + " Friend Request") : (header.title = String(count) + " Friend Requests")
                    }
                }
            } else if indexPath.section == 1 {
                if self.recentUsers.count != 0 {
                    header.title = "Recent"
                }
            } else if indexPath.section == 2 {
                if self.suggestedFriends.count != 0 {
                    header.title = "Suggested"
                }
            }
        } else {
            header.title = nil
        }
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if !shouldDisplaySearchedUsers {
            if section == 0 {
                if friendRequests.count == 0 && hideRequestHeaderAtZero {
                    return CGSize(width: collectionView.frame.width, height: 0)
                } else {
                    return CGSize(width: collectionView.frame.width, height: 40)
                }
                
            } else if section == 1 {
                return self.recentUsers.count == 0 ? CGSize(width: collectionView.frame.width, height: 0) : CGSize(width: collectionView.frame.width, height: 40)
            } else {
                return self.suggestedFriends.count == 0 ? CGSize(width: collectionView.frame.width, height: 0) : CGSize(width: collectionView.frame.width, height: 40)
            }
        } else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if !shouldDisplaySearchedUsers {
            return 3
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !shouldDisplaySearchedUsers {
            if section == 0 {
                return filteredFriendRequests.count
            } else if section == 1 {
                return filteredRecentUsers.count
            } else {
                return filteredSuggestedFriends.count
            }
        } else {
            return searchedFilteredUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if !shouldDisplaySearchedUsers {
            
            if indexPath.section == 0 {
                
                if indexPath.item == self.filteredFriendRequests.count - 1 && !(isFinishedPagingFriendRequests == 1)  {
                    self.paginateSearchValues()
                }
                
                let requestCell = collectionView.dequeueReusableCell(withReuseIdentifier: requestCellId, for: indexPath) as! FriendsRequestCell
                requestCell.user = filteredFriendRequests[indexPath.item]
                requestCell.delegate = self
                return requestCell
                
                
            } else if indexPath.section == 1 {
                
                let recentCell = collectionView.dequeueReusableCell(withReuseIdentifier: searchCellId, for: indexPath) as! FriendsSearchCell
                recentCell.delegate = self //gona have to fix the delegates for this shit now bruh
                recentCell.user = filteredRecentUsers[indexPath.item]
                return recentCell
                
            } else {
                
                if indexPath.item == self.filteredSuggestedFriends.count - 1 && !isFinishedPagingSuggestedFriends && lastIndexSuggestedFriends < 5 {
                    self.paginateSearchValues()
                }
                
                let suggestedCell = collectionView.dequeueReusableCell(withReuseIdentifier: searchCellId, for: indexPath) as! FriendsSearchCell
                suggestedCell.user = filteredSuggestedFriends[indexPath.item]
                suggestedCell.delegate = self
                return suggestedCell
                
            }
            
        } else {
            
            if indexPath.item == self.searchedFilteredUsers.count - 1 && !isFinishedPagingUsers {
                print("paging c4i@", lastIndexSearchedUsers)
                if self.searchedFilteredUsers.count < 10 {
                    self.lastIndexSearchedUsers = 0
                }
                self.paginateUsers()
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: searchCellId, for: indexPath) as! FriendsSearchCell
            cell.delegate = self
            cell.user = searchedFilteredUsers[indexPath.item]
            return cell
            
        }
    }
    
    let height: CGFloat = UIScreen.main.bounds.width <  375 ? 70 : 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
        
    }
    
}

extension SearchControllerCell: ProfileMainControllerDelegate {
    
    func didChangeFriendStatusInProfile(friendStatus: Int, userId: Int) {
        //status ==  0 1 or 3
        print("DID CHANGE STATUS")
        guard let index = selectedProfileIndex else {print("no selected index"); return }
        
        if !shouldDisplaySearchedUsers {
            
            if friendStatus == 0 { //if 0, user was in requests, remove
                
                friendRequests.remove(at: index.item)
                filteredFriendRequests = friendRequests
                
                if let friendRequestCount = self.friendRequestCount {
                    print("setting friend request count")
                    self.friendRequestCount = friendRequestCount - 1
                }
                
            } else if friendStatus == 1 { // if 1 user was maybe in suggested, remove if they are
                
                let indexInSuggested = suggestedFriends.firstIndex { (user) -> Bool in
                    return user.uid == userId
                } //if this returns a value the user was there
                
                if let index = indexInSuggested {
                    suggestedFriends.remove(at: index)
                    filteredSuggestedFriends = suggestedFriends
                } else {//user was maybe in recent update user
                    let indexInRecent = recentUsers.firstIndex { (user) -> Bool in
                        return user.uid == userId
                    }
                    if let index = indexInRecent {
                        var user = recentUsers[index]
                        user.friendStatus = friendStatus
                        recentUsers[index] = user
                        filteredRecentUsers = recentUsers
                    }
                }
                
            } else if friendStatus == 3 { //user sent request from cell then went into profile and cancelled, update the user
                
                if index.section == 1 {
                    var user = recentUsers[index.item]
                    user.friendStatus = friendStatus
                    recentUsers[index.item] = user
                    filteredRecentUsers = recentUsers
                    
                } else if index.section == 2 {
                    var user = suggestedFriends[index.item]
                    user.friendStatus = friendStatus
                    suggestedFriends[index.item] = user
                    filteredSuggestedFriends = suggestedFriends
                }
                
                
            }
            
        } else { //update user friend status
            var user = searchedUsers[index.item]
            user.friendStatus = friendStatus
            searchedUsers[index.item] = user
            searchedFilteredUsers = searchedUsers
            
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
}

extension SearchControllerCell: FriendSearchCellDelegate {
    
    func didChangeFriendStatusInSearchCell(cell: FriendsSearchCell, newFriendStatus: Int) {
        print("CHANGING FRIEND STATUS")
        guard let user = cell.user, let indexPath = collectionView.indexPath(for: cell) else { return }
        
        if shouldDisplaySearchedUsers {
            print("should display searched users")
            searchedFilteredUsers[indexPath.item] = user
            
            //replace in the searched array
            let index = searchedUsers.firstIndex { (searchedUser) -> Bool in
                return searchedUser.username == user.username
            }
            
            if let index = index {
                self.searchedUsers[index] = user
            }
            
        } else if indexPath.section == 1 {
            filteredRecentUsers[indexPath.item] = user
            
            let index = recentUsers.firstIndex { (recentUser) -> Bool in
                return recentUser.username == user.username
            }
            
            if let index = index {
                self.recentUsers[index] = user
            }
            
        } else {
            filteredSuggestedFriends[indexPath.item] = user
            
            let index = suggestedFriends.firstIndex { (suggestedUser) -> Bool in
                return suggestedUser.username == user.username
            }
            
            if let index = index {
                self.suggestedFriends[index] = user
            }
        }
        
        if newFriendStatus == 0 { //users are now friends, remove from friend request array, update search cell user
            print("now friends")
            print("ACCEPTING FRIEND REQUEST")
            user.uid.acceptFriendRequest()
            if let friendRequestCount = self.friendRequestCount {
                print("setting friend request count")
                self.friendRequestCount = friendRequestCount - 1
            }
            
            if indexPath.section == 1 {
                
                let index = recentUsers.firstIndex { (recentUser) -> Bool in
                    return recentUser.username == user.username
                }
                
                if let index = index {
                    recentUsers.remove(at: index)
                    filteredRecentUsers = recentUsers
                }
                
            } else {
                
                
                let index = friendRequests.firstIndex { (friendRequestUser) -> Bool in
                    return friendRequestUser.username == user.username
                }
                
                if let index = index {
                    friendRequests.remove(at: index)
                    filteredFriendRequests = friendRequests
                }
            }
            
        } else if newFriendStatus == 1 { //current request friend ship, send friend request
            user.uid.sendFriendRequest()
        } else if newFriendStatus == 3 { //newFriendStatus = 3, cancel request
            user.uid.cancelFriendRequest()
        }
        
        DispatchQueue.main.async {
            print("reloading")
            self.collectionView.reloadData()
        }
        
    }
    
    func showProfile(cell: FriendsSearchCell) {
        let profileController = ProfileMainController()
        profileController.delegate = self
        profileController.wasPushed = true
        guard let user = cell.user else { return }
        profileController.userId = user.uid
        profileController.user = user
        delegate?.showProfile(profileController: profileController)
        
        self.selectedProfileIndex = collectionView.indexPath(for: cell)
        
    }
}

extension SearchControllerCell: FriendsRequestCellDelegate {
    
    func didAcceptFriendRequest(cell: FriendsRequestCell) { //accept friend request, remove from friend requests, update own profile
        guard let indexPath = collectionView.indexPath(for: cell), let user = cell.user else { return }
        user.uid.acceptFriendRequest()
        self.friendRequests[indexPath.item].friendStatus = 0
        
        self.filteredFriendRequests = self.friendRequests
        
        if let friendRequestCount = self.friendRequestCount {
            print("friend request Count")
            self.friendRequestCount = friendRequestCount - 1
        }
        
        hideRequestHeaderAtZero = false
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func didHideFriendRequest(cell: FriendsRequestCell) { //remove from friend requests
        
        guard let id = cell.user?.uid else { return }
        let params = ["FID": id]
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/hideFriendRequest", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("hide friend request")
            } else {
                print("Failed to hide friend request")
            }
        }
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        self.friendRequests.remove(at: indexPath.item)
        self.filteredFriendRequests = self.friendRequests
        collectionView.deleteItems(at: [indexPath])
        
        if let friendRequestCount = self.friendRequestCount {
            self.friendRequestCount = friendRequestCount - 1
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
}
