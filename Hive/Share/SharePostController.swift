//
//  SharePostController.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-06.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class SharePostController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UISearchBarDelegate {

    let sharePostCellId = "sharePostCellId"
    let logCellId = "logCellId"
    let headerCellId = "headerCellId"
    
    fileprivate var placeholderWidth: CGFloat! //calculate this value instead of hard code
    fileprivate var offset = UIOffset()
   
    var containerViewBottomAnchor: NSLayoutConstraint!
    
    var post: Post! {
        didSet {
            postView.postImageCache(url: post.imageUrl, postId: post.id)
        }
    }
    
    var sharedIds = [Int]()
    var sharedGroupIds = [String]()
    
    var shouldShowSearchedUsers: Bool = false

    let postView: CustomImageView = {
        let pv = CustomImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        pv.layer.cornerRadius = 2
        return pv
    }()
    
    let messageTextView: UITextView = {
        let tv = UITextView()
        tv.text = "Add a message..."
        tv.textColor = .lightGray
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        return tv
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 5
        view.isUserInteractionEnabled = true
        return view
    }()
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if messageTextView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
       
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add a message..."
            textView.textColor = .lightGray 
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 420 {
            textView.deleteBackward()
        }
    }
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.showsVerticalScrollIndicator = false
        cv.contentInset.top = 48.0
        cv.backgroundColor = .white
        return cv
    }()
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search Friends"
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
        
        if !(searchText.isEmpty) {
            shouldShowSearchedUsers = true
            if let queryText = self.queryText {
                if searchText.lowercased().range(of: queryText.lowercased()) == nil {
                    self.lastIndex = 0
                    self.hasSearchedUsers = false
                    self.friends.removeAll()
                    self.filteredFriends.removeAll()
                }
            }
            if !hasSearchedUsers {
                self.hasSearchedUsers = true
                paginateSearchedFriends()
            }
            
            filteredFriends = self.friends.filter({ (friend) -> Bool in
                return (friend.username.lowercased().contains(searchText.lowercased()) || friend.fullName.lowercased().contains(searchText.lowercased()))
            })
        } else {
            shouldShowSearchedUsers = false
        }
        
        self.collectionView.reloadData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainTabBarController.requestManager.delegate = self
        
        searchBar.delegate = self
        messageTextView.delegate = self
        
        view.backgroundColor = .white 

        navigationController?.makeTransparent()
        
        navigationItem.title = "Share Post"
        
        let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleDismiss))
        navigationItem.leftBarButtonItem = dismissButton
        navigationController?.navigationBar.tintColor = .black
        
        placeholderWidth = "Search Friends".width(withContainedHeight: 30, font: UIFont.systemFont(ofSize: 16)) + 50
        let searchBarWidth = view.frame.width - 80
        offset = UIOffset(horizontal: (searchBarWidth - placeholderWidth) / 2, vertical: 0)
        searchBar.setPositionAdjustment(offset, for: .search)
        
        registerForKeyboardNotifications()
        setupViews()
        paginateRecentConvos()
        
    }
    
    fileprivate func registerForKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc fileprivate func keyboardWillShow(notification: NSNotification) {

        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardFrame.height
            self.containerViewBottomAnchor.constant = -(keyboardHeight + 8)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc fileprivate func keyboardWillBeHidden(notification: NSNotification) {
        self.containerViewBottomAnchor.constant = -8.0
        UIView.animate(withDuration: 0.3) {
          self.view.layoutIfNeeded()
            
        }
    }
    
    fileprivate func setupViews() {
        let postWidth = view.frame.width * 0.193236715
        
       
        view.addSubview(collectionView)
        
        view.addSubview(containerView)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        containerView.addGestureRecognizer(swipeGesture)
        
        containerView.addSubview(postView)
        postView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: postWidth, height: postWidth * (4/3))
        
        containerView.addSubview(messageTextView)
        messageTextView.anchor(top: postView.topAnchor, left: postView.rightAnchor, bottom: postView.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        messageTextView.centerYAnchor.constraint(equalTo: postView.centerYAnchor).isActive = true
        
        containerView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: view.frame.width - 16, height: postWidth * 4/3 + 16)
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        containerViewBottomAnchor.isActive = true
    
        let searchBarContainerView = UIView()
        searchBarContainerView.layer.cornerRadius = 15
        searchBarContainerView.clipsToBounds = true
        searchBarContainerView.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        
        view.addSubview(searchBarContainerView)
        searchBarContainerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 30)
    
        view.addSubview(searchBar)
        searchBar.anchor(top: nil, left: searchBarContainerView.leftAnchor, bottom: nil, right: searchBarContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        searchBar.centerYAnchor.constraint(equalTo: searchBarContainerView.centerYAnchor).isActive = true
        
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SharePostCell.self, forCellWithReuseIdentifier: sharePostCellId)
        collectionView.register(ShareLogCell.self, forCellWithReuseIdentifier: logCellId)
        collectionView.register(FriendsSearchHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerCellId)
        
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: containerView.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    @objc fileprivate func handleDismiss() {
        self.messageTextView.resignFirstResponder()
        
        if let parent = self.navigationController?.presentingViewController as? FeedHeaderPostViewer {
            parent.pageIndicator.isHidden = false
        }
        
        self.dismiss(animated: true, completion: nil)
       
    }
    
    @objc fileprivate func handleSwipe() {
        self.messageTextView.resignFirstResponder()
    }
    
    var logs = [LogMessage]() // message always nil here
    var lastIndexRecent: Int = 0
    var isFinishedPagingRecent: Bool = false
    fileprivate func paginateRecentConvos() {
        let params = ["lastIndex": lastIndexRecent]
        self.lastIndexRecent += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateRecentConversations", params: params) { (json, _) in
            guard let json = json as? [[String: Any]]  else { return }
            json.count < 10 ? (self.isFinishedPagingRecent = true) : (self.isFinishedPagingRecent = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    let user = User(dictionary: snapshot)
                    var log = LogMessage(dictionary: snapshot)
                    log.userOne = user
                    
                    if let count = snapshot["count"] as? Int {
                        log.count = count
                    }
                    
                    self.logs.append(log)
                })
                self.collectionView.reloadData()
            }
            
        }
    }
    
    var friends = [Friend]()
    var filteredFriends = [Friend]()
    var isFinishedPagingFriends: Bool = false
    var lastIndex: Int = 0
    var queryText: String?
    var hasSearchedUsers: Bool = false
    fileprivate func paginateSearchedFriends() {

        if let queryText = searchBar.text?.lowercased() {
            self.queryText = queryText
        
            hasSearchedUsers = true
            let params = ["search": queryText, "lastIndex": lastIndex, "added": []] as [String: Any]
            self.lastIndex += 1
            MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/searchFriends", params: params) { (json, _) in
                guard let json = json as? [[String: Any]] else { return }
                json.count < 10 ? (self.isFinishedPagingFriends = true) : (self.isFinishedPagingFriends = false)
                if json.count > 0 {
                    json.forEach({ (snapshot) in
                        
                        if let uid = snapshot["id"] as? Int {
                            let friend = Friend(uid: uid, dictionary: snapshot)
                            self.friends.append(friend)
                        }
                        self.filteredFriends = self.friends
                        self.collectionView.reloadData()
                        
                    })
                }
            }
        
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if !shouldShowSearchedUsers {
            return logs.count == 0 ? CGSize(width: collectionView.frame.width, height: 0) : CGSize(width: collectionView.frame.width, height: 40)
        } else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! FriendsSearchHeader
        header.title = "Recent Conversations"
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowSearchedUsers ? filteredFriends.count : logs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        if shouldShowSearchedUsers {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sharePostCellId, for: indexPath) as! SharePostCell
            if indexPath.item == self.filteredFriends.count - 1 && !isFinishedPagingFriends {
                self.paginateSearchedFriends()
            }
            
            let friend = filteredFriends[indexPath.item]
            
            if sharedIds.contains(friend.uid) {
                cell.hasShared = true
            } else {
                cell.hasShared = false
            }
            
            cell.friend = filteredFriends[indexPath.item]
            cell.delegate = self
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: logCellId, for: indexPath) as! ShareLogCell
            if indexPath.item == self.logs.count - 1 && !isFinishedPagingRecent {
                self.paginateRecentConvos()
            }
            
            let log = logs[indexPath.item]
            
            
            if log.groupId != "" {
                
                if sharedGroupIds.contains(log.groupId) {
                    cell.hasShared = true
                } else {
                    cell.hasShared = false
                }
            } else {
                if let logUserUid = log.userOne?.uid, sharedIds.contains(logUserUid)  { // have a shared group ids for strings
                    cell.hasShared = true
                } else {
                    cell.hasShared = false
                }
            }
            cell.delegate = self
            cell.log = log
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 66)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
}

