//
//  HomeHeaderCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-23.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol HomeHeaderCellDelegate: class {
    func showPostViewer(postViewer: FeedHeaderPostViewer)
    func updateMessages(messageCount: Int)
    func openCamera()
}

class HomeHeaderCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let userCellId = "userCellId"
    
    weak var delegate: HomeHeaderCellDelegate?
    
    var headerJson: [String: Any]? {
        didSet {
            if self.orderedUids.count > 0 { return }
            if let json = headerJson {
                DispatchQueue.main.async {
                    self.processHeaderJson(headerJson: json)
                }
            }
        }
    }
    
    var currentUser: User?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceHorizontal = true
        cv.decelerationRate = .fast
        return cv
    }()
//
//    let nearbyLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Nearby"
//        label.textColor = UIColor.lightGray
//        label.font = UIFont.boldSystemFont(ofSize: 14)
//        label.textAlignment = .center
//        return label
//    }()
//
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        self.currentUser = MainTabBarController.currentUser
        
        collectionView.register(MFCell.self, forCellWithReuseIdentifier: userCellId)
        
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
//        addSubview(nearbyLabel)
//        nearbyLabel.anchor(top: collectionView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addObservers()
      
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateCellBorder(_:)), name: FeedHeaderPostViewer.updateFeedHeaderNotificationName, object: nil)

    }
    
    @objc func updateCellBorder(_ notification: NSNotification) {
        
        if let storiesDict = notification.userInfo as? [Int: Story] {
            uidToStoryDict = storiesDict
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
    }
    
//    func reloadHeader(headerJson: [[String: Any]]) {
//        print("reloading header")
//        self.orderedUids.removeAll()
//        self.uidToStoryDict.removeAll()
//        self.isFinishedPaging = false
//        self.pids.removeAll()
//        self.lastIndex = 0
//        self.processHeaderJson(headerJson: ["json": headerJson])
//    }
//
    fileprivate func paginateHeader() {
        print("paginating home header")
        self.lastIndex += 1
        let params = ["lastIndex": self.lastIndex]
        
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateHeader", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let messages = json["Messages"] as? Int {
                self.delegate?.updateMessages(messageCount: messages)
            }
            if let postJson = json["Header"] as? [[String: Any]], let count = json["HeaderCount"] as? Int {
                let hjson = ["json": postJson, "count": count] as [String : Any]
                self.processHeaderJson(headerJson: hjson)
            }
        }
    }
    
    fileprivate var orderedUids = [Int]()
    fileprivate var uidToStoryDict = [Int: Story]()
    fileprivate var isFinishedPaging: Bool = false
    fileprivate var pids = [Int]()
    var lastIndex = 0
    func processHeaderJson(headerJson: [String: Any]) {
     
        if let count = headerJson["count"] as? Int {
            isFinishedPaging = (count < 10 ? true : false)
        }
        
        if let json = headerJson["json"] as? [[String: Any]] {
    
            if json.count > 0 {
                json.forEach({ (snapshot) in
    
                    var post = Post(dictionary: snapshot)
                    
                    if !pids.contains(post.id) {
                        pids.append(post.id)
                    } else {
                        print("returning, home header")
                        return
                    }
                    
                    let user = User(postdictionary: snapshot)
                
                    post.user = user
                    if let seen = snapshot["seen"] as? Bool, seen {
                        post.seen = true
                    } else {
                        post.seen = false
                    }
                    post.setPostCache()
                    if self.uidToStoryDict[user.uid] == nil {
                        self.orderedUids.append(user.uid)
                        var story = Story(user: user, posts: [post])
                        
                        if let seen = post.seen, !seen {
                            story.firstUnseenPostIndex = 0
                            story.hasSeenAllPosts = false
                        }
                        
                        self.uidToStoryDict[user.uid] = story
                        
                    } else {
                        
                        self.uidToStoryDict[user.uid]?.posts.append(post)
                        
                        self.uidToStoryDict[user.uid]?.posts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                        })
                        
                        if let seen = post.seen, !seen {
                            if self.uidToStoryDict[user.uid]?.firstUnseenPostIndex == nil {
                                let story = self.uidToStoryDict[user.uid]
                                print("no unseen yet setting to ", (story?.posts.count  ?? 1) - 1, user.username)
                                self.uidToStoryDict[user.uid]?.firstUnseenPostIndex = (story?.posts.count ?? 1) - 1
                                self.uidToStoryDict[user.uid]?.hasSeenAllPosts = false
                            }
                    
                        } 
                    }
                    
                })
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            delegate?.openCamera()
        } else {
            guard orderedUids.count > 0 else { return }
            let postViewer = FeedHeaderPostViewer()
            postViewer.orderedUids = orderedUids
            postViewer.storiesDict = uidToStoryDict
            postViewer.startingUid = orderedUids[indexPath.item - 1]
            postViewer.isFinishedPaging = isFinishedPaging
            postViewer.lastIndex = self.lastIndex
            postViewer.modalPresentationStyle = .overFullScreen
            postViewer.modalPresentationCapturesStatusBarAppearance = true
            postViewer.delegate = self
            delegate?.showPostViewer(postViewer: postViewer)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return orderedUids.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userCellId, for: indexPath) as! MFCell
        
        if indexPath.item == 0 {
            var story = Story(user: self.currentUser!, posts: [])// get rid of bang bang
            story.hasSeenAllPosts = false
            cell.story = story
            cell.addOverlayButton()
        
        } else {
            if indexPath.item == orderedUids.count && !isFinishedPaging {
                self.paginateHeader()
            }
            
            let uid = orderedUids[indexPath.item - 1]
            if let story = uidToStoryDict[uid] {
                cell.story = story
            }
            
        }
        
        return cell
        
    }
    
    let width: CGFloat = ((UIScreen.main.bounds.width) / (UIScreen.main.bounds.width <  375 ? 5 : 6))
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = frame.width * 0.0193236715
        return UIEdgeInsets.init(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
}

extension HomeHeaderCell: FeedHeaderPostViewerDelegate {
    
    func updateMessageCount(count: Int) {
        delegate?.updateMessages(messageCount: count)
    }
    
    
    func scrollToUserWithUidAndUpdateHeaderCell(uidToScrollTo: Int, orderedUids: [Int], storiesDict: [Int : Story], isFinishedPaging: Bool, lastIndex: Int) {
        print("UPDATING")
    
        DispatchQueue.main.async {
            
            if self.orderedUids.count < orderedUids.count { //header paginaed extra users
                print("header had more")
                self.orderedUids = orderedUids
                self.uidToStoryDict = storiesDict
                self.isFinishedPaging = isFinishedPaging
                self.lastIndex = lastIndex
                
            } else {
                print("header had less")
                for id in orderedUids {
                    self.uidToStoryDict[id] = storiesDict[id]
                    if !(self.orderedUids.contains(id)) { //just in case
                        self.orderedUids.append(id)
                    }
                }
            }

            self.collectionView.reloadData()
            
            if let index = orderedUids.firstIndex(of: uidToScrollTo) {
                self.collectionView.scrollToItem(at: IndexPath(item: index + 1, section: 0), at: .centeredHorizontally, animated: false)
            }
            
        }
        
    }
   
}
