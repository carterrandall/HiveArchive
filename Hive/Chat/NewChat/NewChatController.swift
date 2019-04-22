//
//  NewChatController.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol NewChatControllerDelegate: class {
    func showChatControllerForUser(idToUserDict: [Int: User])
    func showChatControllerForGroup(idToUserDict: [Int: User], groupId: String)
}

protocol AddUserChatControllerDelegate: class {
    func addUserToGroup(idToUserDict: [Int: User])
}

class NewChatController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, NewChatCellDelegate {
    
    let cellId = "cellId"
    
    weak var delegate: NewChatControllerDelegate?
    
    weak var addUserDelegate: AddUserChatControllerDelegate?
    
    fileprivate var shouldShowSearchedUsers: Bool = false
    fileprivate var hasSearchedUsers: Bool = false
    
    var isNewMessage: Bool = true {
        didSet {
           
            if isNewMessage {
                navigationItem.title = "New Message"
                toTextView.text = "To:"
                
            } else {
                navigationItem.title = "Add To Group"
                toTextView.text = "Add: "
            }
        }
    }
    
    var groupId: String?
    var groupIds: [Int]?

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .white
        return cv
    }()
    
    let toContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.autoresizingMask = .flexibleHeight
        return view
    }()
    
    let textView: NewChatTextView = {
        let tv = NewChatTextView()
        tv.font = UIFont.boldSystemFont(ofSize: 14)
        tv.textColor = .black
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.autocorrectionType = .no
        tv.textContainerInset.left = 0
        tv.autocapitalizationType = .none
        return tv
    }()
    
    let toTextView: UITextView = {
        let tv = UITextView()
        tv.text = "To:"
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.textColor = .gray
        tv.isUserInteractionEnabled = false
        return tv
    }()
    
    var stringOfInterest: String = ""
    var prefixString: String = ""
    var currentPrefix: String = ""
    func textViewDidChange(_ textView: UITextView) {
        
        textView.sizeToFit()
       
        //check for removal
        
        if textView.text.count < prefixString.count && selectedUsernames.count > 0 {
            
            let lastUsername = selectedUsernames.last
            selectedIdToFriendDict.forEach { (id, user) in
                if user.username == lastUsername {
                    selectedIdToFriendDict[id] = nil
                    return
                }
            }
         
            selectedUsernames.removeLast()
            setAttributedText()
            return
            
        }
        
        //search
        stringOfInterest = String(textView.text.dropFirst(prefixString.count))
        if stringOfInterest.count > 1 {
            
            shouldShowSearchedUsers = true
            
            if let queryText = self.queryText {
                if stringOfInterest.lowercased().trimmingCharacters(in: .whitespaces).range(of: queryText.lowercased()) == nil {
                    self.lastIndexSearch = 0
                    self.hasSearchedUsers = false
                    self.searchedUsers.removeAll()
                    self.filteredSearchedUsers.removeAll()
                    self.searchedUids.removeAll()
                }
            }
            
            if !hasSearchedUsers {
                self.paginateSearchedUsers()
            }
            
            filteredSearchedUsers = self.searchedUsers.filter({ (user) -> Bool in
                return (user.username.lowercased().contains(stringOfInterest.lowercased().trimmingCharacters(in: .whitespaces))) || (user.fullName.lowercased().contains(stringOfInterest.lowercased().trimmingCharacters(in: .whitespaces)))
            })
            
            self.collectionView.reloadData()
            filteredSearchedUsers.forEach { (user) in
                checkToAddUser(user: user)
            }
    //////////////////// //////////////////// //////////////////// //////////////////// ////////////////////
        } else if stringOfInterest.count == 0 {
            
            shouldShowSearchedUsers = false
            filteredFriends = friends
        }
        
        collectionView.reloadData()
        
    }
    
    fileprivate func checkToAddUser(user: User) {
        if stringOfInterest.contains(user.username) || stringOfInterest.contains(user.fullName) { //check for adding
            selectedIdToFriendDict[user.uid] = user
            if !selectedUsernames.contains(user.username) {
                selectedUsernames.append(user.username)
            }
            setAttributedText()
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
       
        view.backgroundColor = .white
        setupNavBar()
        setupViews()
        if isNewMessage {
            paginateFriends()
        } else {
            paginateFriendsNotInGroup()
        }

    }
    
    fileprivate func setupViews() {
        
        view.addSubview(collectionView)
        
        view.addSubview(toTextView)
        toTextView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: toTextView.text.width(withContainedHeight: 30, font: UIFont.systemFont(ofSize: 14)) + 10, height: 30)
        
        view.addSubview(textView)
        textView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: toTextView.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: -8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(seperatorView)
        seperatorView.anchor(top: textView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)

        collectionView.register(NewChatCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.anchor(top: textView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    
    }
    
    let navBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
    fileprivate func setupNavBar() {
        
        navigationController?.makeTransparent()
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleDismiss))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if isNewMessage {
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
            self.navigationItem.rightBarButtonItem = nextButton
        } else {
            let nextButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleNext))
            self.navigationItem.rightBarButtonItem = nextButton
        }
        
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBlurView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navBlurView.isHidden = true
    }
    
    @objc fileprivate func handleDismiss() {
        view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func handleNext() {
        if !isNewMessage {
            self.addUserDelegate?.addUserToGroup(idToUserDict: selectedIdToFriendDict)
            self.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true) {
                if self.selectedIdToFriendDict.count == 1 {
                    self.delegate?.showChatControllerForUser(idToUserDict: self.selectedIdToFriendDict)
                } else {
                    self.delegate?.showChatControllerForGroup(idToUserDict: self.selectedIdToFriendDict, groupId: NSUUID().uuidString)
                }
            }
        }
    }
    
    var friends = [User]()
    var filteredFriends = [User]()
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
                self.filteredFriends = self.friends
                self.collectionView.reloadData()
            }
        }
 
    }
    
    var searchedUsers = [User]()
    var filteredSearchedUsers = [User]()
    var isFinishedPagingSearch: Bool = false
    var lastIndexSearch = 0
    var queryText: String?
    var searchedUids = [Int]()
    fileprivate func paginateSearchedUsers() {
        print("Paginating searched users")
        self.queryText = stringOfInterest.trimmingCharacters(in: .whitespaces)
        
        hasSearchedUsers = true
        
        guard let queryText = queryText else { return }
        var added = Array(selectedIdToFriendDict.keys)
        if let groupIds = groupIds {
            added = added + groupIds
        }
        let params = ["search": queryText, "lastIndex": lastIndexSearch, "added": added] as [String : Any]
        self.lastIndexSearch += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/searchFriends", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPagingSearch = true) : (self.isFinishedPagingSearch = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    let user = User(dictionary: snapshot)
                    if !self.searchedUids.contains(user.uid) {
                        self.searchedUids.append(user.uid)
                        self.searchedUsers.append(user)
                    }
                    
                })
                self.filteredSearchedUsers = self.searchedUsers
                print(self.filteredSearchedUsers.count, "FILTERED COUNT")
                self.collectionView.reloadData()
            } else {
                print("json had count 0 :(")
            }
        }

    }
    
    fileprivate func paginateFriendsNotInGroup() {
        guard let id = self.groupId else { return }
        let params = ["lastIndex": lastIndex, "groupId": id] as [String: Any]
        self.lastIndex += 1
        
        RequestManager().makeJsonRequest(urlString: "/Hive/api/paginateFriendsToAddToGroupChat", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    self.friends.append(User(dictionary: snapshot))
                })
                self.filteredFriends = self.friends
                self.collectionView.reloadData()
            }
        }
    }

    var selectedIdToFriendDict = [Int: User]()
    var selectedUsernames = [String]()
    var isMaxCapacity: Bool = false
    func didSelectCell(cell: NewChatCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        var selectedFriend: User!
        if !shouldShowSearchedUsers {
            selectedFriend = filteredFriends[indexPath.item]
        } else {
            selectedFriend = filteredSearchedUsers[indexPath.item]
        }
        
        let selectedUid = selectedFriend.uid
        let selectedUsername = selectedFriend.username
        if selectedIdToFriendDict[selectedUid] == nil {
            
            selectedIdToFriendDict[selectedUid] = selectedFriend
            selectedUsernames.append(selectedUsername)
            
        } else {
            if let item = selectedUsernames.firstIndex(of: selectedUsername) {
                selectedUsernames.remove(at: item)
            }
            selectedIdToFriendDict[selectedUid] = nil
        }
        
        if !(self.selectedUsernames.count + (self.groupIds?.count ?? 0) < (isNewMessage ? 24:25)) {
            self.isMaxCapacity = true
            self.collectionView.reloadData()
        } else if isMaxCapacity {
            self.isMaxCapacity = false
            self.collectionView.reloadData()
        }
        
        setAttributedText()
    }
    
    fileprivate func setAttributedText() {
      
        let attributedText = NSMutableAttributedString(string: "", attributes: nil)
        
        if selectedUsernames.count > 0 {
            
            if isMaxCapacity {
                attributedText.append(NSMutableAttributedString(string: selectedUsernames.joined(separator: ", ") + ". ", attributes: [.font : UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]))

            } else {
                attributedText.append(NSMutableAttributedString(string: selectedUsernames.joined(separator: ", ") + ", ", attributes: [.font : UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]))

            }
            
        }
        
        textView.attributedText = attributedText
        self.prefixString = attributedText.string
        
        self.filteredFriends = self.friends
        self.filteredSearchedUsers = self.searchedUsers
        self.shouldShowSearchedUsers = false
        self.collectionView.reloadData()
        
    }
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowSearchedUsers ? filteredSearchedUsers.count : filteredFriends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! NewChatCell
        
        if indexPath.item == self.filteredFriends.count - 1 && !isFinishedPaging && !shouldShowSearchedUsers {
            self.paginateFriends()
        }
        
        if indexPath.item == self.filteredSearchedUsers.count - 1 && !isFinishedPagingSearch && shouldShowSearchedUsers {
            if self.filteredSearchedUsers.count < 10 {
                self.lastIndexSearch = 0
            }
            self.paginateSearchedUsers()
        }
        
        var friend: User!
        if shouldShowSearchedUsers {
            friend = filteredSearchedUsers[indexPath.item]
        } else {
            friend = filteredFriends[indexPath.item]
        }
        
        if Array(selectedIdToFriendDict.keys).contains(friend.uid) {
            cell.hasBeenSelected = true
        } else {
            cell.hasBeenSelected = false
            if isMaxCapacity {
                cell.isUserInteractionEnabled = false
                cell.usernameLabel.textColor = .lightGray
                cell.nameLabel.textColor = .lightGray
            }
        }
        
        cell.friend = friend
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
