//
//  NearbyController.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-27.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class NearbyController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let postCellId = "nearbyCellId"
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = view.bounds
        view.insertSubview(blurView, at: 0)
        
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: postCellId)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        if MapRender.mapView.locationManager.authorizationStatus.rawValue != 2 {
            self.fetchNearbyPosts()
        } else {
            self.showAccessoryDisplay()
        }
        
        self.setupNavBar()
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func setupNavBar() {
        navigationController?.makeTransparent()
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.title = "Explore Nearby"
        
        let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleDismiss))
        navigationItem.leftBarButtonItem = dismissButton
        
        navigationController?.navigationBar.tintColor = .white
        
    }
    
    @objc fileprivate func handleDismiss() {
        self.dismiss(animated: true, completion: nil)
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
        cell.post = posts[indexPath.item]
        cell.whiteTint = true
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: (view.frame.width * (4/3)) + 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
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
        

        view.addSubview(noPostsLabel)
        noPostsLabel.anchor(top: nil, left: view.leftAnchor, bottom: view.centerYAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
  
        view.addSubview(inviteButton)
        inviteButton.anchor(top: noPostsLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: posts ? 120: 200, height: 30)
        inviteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
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
                DispatchQueue.main.async {
                    self.dismiss(animated: false, completion: nil)
                }
                
            }
        }
    }
    
}

extension NearbyController: PostCellDelegate {
    
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

extension NearbyController: CommentsLikesControllerDelegate {
    
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
