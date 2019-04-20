//
//  HomeFeedControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-22.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol HomeFeedControllerCellDelegate: class {
    func updateMessageIcon(messageCount: Int)
    func didTapShare(post: Post)
    func didTapComments(commentsLikesController: CommentsLikesController)
    func didTapProfile(user: User)
    func didSelectStory(postViewer: FeedHeaderPostViewer)
    func openCamera()
}

class HomeFeedControllerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let postCellId = "postCellId"
    fileprivate let headerId = "headerId"
    fileprivate let gridCellId = "gridCellId"
    fileprivate var isNewPostsUp: Bool = false
    
    weak var delegate: HomeFeedControllerCellDelegate?
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.backgroundColor = .white
        cv.delegate = self
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .mainRed()
        refreshControl.addTarget(self, action: #selector(reloadFeed), for: .valueChanged)
        cv.refreshControl = refreshControl
        cv.addSubview(refreshControl)
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white

        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: postCellId)
        collectionView.register(HomeHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.register(FeedPostGridCell.self, forCellWithReuseIdentifier: gridCellId)
        
        loadFeed()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var headerJson = [String: Any]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    fileprivate func loadFeed() {
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/loadFeed", params: nil) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let messages = json["Messages"] as? Int {
                self.delegate?.updateMessageIcon(messageCount: messages)
            }
            
            if let headerJson = json["Header"] as? [[String: Any]], let count = json["HeaderCount"] as? Int {
                
                self.headerJson = ["json": headerJson, "count": count]
                print(headerJson, "HEADER JSON HERE")
                
            } else {
                print("bad header or no json")
            }
            
            if let postJson = json["Posts"] as? [[String: Any]], let postCount = json["FeedCount"] as? Int {
                
                DispatchQueue.main.async {
                    self.processPosts(json: postJson, new: false)
                }
                self.isFinishedPaging = (postCount < 10 ? true : false)
            } else {
                print("DAM DUDE")
            }
        }
        
        
    }

    
    fileprivate func paginateFeed() {
        print("PAYGENAYTING")
        guard let oldestDate = self.posts.last?.creationDate.timeIntervalSince1970, let newestDate = self.posts.first?.creationDate.timeIntervalSince1970 else { return }
        let params = ["lastPost": oldestDate, "newestPost": newestDate] as [String: Any]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateFeed", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let messages = json["Messages"] as? Int {
                self.delegate?.updateMessageIcon(messageCount: messages)
            }
            
            if let postJson = json["Posts"] as? [[String: Any]], let postCount = json["FeedCount"] as? Int {
                self.isFinishedPaging = (postCount < 10 ? true : false)
                
                
                if let newPostJson = json["NewPosts"] as? [[String: Any]], newPostJson.count > 0 {
                    self.processPosts(json: postJson, new: false, completion: {
                        DispatchQueue.main.async {
                            self.processPosts(json: newPostJson, new: true)
                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        self.processPosts(json: postJson, new: false)
                    }
                }
            }
            
        }
    }
    
    var isFinishedPaging: Bool = false
    var posts = [Post]()
    var pids = [Int]()
    var tempNewPosts = [Post]()
    fileprivate func processPosts(json: [[String: Any]], new: Bool, completion: @escaping() -> () = {}) {
        print("processing posts home feed")
        if json.count > 0 {
            if noPostsStackView != nil {
                self.noPostsStackView.removeFromSuperview()
                self.noPostsStackView = nil
                print("REMOVED IT")
            } else {
                print("NIL")
            }
            print(json.count, "HOME FEED JSON OCUNT")
            json.forEach({ (snapshot) in
               
                var post = Post(dictionary: snapshot)
                
                if !pids.contains(post.id) { //safe guard against duplication
                    pids.append(post.id)
                } else {
                    print("RETURNING home feed")
                    return
                }
                
                post.user = User(postdictionary: snapshot)
                post.setPostCache()
                
                if new {
                    self.tempNewPosts.insert(post, at: 0)
                } else {
                    self.posts.append(post)
                }
            })

            if new && self.posts.count > 0 {
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
        } else if new {
            self.collectionView.reloadData()
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
                self.posts.insert(posts[i], at: 0)
                indexPaths.append(IndexPath(item: i, section: 0))
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
    
    @objc func reloadFeed() {
        
        let newestPost = self.posts.first?.creationDate.timeIntervalSince1970 ?? 0
        let params = ["newestPost": newestPost]
        self.collectionView.refreshControl?.beginRefreshing()
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/reloadFeed", params: params) { (json, _) in
            self.collectionView.refreshControl?.endRefreshing()
            guard let json = json as? [String: Any] else { return }
            if let messages = json["Messages"] as? Int {
                self.delegate?.updateMessageIcon(messageCount: messages)
            }
            if let postJson = json["NewPosts"] as? [[String: Any]] {
                if postJson.count == 10 {
                    print("NEW NEW PROTOCOL")
                    self.posts.removeAll()
                    self.pids.removeAll()
                    self.isFinishedPaging = false
                    self.processPosts(json: postJson, new: false)
                } else {
                    DispatchQueue.main.async {
                        self.processPosts(json: postJson, new: true)
                    }
                }
            }
            if let headerJson = json["Header"] as? [[String: Any]], let count = json["HeaderCount"] as? Int {
                print(count, "HOME FEED ZZZZZZZZZ")
                DispatchQueue.main.async {
                    if let homeHeader = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? HomeHeaderCell {
                        
                        homeHeader.processHeaderJson(headerJson: ["json":headerJson,"count":count])
                        
                    }
                }
            }
            
        }
    }


    
    @objc func refresh() { //complete wipe, used when user deletes a post or recconects to internet
        DispatchQueue.main.async {
            self.posts.removeAll()
            self.pids.removeAll()
            self.isFinishedPaging = false
            self.loadFeed()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.item == self.posts.count - 1 && !isFinishedPaging {
            paginateFeed()
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellId, for: indexPath) as! PostCell
        if posts.count > 0 {
            cell.post = posts[indexPath.item]
        }
        cell.delegate = self
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width, height: (frame.width * (4/3)) + 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let cellWidth = ((frame.width) / (UIScreen.main.bounds.width <  375 ? 5 : 6))
        return CGSize(width: frame.width, height: cellWidth + 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HomeHeaderCell
        
        if header.headerJson == nil && self.headerJson.count > 0 {
            header.headerJson = self.headerJson
        }
        
        header.delegate = self
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 0, bottom: 30, right: 0)
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
        if self.isNewPostsUp && scrollView.contentOffset.y < self.frame.height {
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
                    if canPlay && collectionView.frame.contains(collectionView.convert(attributes.center, to: self)) {
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

    func endPlayingVideos() {
       
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
        guard noPostsStackView == nil else {print("ah the shit was already added"); return }
        print("SHOWING NO POSTS")
        let noPostsLabel = UILabel()
        noPostsLabel.text = "No posts here yet!"
        noPostsLabel.font = UIFont.boldSystemFont(ofSize: 26)
        noPostsLabel.textAlignment = .center
        noPostsLabel.textColor = .darkGray
        
        
        let detailLabel = UILabel()
        detailLabel.text = "Add friends or share something to see fresh posts here."
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        detailLabel.font = UIFont.systemFont(ofSize: 18)
        detailLabel.textColor = .lightGray
        
        noPostsStackView = UIStackView(arrangedSubviews: [noPostsLabel, detailLabel])
        noPostsStackView.axis = .vertical
        noPostsStackView.spacing = 16
        
        addSubview(noPostsStackView)
        noPostsStackView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        noPostsStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        
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
            newPostsButton.setTitle("\(count) New Post\(count == 1 ? "" : "s")", for: .normal)
            newPostsButton.setTitleColor(.white, for: .normal)
            newPostsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            newPostsButton.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
            newPostsButton.layer.cornerRadius = 15
            newPostsButton.addTarget(self, action: #selector(handleScrollToTop), for: .touchUpInside)
            
            let closeNewPostsButton = UIButton(type: .system)
            closeNewPostsButton.setImage(UIImage(named: "fatX"), for: .normal)
            closeNewPostsButton.tintColor = .white
            closeNewPostsButton.addTarget(self, action: #selector(handleCloseNewPosts), for: .touchUpInside)
            
            addSubview(newPostsButton)
            newPostsButton.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 80, paddingBottom: 0, paddingRight: 80, width: 0, height: 30)
            
            newPostsButton.addSubview(closeNewPostsButton)
            closeNewPostsButton.anchor(top: newPostsButton.topAnchor, left: nil, bottom: newPostsButton.bottomAnchor, right: newPostsButton.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 30, height: 30)
            
        }
        
    }
    
    @objc fileprivate func handleScrollToTop() {
        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        handleCloseNewPosts()
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

extension HomeFeedControllerCell: PostCellDelegate {
    
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
            
            
            cell.post?.changeLikeOnPost { (_) in
                cell.post?.hasLiked = !hasLiked
               
            }
        }
    }
    
    func didTapShare(post: Post) {
        delegate?.didTapShare(post: post)
    }
    
    func didTapComments(cell: PostCell) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let commentsLikesController = CommentsLikesController(collectionViewLayout: layout)
        if let index = collectionView.indexPath(for: cell)?.item {
            commentsLikesController.index = index
        }
        commentsLikesController.post = cell.post
        commentsLikesController.delegate = self
        delegate?.didTapComments(commentsLikesController: commentsLikesController)
    }
    
    func didTapProfile(user: User) {
        delegate?.didTapProfile(user: user)
    }
    
}

extension HomeFeedControllerCell: CommentsLikesControllerDelegate {
    
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

extension HomeFeedControllerCell: HomeHeaderCellDelegate {
    func showPostViewer(postViewer: FeedHeaderPostViewer) {
        delegate?.didSelectStory(postViewer: postViewer)

    }
    func updateMessages(messageCount: Int) {
        delegate?.updateMessageIcon(messageCount: messageCount)
    }
    
    func openCamera() {
        delegate?.openCamera()
    }
}

extension HomeFeedControllerCell: FeedPostViewerControllerDelegate {
    func didPageForMorePosts(posts: [Post?], isFinishedPaging: Bool) {
        self.isFinishedPaging = isFinishedPaging
        self.posts = posts as! [Post]
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    func didLikePost(index: Int, post: Post) {
        self.posts[index] = post
        DispatchQueue.main.async {
            self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }
    func viewerWillDismiss(indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
    }
}

