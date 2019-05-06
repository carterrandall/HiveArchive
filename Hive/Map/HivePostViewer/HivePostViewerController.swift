//
//  HivePostViewerController.swift
//  Hive
//
//  Created by Carter Randall on 2019-05-05.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class HivePostViewerController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate let hivePostCellId = "hivePostCellId"
    
    fileprivate var isNewPostsUp: Bool = false
    
    var hiveData: HiveData? {
        didSet {
            print("123")
            guard let hd = hiveData else { return }
            self.loadHiveFeed(hid: hd.id)
            self.navigationItem.title = hd.name
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = view.bounds
        
        view.insertSubview(blurView, at: 0)
        
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: hivePostCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        self.setupNavBar()
        
    }
    
    fileprivate func setupNavBar() {
        navigationController?.makeTransparent()
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
   
        
        let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleDismiss))
        navigationItem.leftBarButtonItem = dismissButton
        
        navigationController?.navigationBar.tintColor = .white
        
    }
    
    @objc fileprivate func handleDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func loadHiveFeed(hid: Int) {
        let params = ["HID":hid]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/maploadHiveFeed", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let postJson = json["Posts"] as? [[String: Any]], let postCount = json["FeedCount"] as? Int {
                self.isFinishedPaging = (postCount < 10 ? true : false)
                self.processPosts(json: postJson, new: false)
            }
        }
    }
    
    fileprivate func paginateHivePosts() {
        print("paginating")
        guard let oldestDate = self.posts.last?.creationDate.timeIntervalSince1970, let newestDate = self.posts.first?.creationDate.timeIntervalSince1970, let hid = self.hiveData?.id else { return }
        let params = ["lastPost": oldestDate, "newestPost": newestDate, "HID": hid] as [String: Any]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/mappaginateHiveFeed", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
           
            if let postJson = json["Posts"] as? [[String: Any]], let postCount = json["FeedCount"] as? Int {
                self.isFinishedPaging = (postCount < 10 ? true : false)
                if let newPostJson = json["NewPosts"] as? [[String: Any]] {
                    print("processPosts 2")
                    self.processPosts(json: postJson, new: false, completion: {
                        DispatchQueue.main.async {
                            print("processPosts 3")
                            self.processPosts(json: newPostJson, new: true)
                            print(self.pids, "pids")
                        }
                    })
                } else {
                    print("processPosts 4")
                    self.processPosts(json: postJson, new: false)
                }
            }
        }
    }
    
    var isFinishedPaging: Bool = false
    var posts = [Post]()
    var pids = [Int]()
    var tempNewPosts = [Post]()
    fileprivate func processPosts(json: [[String: Any]], new: Bool, completion: @escaping() -> () = {}) {
        print("PROCESSING POSTS HIVE FEED")
        
        if json.count > 0 {
            if noPostsStackView != nil {
                self.noPostsStackView.removeFromSuperview()
                self.noPostsStackView = nil
            }
            json.forEach({ (snapshot) in
                var post = Post(dictionary: snapshot)
                
                if !pids.contains(post.id) { //safe guard against duplication
                    pids.append(post.id)
                } else {print("RETURNING", post.id, pids);return }
                
                post.user = User(postdictionary: snapshot)
                post.setPostCache()
                if new {
                    self.tempNewPosts.insert(post, at: 0)
                } else {
                    self.posts.append(post)
                }
            })
            
            if new && self.posts.count > 0 { //maintain scroll position
                self.reloadForNewItems(posts: self.tempNewPosts)
            } else {
                if self.posts.count == 0 {
                    self.posts = self.tempNewPosts
                    self.tempNewPosts.removeAll()
                }
                self.collectionView.reloadData()
                self.collectionView.performBatchUpdates(nil) { (_) in
                    completion()
                }
            }
            
        } else if self.posts.count == 0 {
            self.showNoPostsDisplay()
        }
    }
    
    fileprivate func reloadForNewItems(posts: [Post]) {
        self.tempNewPosts.removeAll()
        let contentHeight = self.collectionView.contentSize.height
        let offsetY = self.collectionView.contentOffset.y
        
        if offsetY < self.collectionView.frame.height {
            posts.forEach { (post) in
                self.posts.insert(post, at: 0)
            }
            self.collectionView.reloadData()
            return
        }
        
        let bottomOffset = contentHeight - offsetY
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.collectionView.performBatchUpdates({
            var indexPaths = [IndexPath]()
            for i in 0..<posts.count {
                let index = 0 + i
                indexPaths.append(IndexPath(item: index, section: 0))
            }
            if indexPaths.count > 0 {
                self.collectionView.insertItems(at: indexPaths)
            }
        }) { (complete) in
            DispatchQueue.main.async {
                self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - bottomOffset)
                CATransaction.commit()
                self.insertNewPostsButton(count: posts.count)
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hivePostCellId, for: indexPath) as! PostCell
        
        if indexPath.item == self.posts.count - 1 && !isFinishedPaging {
            paginateHivePosts()
        }
        
        cell.post = posts[indexPath.item]
          cell.whiteTint = true
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: (view.frame.width * (4/3)) + 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let postCell = cell as? PostCell {
            postCell.player?.pause()
            postCell.player = nil
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            self.checkToPlayVideo()
        }
        if self.isNewPostsUp && scrollView.contentOffset.y < self.view.frame.height {
            self.handleCloseNewPosts()
        }
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            DispatchQueue.main.async {
                self.checkToPlayVideo()
            }
        }
    }
    
    fileprivate func checkToPlayVideo() {
        let visibleCells = collectionView.visibleCells
        var canPlay: Bool = true
        
        for cell in visibleCells {
            
            if let indexPath = collectionView.indexPath(for: cell) {
                if let attributes = self.collectionView.layoutAttributesForItem(at: indexPath) {
                    if canPlay && self.collectionView.frame.contains(collectionView.convert(attributes.center, to: self.view)) {
                        if let postCell = cell as? PostCell, postCell.post?.videoUrl != nil , !(postCell.player?.isPlaying ?? false) {
                            canPlay = false
                            
                            postCell.handlePlay()
                        }
                    } else {
                        if let postCell = cell as? PostCell, postCell.post?.videoUrl != nil, (postCell.player?.isPlaying ?? true) {
                            postCell.player?.pause()
                            postCell.player = nil
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func endVideos() {
        let visibleCells = collectionView.visibleCells
        for visibleCell in visibleCells {
            if let cell = visibleCell as? PostCell {
                cell.player?.pause()
                cell.player = nil
            }
        }
        self.collectionView.contentOffset = self.collectionView.contentOffset
    }
    
    var noPostsStackView: UIStackView!
    fileprivate func showNoPostsDisplay() {
        print("SHOWING NO POSTS")
        guard noPostsStackView == nil else {return}
        let noPostsLabel = UILabel()
        noPostsLabel.text = "No posts here yet!"
        noPostsLabel.font = UIFont.boldSystemFont(ofSize: 26)
        noPostsLabel.textAlignment = .center
        noPostsLabel.textColor = .darkGray
        
        
        let detailLabel = UILabel()
        detailLabel.text = "Share something to get the ball rolling."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        detailLabel.font = UIFont.systemFont(ofSize: 18)
        detailLabel.textColor = .lightGray
        
        noPostsStackView = UIStackView(arrangedSubviews: [noPostsLabel, detailLabel])
        noPostsStackView.axis = .vertical
        noPostsStackView.spacing = 16
        
        view.addSubview(noPostsStackView)
        noPostsStackView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        noPostsStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
    }
    
    var newPostsButton: UIButton!
    fileprivate func insertNewPostsButton(count: Int) {
        if isNewPostsUp {
            if let currentLabel = newPostsButton.titleLabel?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "01234567890").inverted), let currentCount = Int(currentLabel) {
                print("currentlabel", currentLabel)
                let newCount = currentCount + count
                newPostsButton.setTitle("\(newCount) New Post\(newCount == 1 ? "" : "s")", for: .normal)
            } else {
                print("COUNLDINT GET CURRENT LABEL")
                newPostsButton.setTitle("\(count) New Post\(count == 1 ? "" : "s")", for: .normal)
            }
        } else {
            isNewPostsUp = true
            newPostsButton = UIButton(type: .system)
            newPostsButton.backgroundColor = .mainRed()
            newPostsButton.setTitle("\(count) New Post \(count == 1 ? "" : "s")", for: .normal)
            newPostsButton.setTitleColor(.white, for: .normal)
            newPostsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            newPostsButton.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
            newPostsButton.layer.cornerRadius = 15
            newPostsButton.addTarget(self, action: #selector(handleScrollToTop), for: .touchUpInside)
            
            let closeNewPostsButton = UIButton(type: .system)
            closeNewPostsButton.setImage(UIImage(named: "fatX"), for: .normal)
            closeNewPostsButton.tintColor = .white
            closeNewPostsButton.addTarget(self, action: #selector(handleCloseNewPosts), for: .touchUpInside)
            
            view.addSubview(newPostsButton)
            newPostsButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 80, paddingBottom: 0, paddingRight: 80, width: 0, height: 30)
            
            newPostsButton.addSubview(closeNewPostsButton)
            closeNewPostsButton.anchor(top: newPostsButton.topAnchor, left: nil, bottom: newPostsButton.bottomAnchor, right: newPostsButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 30, height: 30)
            
        }
        
    }
    
    @objc fileprivate func handleScrollToTop() {
        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        UIView.animate(withDuration: 0.3, animations: {
            self.newPostsButton.alpha = 0.0
        }) { (complete) in
            self.newPostsButton.removeFromSuperview()
        }
    }
    
    @objc fileprivate func handleCloseNewPosts() {
        UIView.animate(withDuration: 0.3, animations: {
            self.newPostsButton.alpha = 0.0
        }) { (_) in
            self.newPostsButton.removeFromSuperview()
            self.isNewPostsUp = false
        }
    }
}

extension HivePostViewerController: PostCellDelegate {
    
    func didTapComments(cell: PostCell) {
        endVideos()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let commentsLikesController = CommentsLikesController(collectionViewLayout: layout)
        if let index = collectionView.indexPath(for: cell)?.item {
            commentsLikesController.index = index
        }
        commentsLikesController.post = cell.post
        commentsLikesController.delegate = self
        let commentsLikesNavController = UINavigationController(rootViewController: commentsLikesController)
        self.present(commentsLikesNavController, animated: true, completion: nil)
    }
    
    func didTapShare(post: Post) {
        endVideos()
        let sharePostController = SharePostController()
        sharePostController.post = post
        let sharePostNavController = UINavigationController(rootViewController: sharePostController)
        self.present(sharePostNavController, animated: true, completion: nil)
    }
    
    func didTapLike(cell: PostCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard var post = cell.post else { return }
        let hasLiked = post.hasLiked
        post.hasLiked = !hasLiked
        post.setPostCache()
        DispatchQueue.main.async {
            self.posts[indexPath.item] = post
            if !hasLiked {
                cell.animateLike()
            }
            
            cell.post?.changeLikeOnPost(completion: { (_) in
                cell.post?.hasLiked = !hasLiked
            })
        }
    }
    
    func didTapProfile(user: User) {
        endVideos()
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        let profileNavController = UINavigationController(rootViewController: profileController)
        self.present(profileNavController, animated: true, completion: nil)
    }
    
}

extension HivePostViewerController: CommentsLikesControllerDelegate {
    
    func didCommentOrDelete(index: Int, increment: Int) {
        print("updating comments")
        var post = posts[index]
        if let comments = post.comments {
            DispatchQueue.main.async {
                post.comments = comments + increment
                self.posts[index] = post
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
    
}
