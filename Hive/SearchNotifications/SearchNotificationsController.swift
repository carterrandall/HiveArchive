//
//  SearchNotificationCollectionView.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class SearchNotificationsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let searchCellId = "searchCellId"
    fileprivate let notificationsCellId = "notificationCellId"
    
    var user: User?
    
    lazy var menuBar: SearchNotificationMenuBar = {
        let mb = SearchNotificationMenuBar()
        mb.searchNotificationsController = self
        return mb
    }()
    
    lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "cancel"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    let inviteButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.rgb(red: 245, green: 245, blue: 245)
        button.setTitle("Invite Friends", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.setShadow(offset: .zero, opacity: 0.1, radius: 3, color: UIColor.black)
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.addTarget(self, action: #selector(handleInvite), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleInvite() {
        if let username = MainTabBarController.currentUser?.username{
            let sms: String = "sms:&body=Add me on Hive, my username is \(username)! http://hiveios.com/HiveforiOS"
            let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
        }else{
            let sms: String = "sms:&body=Come join me on Hive! http://hiveios.com/HiveforiOS"
            let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainTabBarController.requestManager.delegate = self
        view.backgroundColor = .clear
    
        setupCollectionView()
        setupNavBar()
    }
    
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        menuBar.isHidden = false
        dismissButton.isHidden = false
        
//        whiteView = UIView()
//        whiteView.backgroundColor = .white
//        view.addSubview(whiteView)
//        whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuBar.isHidden = true
        dismissButton.isHidden = true

    }
    
    fileprivate func setupCollectionView() {
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blurView.frame = view.bounds
        view.insertSubview(blurView, at: 0)
        
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.register(SearchControllerCell.self, forCellWithReuseIdentifier: searchCellId)
        collectionView.register(NotificationsControllerCell.self, forCellWithReuseIdentifier: notificationsCellId)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        
        view.addSubview(inviteButton)
        inviteButton.anchor(top: nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 16, paddingRight: 0, width: 120, height: 30)
        inviteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    override func viewSafeAreaInsetsDidChange() {
        collectionView.contentInset = view.safeAreaInsets
    }
    
    var menuBarLeftAnchor: NSLayoutConstraint!
    fileprivate func setupNavBar() {
        
        navigationController?.makeTransparent()
        
        guard let navBar = navigationController?.navigationBar else { return }
        
        navBar.insertSubview(menuBar, at: 0)
        menuBar.anchor(top: navBar.topAnchor, left: nil, bottom: navBar.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: 0)
        menuBarLeftAnchor = menuBar.leftAnchor.constraint(equalTo: navBar.leftAnchor, constant: 0)
        menuBarLeftAnchor.isActive = true

        navBar.addSubview(dismissButton)
        dismissButton.anchor(top: nil, left: navBar.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        navBar.centerYAnchor.constraint(equalTo: navBar.centerYAnchor, constant: -4).isActive = true

    }
    
    func scrollToMenuIndex(menuIndex: Int) {
        let indexPath = IndexPath(item: menuIndex, section: 0)
        if menuIndex == 1 {
          
            if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? SearchControllerCell {
                cell.searchBar.resignFirstResponder()
            } else {
                print("COULDINT DO IT YO")
            }
        }
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        menuBar.horizontalBarLeftConstraint?.constant = scrollView.contentOffset.x / 2
        
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let item = targetContentOffset.pointee.x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuBar.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
       
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: searchCellId, for: indexPath) as! SearchControllerCell
            cell.user = self.user
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: notificationsCellId, for: indexPath) as! NotificationsControllerCell
            cell.delegate = self
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.menuBar.notificationCount != 0 && indexPath.item == 0  {
            self.menuBar.notificationCount = 0
        }
    }
    
}


extension SearchNotificationsController: SearchControllerCellDelegate {
    
    func showProfile(profileController: ProfileMainController) {
        profileController.isFromSearch = true
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(profileController, animated: true)
        }
       
    }
    
    func updateNotificationCount(count: Int) {
        self.menuBar.notificationCount = count
    }
}

extension SearchNotificationsController: NotificationsControllerCellDelegate {
    
    func showProfile(user: User) {
        
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        profileController.wasPushed = true
        navigationController?.pushViewController(profileController, animated: true)
    }
    
    func showPost(postViewer: FeedPostViewerController) {
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(postViewer, animated: true)
        }
    }
    
}

extension SearchNotificationsController: RequestManagerDelegate {
    func reconnectedToInternet() {
        let visibleCell = collectionView.visibleCells.first
        if let vc = visibleCell as? SearchControllerCell {
            vc.paginateSearchValues()
        } else if let vc = visibleCell as? NotificationsControllerCell {
            vc.paginateNotifications()
        }

    }
    
}


