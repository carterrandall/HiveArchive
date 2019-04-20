//
//  NotificationsControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol NotificationsControllerCellDelegate: class {
    func showProfile(user: User)
    func showPost(postViewer: FeedPostViewerController)
}

class NotificationsControllerCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let notificationsCellId = "notificationsCellId"
    
    weak var delegate: NotificationsControllerCellDelegate?
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.showsVerticalScrollIndicator = false
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    fileprivate var selectedPostItem: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(NotificationsCell.self, forCellReuseIdentifier: notificationsCellId)
        tableView.estimatedRowHeight = UIScreen.main.bounds.width <  375 ? 70 : 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = 40.0
        tableView.contentInset.top = 0.0
        tableView.backgroundColor = .white
        setupViews()
        paginateNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        
        addSubview(tableView)
        tableView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    var notifications = [HiveNotification]()
    var lastIndexNotifications: Int = 0
    var isFinishedPagingNotifications: Bool = false
    func paginateNotifications() {
        print("peginating notifications")
        let params = ["lastIndex": lastIndexNotifications]
        self.lastIndexNotifications += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateNotificationsForUser", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            
            json.count < 10 ? (self.isFinishedPagingNotifications = true) : (self.isFinishedPagingNotifications = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    var notification = HiveNotification(dictionary: snapshot)
                    if let pid = snapshot["pid"] as? Int {
                        
                        var post = Post(dictionary: snapshot)
                        
                        post.id = pid
                        notification.post = post
                    }
                    
                    self.notifications.append(notification)
                })
                
                self.tableView.reloadData()
                
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.item == self.notifications.count - 1 && !isFinishedPagingNotifications {
            self.paginateNotifications()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: notificationsCellId, for: indexPath) as! NotificationsCell
        cell.notification = notifications[indexPath.item]
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
}

extension NotificationsControllerCell: NotificationsCellDelegate {

    func showProfile(user: User) {
        delegate?.showProfile(user: user)

    }

    func showPost(cell: NotificationsCell) {

        guard var post = cell.notification?.post else { return }
        post.user = MainTabBarController.currentUser
        let layout = UICollectionViewFlowLayout()
        let postViewer = FeedPostViewerController(collectionViewLayout: layout)
        postViewer.posts = [post]
        postViewer.isFinishedPaging = true
        postViewer.delegate = self
        postViewer.isFromNotifications = true
        delegate?.showPost(postViewer: postViewer)
        if let item = tableView.indexPath(for: cell)?.item {
            self.selectedPostItem = item
        }

    }
}

extension NotificationsControllerCell: FeedPostViewerControllerDelegate {
    func sendBackPost(post: Post) {
        if let item = self.selectedPostItem {
            var notification = notifications[item]
            notification.post = post
            notifications[item] = notification
            tableView.reloadRows(at: [IndexPath(item: item, section: 0)], with: .none)
        }
    }
   
}
