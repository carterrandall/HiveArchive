//
//  ProfileMainController.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-23.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire
import Photos

protocol ProfileMainControllerDelegate: class {
    func didChangeFriendStatusInProfile(friendStatus: Int, userId: Int)
}

class ProfileMainController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var delegate: ProfileMainControllerDelegate?
    
    fileprivate let profilePostsControllerCellId = "profilePostsControllerCellId"
    fileprivate let profileFriendsControllerCellId = "profileFriendsControllerCellId"
    fileprivate let editProfileControllerCellId = "editProfileControllerCellId"
    fileprivate var profileState = ProfileState.normal
    fileprivate var hasLoadedProfile: Bool = false
    fileprivate var reloadPostsOnScroll: Bool = false
    fileprivate var didDeletePost: Bool = false
    
    var isFromSearch: Bool = false
    var isCached: Bool = false

    var user: User?
    var userId: Int?
    var partialUser: User?
    
    var wasPushed: Bool = false
    var isFromChat: Bool = false
    
    
    let headerView = ProfileHeaderView()
//    var headerView: ProfileHeaderView!
    let editAddButton = ProfileEditAddButton()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.bounces = false
        cv.backgroundColor = .white
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    lazy var menuBar: ProfileMenuBar = {
        let mb = ProfileMenuBar()
        mb.profileMainController = self
        return mb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainTabBarController.requestManager.delegate = self
        setupViews()
        setupNavBar()
        fetchUser()
        
    }

    fileprivate func fetchUser() {
        if let user = self.user {
            self.userId = user.uid
            self.collectionView.reloadData()
            performWorkForUser(user: user, partial: false)
            
        } else {
            if let uid = self.user?.uid ?? userId ?? MainTabBarController.currentUser?.uid {
                if let partialUser = self.partialUser {
                    self.performWorkForUser(user: partialUser, partial: true)
                } else {
                    self.loadProfile(uid: uid)
                }
            }
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if wasPushed {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
            headerView.addGestureRecognizer(swipeGesture)
            headerView.isUserInteractionEnabled = true
        }
        
        if isCached {
            guard let uid = self.user?.uid else { return }
            if checkToReload(uid: uid) {
                if let postControllerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ProfilePostsControllerCell {
                    postControllerCell.reloadPosts()
                } else {
                    self.reloadPostsOnScroll = true
                }
                
            }
        }

    }
    
    fileprivate func checkToReload(uid: Int) -> Bool {
        if let currentUid = MainTabBarController.currentUser?.uid, currentUid == uid {
            return true
        } else {
            return false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .black
        navigationController?.makeTransparent()
    }
    
    fileprivate func setupViews() {
//        headerView = ProfileHeaderView()
        view.addSubview(headerView)
        headerView.delegate = self
        headerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: (UIScreen.main.bounds.width <  375 ? 200 : 220) + UIApplication.shared.statusBarFrame.height)
        headerView.addSubview(menuBar)
        menuBar.anchor(top: nil, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: headerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        view.addSubview(collectionView)
        collectionView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        collectionView.register(ProfileFriendsControllerCell.self, forCellWithReuseIdentifier: profileFriendsControllerCellId)
        collectionView.register(ProfilePostsControllerCell.self, forCellWithReuseIdentifier: profilePostsControllerCellId)
    }
    
    
    fileprivate func setupNavBar() {
        
        navigationController?.navigationBar.tintColor = .black
        navigationController?.makeTransparent()
        
        if wasPushed {
            let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleDismiss))
            navigationItem.leftBarButtonItem = backButton
        } else {
            let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleDismiss))
            navigationItem.leftBarButtonItem = dismissButton
        }
        
        guard let currentUserUid = MainTabBarController.currentUser?.uid else { return }
        let profileUid = userId ?? user?.uid ?? currentUserUid
        
        if currentUserUid == profileUid {
            let settingsButton = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(handleSettings))
            navigationItem.rightBarButtonItem = settingsButton
            registerForNotifications()
        } else if !isFromChat {
            let customView: ButtonWithCount = {
                let button = ButtonWithCount(type: .system)
                button.paddingTop = -5
                button.setImage(UIImage(named: "chat")?.withRenderingMode(.alwaysOriginal), for: .normal)
                button.count = 0
                button.addTarget(self, action: #selector(handleMessage), for: .touchUpInside)
                return button
            }()
            let messageButton = UIBarButtonItem(customView: customView)
            navigationItem.rightBarButtonItem = messageButton
        }
    }
    
    static let addedRemovedFriendNotificationName = NSNotification.Name("addedFriend")
    fileprivate func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAddedRemovedFriend(notification:)), name: ProfileMainController.addedRemovedFriendNotificationName, object: nil)
    }
    
    @objc fileprivate func handleAddedRemovedFriend(notification: NSNotification) {
        
        if user?.uid == MainTabBarController.currentUser?.uid {
            if let userInfoDict = notification.userInfo as? [String: Any] {
                if let uid = userInfoDict["uid"] as? Int, let added = userInfoDict["added"] as? Bool {

                    if let friendCell = collectionView.visibleCells.first as? ProfileFriendsControllerCell {
                        friendCell.updateFriends(uid: uid, added: added)
                    }
                    
                }
            }
        }
    }
    
    @objc fileprivate func handleSettings() {
        let layout = UICollectionViewFlowLayout()
        let settingsController = SettingsController(collectionViewLayout: layout)
        settingsController.delegate = self
        settingsController.user = self.user
        navigationController?.pushViewController(settingsController, animated: true)
    }
    
    @objc fileprivate func handleMessage() {
        // handle message, get the button first.
        if let user = self.user {
            let chatController = ChatController(style: .grouped)
            chatController.idToUserDict = [user.uid: user]
            chatController.isFromProfile = true
            navigationController?.pushViewController(chatController, animated: true)
        }
        let chatButton = self.navigationItem.rightBarButtonItem
        if let customView = chatButton?.customView as? ButtonWithCount, let oldcount = customView.count {
            customView.count = 0
            let currentcount = UIApplication.shared.applicationIconBadgeNumber
            if (currentcount - oldcount >= 0 ){
                UIApplication.shared.applicationIconBadgeNumber = currentcount - oldcount
            }else{
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        
    }
    
    @objc func handleDismiss() {
        if wasPushed {
            navigationController?.popViewController(animated: true)
        } else {
            
            if let parent = self.navigationController?.presentingViewController as? FeedHeaderPostViewer {
                parent.pageIndicator.isHidden = false
            }
            
            self.dismiss(animated: true) {
                if self.isCached {
                    MapRender.profileCache.setObject(self, forKey: "CachedProfile")
                }
            }
        }
    }
    
    var postJson = [String: Any]()
    var friendJson = [[String: Any]]()
    var privateProfile: Bool?
    fileprivate func loadProfile(uid: Int?) {
        print("loading profile")
        self.hasLoadedProfile = true
        
        var params = [String: Any]()
        if let uid = uid {
            params["UID"] = uid
        }
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/loadProfile", params: params) { (json, _) in
            guard let json = json as? [String: Any] else {print("WHAT ARE YOU LIDDING "); return }
            print("HREE")
            if let userDict = json["User"] as? [String: Any] {
                var user = User(dictionary: userDict)
                
                if let status = userDict["status"] as? Int, let myId = MainTabBarController.currentUser?.uid {
                    user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: myId)
                } else {
                    user.friendStatus = 3
                }
                
                if !self.isFromSearch {
                    self.user = user
                }
                
                self.performWorkForUser(user: user, partial: false)
                
            }
            
            if let messages = json["Messages"] as? Int, messages > 0 {
                self.updateMessageIcon(messageCount: messages)
            } else {
                self.updateMessageIcon(messageCount: 0)
            }
            
            if let postJson = json["Posts"] as? [[String: Any]], let paginateCount = json["paginatePostCount"] as? Int {
                self.postJson = ["Posts": postJson, "paginatePostCount": paginateCount] as [String: Any]
            }
            
            if let privateProfile = json["privateProfile"] as? Bool {
                self.privateProfile = privateProfile
                print("got it?", json)
            } else {
                print("DUN DUN DUN", json)
            }
            
            if let friendJson = json["Friends"] as? [[String: Any]] {
                self.friendJson = friendJson
            }
            
            if let friendCount = json["FriendCount"] as? Int {
                self.menuBar.friendCount = friendCount
            }
            
            if let postCount = json["PostCount"] as? Int {
                self.menuBar.postCount = postCount
            }
            
            self.collectionView.reloadData()
            
        }
        
    }
    
    fileprivate func performWorkForUser(user: User, partial: Bool) {
        if self.isCached { return }
        
        if !hasLoadedProfile {
            if !partial {
                self.headerView.user = user
                self.menuBar.friendCount = user.friends
                self.menuBar.postCount = user.postcount
                if isFromSearch {
                    self.loadProfile(uid: user.uid)
                } else {
                    self.loadProfile(uid: nil)

                }
            } else {
                self.headerView.partialUser = user
                self.loadProfile(uid: user.uid)
            }
            
        } else if !isFromSearch {
            self.headerView.user = user
            self.menuBar.friendCount = user.friends
            self.menuBar.postCount = user.postcount
        } else {
            self.menuBar.friendCount = user.friends
            self.menuBar.postCount = user.postcount
        }
        self.headerView.checkIfShouldShowIndicatorView()
    }
    
    //menu bar collectionview methods
    fileprivate var isFirstLoad: Bool = true
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if isFirstLoad {
            scrollToMenuIndex(menuIndex: 0, animated: false)
            menuBar.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            isFirstLoad = false
        }
        
        if reloadPostsOnScroll {
            if let cell = cell as? ProfilePostsControllerCell {
                cell.reloadPosts()
                reloadPostsOnScroll = false
            }
        }
    }
    
    func scrollToMenuIndex(menuIndex: Int, animated: Bool) {
        let indexPath = IndexPath(item: menuIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        menuBar.horizontalBarLeftConstraint?.constant = (scrollView.contentOffset.x) / 2
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let item = targetContentOffset.pointee.x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuBar.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
    }
    
    //collectionview methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return profileState == .normal ? 2 : 1
    }
    
    var didSetPostJson: Bool = false
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profilePostsControllerCellId, for: indexPath) as! ProfilePostsControllerCell
            if let user = self.user {
                cell.user = user
            }
            cell.delegate = self
            
            if let pp = self.privateProfile, pp {
                cell.privateProfile = true
            } else {
                cell.postJson = self.postJson
            }
            
            cell.profileState = self.profileState
            
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profileFriendsControllerCellId, for: indexPath) as! ProfileFriendsControllerCell
            if let user = self.user {
                cell.user = user
            }
            cell.friendJson = self.friendJson
            cell.delegate = self
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func updateMessageIcon(messageCount: Int) {
        let chatButton = self.navigationItem.rightBarButtonItem
        if let customView = chatButton?.customView as? ButtonWithCount {
            customView.count = messageCount
        }
    }
    
}

