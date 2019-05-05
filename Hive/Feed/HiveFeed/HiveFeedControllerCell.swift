//
//  HiveControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-22.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol NearbyFeedControllerCellDelegate: class {
    func updateMessageIcon(messageCount: Int)
    func didTapShare(post: Post)
    func didTapComments(commentsLikesController: CommentsLikesController)
    func didTapProfile(user: User)
    func didSelectStory(postViewer: FeedHeaderPostViewer)
    func openCamera()
}

class NearbyFeedControllerCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: NearbyFeedControllerCellDelegate?
    
    fileprivate let postCellId = "postCellId"
    fileprivate let headerId = "headerId"
    fileprivate let gridCellId = "gridCellId"
    
    fileprivate var isNewPostsUp: Bool = false

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .white
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .mainRed()
        refreshControl.addTarget(self, action: #selector(reloadFeed), for: .valueChanged)
        cv.refreshControl = refreshControl
        cv.addSubview(refreshControl)
        return cv
    }()
    
    @objc fileprivate func reloadFeed() {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 0, width: 0, height: 0)
        collectionView.register(HiveHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: postCellId)
        collectionView.register(FeedPostGridCell.self, forCellWithReuseIdentifier: gridCellId)
        
        fetchNearbyPosts()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func fetchNearbyPosts() {
        print("fetching posts")
        guard let coord = MapRender.mapView.userLocation?.coordinate else { return}
        let params = ["latitude":coord.latitude,"longitude":coord.longitude] as [String: Any]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/loadNearbyFeed", params: params) { (json, sc) in
            if let sc = sc, sc != 200 {
                print("Failed to fetch nearby posts", sc)
            }
            guard let json = json as? [[String: Any]] else {print("bad form"); return }
            
            self.processPostJson(json: json)
        }
    }
    
    var posts = [Post]()
    var pids = [Int]()
    fileprivate func processPostJson(json: [[String: Any]]) {
        print("processing Posts", json.count)
        if json.count > 0 {
            if noPostsLabel != nil {
                self.noPostsLabel.removeFromSuperview()
                self.noPostsLabel = nil
                self.inviteButton.removeFromSuperview()
                self.inviteButton = nil
                print("REMOVED IT")
            } else {
                print("NIL")
            }
            json.forEach { (snapshot) in
                var post = Post(dictionary: snapshot)
                
                if !pids.contains(post.id) {
                    pids.append(post.id)
                } else {
                    return
                }
                post.user = User(postdictionary: snapshot)
                post.setPostCache()
                
                self.posts.append(post)
                self.collectionView.reloadData()
            }
        } else if self.posts.count == 0 {
            self.showAccessoryDisplay(posts: true)
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
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
            print(canPlay, "CAN PLAY")
            if let indexPath = collectionView.indexPath(for: cell) {
                if let attributes = self.collectionView.layoutAttributesForItem(at: indexPath) {
                    if canPlay && collectionView.frame.contains(collectionView.convert(attributes.center, to: self)) {
                        if let postCell = cell as? PostCell, postCell.post?.videoUrl != nil , !(postCell.player?.isPlaying ?? false) {
                            canPlay = false
                            print("SETTING CAN PLAY TO FALSE")
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
    
    var noPostsLabel: UILabel!
    var inviteButton: UIButton!
    fileprivate func showAccessoryDisplay(posts: Bool=false) {
        guard noPostsLabel == nil else {print("ah the shit was already added"); return }
        print("SHOWING NO POSTS")
        noPostsLabel = UILabel()
        
        noPostsLabel.text = posts ? "No posts nearby." : "Enable location services to explore the world around you."
        noPostsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        noPostsLabel.textAlignment = .center
        noPostsLabel.textColor = .lightGray
        noPostsLabel.numberOfLines = 0
        
        inviteButton = UIButton(type: .system)
        inviteButton.backgroundColor = .white
        inviteButton.setTitle((posts ? "Invite Friends" : "Enable Location Services"), for: .normal)
        inviteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        inviteButton.setTitleColor((posts ? UIColor.rgb(red: 252, green: 194, blue: 0): .mainRed()), for: .normal)
        inviteButton.layer.cornerRadius = 15
        inviteButton.layer.borderWidth = 2
        inviteButton.layer.borderColor = posts ? UIColor.rgb(red: 252, green: 194, blue: 0).cgColor: UIColor.mainRed().cgColor
        posts ? inviteButton.addTarget(self, action: #selector(handleInvite), for: .touchUpInside) : inviteButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        
        
        addSubview(noPostsLabel)
        noPostsLabel.anchor(top: nil, left: leftAnchor, bottom: centerYAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        addSubview(inviteButton)
        inviteButton.anchor(top: noPostsLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: posts ? 120: 200, height: 30)
        inviteButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
    }
    
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
    
    @objc fileprivate func handleSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString)  ,UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { (success) in
                print("settings opened")
                
            }
        }
    }
    
}

extension NearbyFeedControllerCell: PostCellDelegate {
    
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

extension NearbyFeedControllerCell: CommentsLikesControllerDelegate {
 
    
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