extension SharePostController: SharePostCellDelegate, ShareLogCellDelegate {

    func didHitShare(uid: Int) {
        sharedIds.append(uid)
        var params: [String: Any]!
        let postId = post.id
        let toId = uid
        let text = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if messageTextView.text != "Add a message..." && text != "" {
            params = ["text": text, "toId": toId, "pid": postId] as [String : Any]
        } else {
            params = ["toId": toId, "pid": postId] as [String : Any]
        }
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/newMessage", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("succssfully shared")
            } else {
                print("failed to share")
            }
        }
    }
    
    func didHitOpen(uid: Int) {
        
        uid.fetchUser { (user) in
            messageCache.removeObject(forKey: String(user.uid) as AnyObject)
            let chatController = ChatController(style: .grouped)
            chatController.idToUserDict = [user.uid: user]
            self.navigationController?.pushViewController(chatController, animated: true)
        }
    }
    
    func didHitOpenGroup(groupId: String) {
        messageCache.removeObject(forKey: groupId as AnyObject)
        let chatController = ChatController(style: .grouped)
        chatController.groupId = groupId
        self.navigationController?.pushViewController(chatController, animated: true)
    }
    
    func didHitShareGroup(groupId: String) {
        var params: [String: Any]!
        let postId = post.id
        let text = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if messageTextView.text != "Add a message..." && text != "" {
            params = ["text": text, "groupId": groupId, "pid": postId] as [String : Any]
        } else {
            params = ["groupId": groupId, "pid": postId] as [String : Any]
        }
        
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/newMessage", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("successfully share group")
            } else {
                print("failed share group")
            }
        }

    }
    
}

extension SharePostController: RequestManagerDelegate {
    func reconnectedToInternet() {
        if self.logs.count == 0 {
            self.lastIndexRecent = 0
            self.paginateRecentConvos()
        }
    }
}
