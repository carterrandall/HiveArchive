//
//  FeedMainController.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-22.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol FeedMainControllerLayoutDelegate {
    func toggleLayout()
}

class FeedMainController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate var feedImageIsPage: Bool = false
    
    fileprivate let hiveControllerCellId = "hiveControllerCellId"
    fileprivate let homeControllerCellId = "homeControllerCellId"
    
    fileprivate var isInHive: Bool = false
    fileprivate var user: User?
    
    fileprivate var isFirstLoad: Bool = true
   
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        whiteView = UIView()
        whiteView.backgroundColor = .white
        view.addSubview(whiteView)
        whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 4, paddingRight: 0, width: 0, height:0)
        
        setNavBarAppearance()
        
        if let hid = user?.HID, hid != 0 {
            menuBar.isHidden = false
        }
    
        print("HANDLE RECONNECTED TO INTERNET check if connected, if so and view is up then remove it")
        
        if AppDelegate.BecameActive {
            print("BECAME AC TIVE")
            self.handleReload()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let hid = user?.HID, hid != 0 {
            menuBar.isHidden = true
        }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainTabBarController.requestManager.delegate = self
        
        view.backgroundColor = .white
        
        fetchUserAndCheckHiveStatus()
        setupCollectionView()
        setupNavBar()
        addObservers()

    }
    
    func fetchUserAndCheckHiveStatus() {
        guard let user = MainTabBarController.currentUser else { return }
        self.user = user
        print("CHECKING HIVE STATUS", user)
        if let hid = user.HID, hid != 0 {
            print("USER IS IN HIVE")
            self.isInHive = true
            self.menuBar.isHidden = false 
            self.navigationItem.title = nil
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.collectionView.performBatchUpdates(nil, completion: { (_) in
                    self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: false)
                    self.menuBar.collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                })
            }
        }
        else {
            self.isInHive = false
            self.menuBar.isHidden = true
            self.navigationItem.title = "Feed"
        }
    }
    
    lazy var menuBar: FeedMenuBar = {
        let mb = FeedMenuBar()
        mb.feedMainController = self
        return mb
    }()

    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleReload), name: PreviewPhotoController.updateForNewPostNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: ProfilePostsControllerCell.updateForDeletedPostNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInHiveFeed(_:)), name: MapRender.didEnterHiveNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNoLongerInHiveFeed), name: MapRender.didExitHiveNotificationName, object: nil)
    }
    
    @objc func handleNoLongerInHiveFeed() {
        DispatchQueue.main.async {
            self.isInHive = false
            self.user?.HID = nil
            self.navigationItem.title = "Feed"
            self.menuBar.isHidden = true
            self.menuBar.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            if let hiveFeedCell = self.collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? HiveFeedControllerCell {
                hiveFeedCell.isFinishedPaging = false
                hiveFeedCell.posts.removeAll()
                hiveFeedCell.pids.removeAll()
            }
            self.collectionView.reloadData()
        }
    }

    
    @objc func handleInHiveFeed(_ notification: NSNotification) {
        DispatchQueue.main.async {
            if let hid = notification.userInfo?["HID"] as? Int {
                self.user?.HID = hid
                self.isInHive = true
            }
            
            self.menuBar.isHidden = false
            self.navigationItem.title = nil
            
            self.collectionView.reloadData()
            self.collectionView.performBatchUpdates(nil, completion: { (_) in
                DispatchQueue.main.async {
                    self.menuBar.collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                    self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: false)
                }
            })
        }
    }
    
    fileprivate func setupCollectionView() {
        
        collectionView.backgroundColor = .white
        collectionView.register(HiveFeedControllerCell.self, forCellWithReuseIdentifier: hiveControllerCellId)
        collectionView.register(HomeFeedControllerCell.self, forCellWithReuseIdentifier: homeControllerCellId)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.contentInsetAdjustmentBehavior = .never

    }
    
    var reloadHomeFeedOnScroll: Bool = false
    var reloadHiveFeedOnScroll: Bool = false
    
    @objc fileprivate func handleReload() {
        if let visibleCell = collectionView.visibleCells.first as? HomeFeedControllerCell {
            visibleCell.reloadFeed()
            reloadHiveFeedOnScroll = true
        
        } else if let visibleCell = collectionView.visibleCells.first as? HiveFeedControllerCell {
            visibleCell.reloadFeed()
            reloadHomeFeedOnScroll = true
        }
        
    }
    
    var refreshHomeFeedOnScroll: Bool = false
    var refreshHiveFeedOnScroll: Bool = false
    @objc fileprivate func handleRefresh() {
        if let visibleCell = collectionView.visibleCells.first as? HomeFeedControllerCell {
            visibleCell.refresh()
            refreshHiveFeedOnScroll = true
            
        } else if let visibleCell = collectionView.visibleCells.first as? HiveFeedControllerCell {
            visibleCell.refresh()
            refreshHomeFeedOnScroll = true
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? HomeFeedControllerCell, indexPath.item == 0 {
            if reloadHomeFeedOnScroll {
                cell.reloadFeed()
                reloadHomeFeedOnScroll = false

            } else if refreshHomeFeedOnScroll {
                cell.refresh()
                refreshHomeFeedOnScroll = false
            }
        } else if let cell = cell as? HiveFeedControllerCell, indexPath.item == 1 {
            if reloadHiveFeedOnScroll {
                cell.reloadFeed()
                reloadHiveFeedOnScroll = false
            } else if refreshHiveFeedOnScroll {
                cell.refresh()
                refreshHiveFeedOnScroll = false
            }

        } else {
            print("COULDINT GET CELL")
        }
    }

    fileprivate func setupNavBar() {
        setNavBarAppearance()
       
        guard let navBar = navigationController?.navigationBar else { return }
        
        let profileButton = UIBarButtonItem(image: UIImage(named: "profile")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleProfile))
        navigationItem.leftBarButtonItem = profileButton
        
        let customView: ButtonWithCount = {
            let button = ButtonWithCount(type: .system)
            button.paddingTop = -5
            button.setImage(UIImage(named: "chat")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.count = 0
            button.addTarget(self, action: #selector(handleChat), for: .touchUpInside)
            return button
        }()
        
        let chatButton = UIBarButtonItem(customView: customView)
        navigationItem.rightBarButtonItem = chatButton
        
        navBar.addSubview(menuBar)
        menuBar.anchor(top: navBar.topAnchor, left: navBar.leftAnchor, bottom: navBar.bottomAnchor, right: navBar.rightAnchor, paddingTop: 0, paddingLeft: 60, paddingBottom: 0, paddingRight: 60, width: 0, height: 0)
        
    }
    
    fileprivate func setNavBarAppearance() {
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.mainRed(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.makeTransparent()

    }
    
    @objc func handleProfile() {
        endVideosInChildCells()
        
        var profileController: ProfileMainController!
        if let cachedVersion = MapRender.profileCache.object(forKey: "CachedProfile") {
            profileController = cachedVersion
            profileController.isCached = true
        } else {
            profileController = ProfileMainController()
            MapRender.profileCache.setObject(profileController, forKey: "CachedProfile")
        }
        
        if let currentUser = MainTabBarController.currentUser {
            profileController.user = currentUser
        } else {
            profileController.user = self.user
        }
        
        let profileMainNavController = UINavigationController(rootViewController: profileController)
        self.tabBarController?.present(profileMainNavController, animated: true, completion: nil)

    }
    
    @objc func handleChat() {
        endVideosInChildCells()
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false) //lock scroll to load new view
        let chatController = ChatLogController()
        chatController.delegate = self
        let chatNavController = UINavigationController(rootViewController: chatController)
       // chatNavController.modalPresentationStyle = .overFullScreen
        self.tabBarController?.present(chatNavController, animated: true, completion: nil)
    }
  
    func scrollToMenuIndex(menuIndex: Int) {
        endVideosInChildCells()
        let indexPath = IndexPath(item: menuIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        menuBar.horizontalBarLeftConstraint?.constant = ((scrollView.contentOffset.x) * ((view.frame.width - 120) / view.frame.width)) / 2
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let item = targetContentOffset.pointee.x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuBar.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
        endVideosInChildCells()

    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homeControllerCellId, for: indexPath) as! HomeFeedControllerCell
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hiveControllerCellId, for: indexPath) as! HiveFeedControllerCell
            
            if let hid = self.user?.HID {
                cell.HID = hid
            }
            
            cell.delegate = self
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isInHive ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func endVideosInChildCells() {
        print("ENDING THAT SHIT")
        let visibleCells = collectionView.visibleCells
        for cell in visibleCells {
            if let cell = cell as? HomeFeedControllerCell {
                
                cell.endPlayingVideos()
            } else if let cell = cell as? HiveFeedControllerCell {
                cell.endPlayingVideos()
            }
        }
    }
 
}

extension FeedMainController: HomeFeedControllerCellDelegate, HiveFeedControllerCellDelegate {
    
    func didTapShare(post: Post) {
        endVideosInChildCells()
        let sharePostController = SharePostController()
        sharePostController.post = post
        let sharePostNavController = UINavigationController(rootViewController: sharePostController)
        self.tabBarController?.present(sharePostNavController, animated: true, completion: nil)
    }
    
    func didTapComments(commentsLikesController: CommentsLikesController) {
        endVideosInChildCells()
        let commentsLikesNavController = UINavigationController(rootViewController: commentsLikesController)
        self.tabBarController?.present(commentsLikesNavController, animated: true, completion: nil)
    }
    
    func didTapProfile(user: User) {
        endVideosInChildCells()
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        let profileNavController = UINavigationController(rootViewController: profileController)
        self.tabBarController?.present(profileNavController, animated: true, completion: nil)

    }
    
    func didSelectStory(postViewer: FeedHeaderPostViewer) {
        endVideosInChildCells()
        self.tabBarController?.present(postViewer, animated: true, completion: nil)
    }
    
    func updateMessageIcon(messageCount: Int) {
        let chatButton = self.navigationItem.rightBarButtonItem
        print("updating")
        if let customView = chatButton?.customView as? ButtonWithCount {
            print("GOT VIEW UPDATING", messageCount)
            customView.count = messageCount
        }
    }
    
    func openCamera() {
        DispatchQueue.main.async {
            if let mtbc = self.tabBarController as? MainTabBarController {
                mtbc.presentCamera(selectedIndex: 2)
            }
        }
    }
    
}

extension FeedMainController: ChatLogControllerDelegate {
    
    func updateMessages() {
        MainTabBarController.requestManager.getJsonRequest(urlString: "/Hive/api/checkfeedmessages", params: nil) { (messages) in
            if let count = messages["Messages"] as? Int {
                self.updateMessageIcon(messageCount: count)
            }
            
        }
    }
}

extension FeedMainController: RequestManagerDelegate {
    func reconnectedToInternet() {
        print("Reconnected refreshing feed")
        handleRefresh()
    }
}