extension ProfileMainController : ProfilePostsControllerCellDelegate {
    
    func privateProfileAction() {
        DispatchQueue.main.async {
            self.headerView.profileEditAddButton.sendActions(for: .touchUpInside)
        }
    }
    
    func presentAlertController(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func presentPostViewer(postViewer: FeedPostViewerController) {
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(postViewer, animated: true)
        }
    }
    
    func updatePostCount(postCount: Int) {
        self.menuBar.postCount = postCount
        self.user?.postcount = postCount
    }
   
    func updateFriendCountFromReload(friendCount: Int) {
        self.menuBar.friendCount = friendCount
        self.user?.friends = friendCount
    }
    
    func decrementPostCount() {
        if let postCount = self.menuBar.postCount {
            self.menuBar.postCount = postCount - 1
            self.didDeletePost = true
        }
    }
}

extension ProfileMainController : ProfileHeaderViewDelegate {

    func displayUserActionSheet(friends:Bool, sharingLocation: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if (friends){
            if (sharingLocation){
                alertController.addAction(UIAlertAction(title: "Stop Sharing Location", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        self.handleStopSharingLocation()
                    }
                }))
            }else{
                alertController.addAction(UIAlertAction(title: "Resume Sharing Location", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        self.handleStartSharingLocation()
                    }
                }))
            }
        }
        alertController.addAction(UIAlertAction(title: "Block User", style: .destructive, handler: { (_) in
            DispatchQueue.main.async {
                self.handleBlock()
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Report User", style: .destructive, handler: { (_) in
            DispatchQueue.main.async {
                self.handleReport()
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func handleBlock() {
        print("blocked")
        guard let id = self.user?.uid else { return }
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/blockUserWithId", params: ["blockId": id]) { (response) in
            if response.response?.statusCode == 200 {
                print("blocked user with uid =", id)
                if let username = self.user?.username {
                    self.animatePopup(title: "Blocked \(username)")
                } else {
                    self.animatePopup(title: "Blocked User")
                }
            }
        }
        
    }
    
    fileprivate func handleReport() {
        print("reported")
        guard let id = self.user?.uid else { return }
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/reportUserWithId", params: ["UID": id]) { (response) in
            if response.response?.statusCode == 200 {
                print("blocked user with uid =", id)
                if let username = self.user?.username {
                    self.animatePopup(title: "Reported \(username)")
                } else {
                    self.animatePopup(title: "Reported User")
                }
            }
        }
    }
    
    
    fileprivate func handleStopSharingLocation(){
        // set the user attribute to true probably, although not sure how to do that and shit. (should be the same user both spots I assume though). 
        print("stop sharing location")
        if let uid = self.user?.uid {
            MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/stopSharingLocationWithUser", params: ["UID":uid]) { (response) in
                if response.response?.statusCode == 200 {
                    if let username = self.user?.username {
                        self.animatePopup(title: "You have stopped sharing location with \(username).")
                    } else {
                        self.animatePopup(title: "You have stopped sharing your location.")
                    }
                    self.user?.sharingLocation = false
                }
            }
            
        }
    }
    
    fileprivate func handleStartSharingLocation(){
        if let uid = self.user?.uid {
            MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/startSharingLocationWithUser", params: ["UID":uid]) { (response) in
                if response.response?.statusCode == 200 {
                    if let username = self.user?.username {
                        self.animatePopup(title: "You have started sharing location with \(username).")
                    } else {
                        self.animatePopup(title: "You have started sharing your location.")
                    }
                    self.user?.sharingLocation = false
                    // ^^^^^^ This is the part where I need you to set this on the user ovject in the thing. 
                    
                    
                }
            }
            
        }
    }
    
    
    
    
    
    func animatePop(title: String) {
        DispatchQueue.main.async {
            self.animatePopup(title: title)
        }
    }
    func displayUserActionSheet(alertController: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func editProfile(state: ProfileState) {
    
        DispatchQueue.main.async {
            
            self.scrollToMenuIndex(menuIndex: 0, animated: true)
            self.menuBar.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            
            UIView.animate(withDuration: 0.3) {
                if state == .editing {
                    self.menuBar.alpha = 0.0
                    self.menuBar.isUserInteractionEnabled = false
                    
                    if let settingsButton = self.navigationItem.rightBarButtonItem {
                        settingsButton.tintColor = .clear
                        settingsButton.isEnabled = false
                    }
                    
                    if let leftButton = self.navigationItem.leftBarButtonItem {
                        leftButton.tintColor = .clear
                        leftButton.isEnabled = false
                    }
                    
                } else {
                    
                    if self.didDeletePost {
                        NotificationCenter.default.post(name: ProfilePostsControllerCell.updateForDeletedPostNotificationName, object: nil)
                        self.didDeletePost = false
                    }
                    
                    self.menuBar.alpha = 1.0
                    self.menuBar.isUserInteractionEnabled = true
                    
                    if let settingsButton = self.navigationItem.rightBarButtonItem {
                        settingsButton.tintColor = .black
                        settingsButton.isEnabled = true
                    }
                    
                    if let leftButton = self.navigationItem.leftBarButtonItem {
                        leftButton.tintColor = .black
                        leftButton.isEnabled = true
                    }
                    
                }
            }
            
            self.profileState = state
            
            
            self.collectionView.reloadData()
            
        }
        
    }
    
    func editProfileImage() {
        checkPhotoPermission { (permission) in
            DispatchQueue.main.async {
                if permission {
                    let layout = UICollectionViewFlowLayout()
                    let photoSelectionController = PhotoSelectionController(collectionViewLayout: layout)
                    photoSelectionController.delegate = self
                    let photoSelectionNavController = UINavigationController(rootViewController: photoSelectionController)
                    self.present(photoSelectionNavController, animated: true, completion: nil)
                } else {
                    let photoPermissionController = PhotoLocationPermissionsViewController()
                    photoPermissionController.isPhotos = true
                    let photoPermissionNavController = UINavigationController(rootViewController: photoPermissionController)
                    self.present(photoPermissionNavController, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    
    
    fileprivate func checkPhotoPermission(completion: @escaping(Bool) -> ()) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    print("success")
                    
                    completion(true)
                } else {
                    
                    completion(false)
                }
            }
        case .restricted:
            print("not access")
            completion(false)
        case .denied:
            print("user denied")
            completion(false)
        }
    }
    
    func didChangeFriendStatus(friendStatus: Int, userId: Int) {
        delegate?.didChangeFriendStatusInProfile(friendStatus: friendStatus, userId: userId) //if user goes from search or likes to profile and adds in header
    }
    
}

extension ProfileMainController: ProfileFriendsControllerCellDelegate {
    
    func showProfile(profileController: ProfileMainController) {
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(profileController, animated: true)
        }
    }
    
    func updateFriendCount(friendCount: Int) {
        self.menuBar.shouldSelectFriends = true
        self.menuBar.friendCount = friendCount
    }
    
}

extension ProfileMainController: PhotoSelectionControllerDelegate {

    func didSelectPhoto(image: UIImage) {
        guard let uid = self.user?.uid else { return }
        headerView.profileImageView.image = image
        headerView.profileImageView.resetProfileImageForUser(image: image, userId: uid)
        headerView.backgroundImageView.image = image
        headerView.backgroundImageView.resetProfileImageForUser(image: image, userId: uid)
        handleUpdateProfileImage(image: image)
    }
    
    fileprivate func handleUpdateProfileImage(image: UIImage) {
        guard let uploadData = image.jpegData(compressionQuality: 0.3) else { return }
        let filename = NSUUID().uuidString
        if let header = UserDefaults.standard.getAuthorizationHeader() {
            guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/updateProfileImage") else {return}
            Alamofire.upload(multipartFormData: { (multipart) in
                multipart.append(uploadData, withName: "file", fileName: "\(filename).jpg", mimeType: "image/jpeg")
            }, usingThreshold: UInt64.init(), to: url, method: .post, headers: header) { (result) in
                switch result{
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        if let JSON = response.result.value as? [String:String], let urlString = JSON["profileImageUrl"], let url = URL(string: urlString) {
                            MainTabBarController.currentUser?.profileImageUrl = url
                        }
                        if let _ = response.error {
                            return
                        }
                    }
                case .failure(let error):
                    print("Error in upload: \(error.localizedDescription)")
                }
            }
        }else{
            // JWT not working.
        }
    }


}

extension ProfileMainController: SettingsControllerDelegate {

    func didMakeChangesToUser(user: User) {
        print("DID MAKE CHANGES")
        self.user = user
        self.headerView.user = user
        self.headerView.setInfoForUser(user: user, override: true)
    }

}

extension ProfileMainController: RequestManagerDelegate {
    func reconnectedToInternet() {
        print("reconnected reloading profile")
        self.loadProfile(uid: self.user?.uid)
    }
}
