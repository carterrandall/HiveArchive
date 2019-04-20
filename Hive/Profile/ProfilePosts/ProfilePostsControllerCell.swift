//
//  ProfilePostsControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-23.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ProfilePostsControllerCellDelegate: class {
    func presentAlertController(alert: UIAlertController)
    func presentPostViewer(postViewer: FeedPostViewerController)
    func updatePostCount(postCount: Int)
    func decrementPostCount()
    func updateFriendCountFromReload(friendCount: Int)
}

class ProfilePostsControllerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: ProfilePostsControllerCellDelegate?
    
    fileprivate let profilePhotoCellId = "profilePhotoCellId"
    fileprivate let editProfilePhotoCellId = "editProfilePhotoCellId"
    
    var user: User?
    var updatePosts: Bool? {
        didSet {
            if let updatePosts = updatePosts, updatePosts {
                DispatchQueue.main.async {
                    self.collectionView.performBatchUpdates(nil, completion: { (_) in
                        self.reloadPosts()
                    })
                }
            }
        }
    }
    
    var profileState = ProfileState.normal {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var postJson: [String: Any]? {
        didSet {
            if self.posts.count > 0 { return }
            if let json = postJson {
                if let postJson = json["Posts"] as? [[String: Any]], postJson.count > 0 {
                    processPostJson(json: postJson, new: false)
                }
                if let count = json["paginatePostCount"] as? Int {
                    self.isFinishedPaging = (count < 10 ? true : false)
                }
            }
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .white
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        collectionView.register(ProfilePhotoCell.self, forCellWithReuseIdentifier: profilePhotoCellId)
        collectionView.register(EditProfilePhotoCell.self, forCellWithReuseIdentifier: editProfilePhotoCellId)
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadPosts() { //ONLY USED ON OWN PROFILE TO UPDATE CACHED OBJECT
        print("reloading")
        let newestPost = self.posts.first?.creationDate.timeIntervalSince1970 ?? 0
        let params = ["newestPost": newestPost]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/reloadProfile", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            
            if let postJson = json["Posts"] as? [[String: Any]] {
                print(postJson, "POST JSON")
                self.processPostJson(json: postJson, new: true)
            } else {
                print("NO POST JSON :'(")
            }
            
            if let friendCount = json["FriendCount"] as? Int {
                self.delegate?.updateFriendCountFromReload(friendCount: friendCount)
            }
            
            if let postCount = json["PostCount"] as? Int {
                self.delegate?.updatePostCount(postCount: postCount)
            }
            
        }
    }
    
    fileprivate func paginatePosts() {
        print("PAGINATING POSTS ON PROFILE")
        guard let uid = self.user?.uid else {print("no uid"); return }
        let params = ["UID": uid, "lastPost": self.posts.last?.creationDate.timeIntervalSince1970 ?? 0] as [String: Any]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginatePostsOnProfile", params: params) { (json, sc) in
            guard let json = json as? [String: Any] else { return }
            if let posts = json["Posts"] as? [[String: Any]] {
                self.processPostJson(json: posts, new: false)
                print(posts.count,  "JSON COUNT")
            }
            if let count = json["paginatePostCount"] as? Int {
                print(count, "PAGINATE POST COUNT")
                self.isFinishedPaging = (count < 10 ? true : false)
            } else {
                print("NO PAGINATE COUNT")
            }
        }
    }
    
    fileprivate var isFinishedPaging: Bool = false
    fileprivate var posts = [Post]()
    fileprivate var pids = [Int]()
    fileprivate func processPostJson(json: [[String: Any]], new: Bool) {
        if json.count > 0 {
            json.forEach({ (snapshot) in
                
                var post = Post(dictionary: snapshot)
                if !(self.pids.contains(post.id)) {
                    self.pids.append(post.id)
                } else {
                    return
                }
                
                post.user = user
                post.setPostCache()
                if new {
                    self.posts.insert(post, at: 0)
                } else {
                    self.posts.append(post)
                }
            })
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            self.isFinishedPaging = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if profileState != .editing {
            let layout = UICollectionViewFlowLayout()
            let postViewer = FeedPostViewerController(collectionViewLayout: layout)
            postViewer.posts = self.posts
            postViewer.isFinishedPaging = self.isFinishedPaging
        
            if let user = self.user {
                postViewer.user = user
            }
            postViewer.navigationItem.title = "\(user?.username ?? "Posts")"
            postViewer.selectedIndexPath = indexPath
            postViewer.delegate = self
            delegate?.presentPostViewer(postViewer: postViewer)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == posts.count - 1 && !isFinishedPaging {
            self.paginatePosts()
        }
        
        let post = posts[indexPath.item]
        
        if profileState == .normal {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profilePhotoCellId, for: indexPath) as! ProfilePhotoCell
            cell.post = post
            cell.isPinned = post.isPinned //set seperatley for good reason...
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: editProfilePhotoCellId, for: indexPath) as! EditProfilePhotoCell
            cell.delegate = self
            cell.post = post
            return cell
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    
    let width = ((UIScreen.main.bounds.width - 1) / 2)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        print(UIScreen.main.bounds.height / UIScreen.main.bounds.width)
        return CGSize(width: width, height: width * (4/3))
    }
    
}

extension ProfilePostsControllerCell : EditProfilePhotoCellDelegate {
    
    func didTapPinPost(cell: EditProfilePhotoCell) {
        
        guard var post = cell.post else { return }

        let isPinned = !post.isPinned

        let pinInt = isPinned ? 1 : 0
        let params = ["PID": post.id, "isPinned": pinInt]
        
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/pinPost", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("successfully pinned post")
            } else {
                print("failed to pin post:", response)
            }
        }
        
        post.isPinned = isPinned
        
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        self.posts[indexPath.item] = post
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    static let updateForDeletedPostNotificationName = NSNotification.Name("updateForDeletedPost")
    func didTapDeletePost(cell: EditProfilePhotoCell) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            
            guard let postId = cell.post?.id else { return }
            self.deletePostWithId(id: postId)
            self.delegate?.decrementPostCount()
            DispatchQueue.main.async {
                guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
                self.posts.remove(at: indexPath.item)
                self.collectionView.deleteItems(at: [indexPath])
            }
            
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        delegate?.presentAlertController(alert: alertController)
        
    }
    
    func deletePostWithId(id: Int) {
        let params = ["PID": id]
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/deleteOwnPost", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("succesfully deleted post with id:", id)
            } else {
                print("Failed to delete post", response)
            }
        }
    }
}


extension ProfilePostsControllerCell: FeedPostViewerControllerDelegate {
    func viewerWillDismiss(indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
    }
    
    func didPageForMorePosts(posts: [Post?], isFinishedPaging: Bool) {
        self.isFinishedPaging = isFinishedPaging
        self.posts = posts as! [Post]
        collectionView.reloadData()
    }
    
    func didLikePost(index: Int, post: Post) {
        self.posts[index] = post
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        
    }
    
}

