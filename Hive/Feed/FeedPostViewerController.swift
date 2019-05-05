import UIKit

protocol FeedPostViewerControllerDelegate: class {
    func didLikePost(index: Int, post: Post)
    func viewerWillDismiss(indexPath: IndexPath)
    func didPageForMorePosts(posts: [Post?], isFinishedPaging: Bool)
    func sendBackPost(post: Post)
    func updateMessages(message: Bool)
}

extension FeedPostViewerControllerDelegate {
    func didLikePost(index: Int, post: Post) {}
    func viewerWillDismiss(indexPath: IndexPath) {}
    func didPageForMorePosts(posts: [Post?], isFinishedPaging: Bool) {}
    func sendBackPost(post: Post) {}
    func updateMessages(message: Bool) {}
}

class FeedPostViewerController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    weak var delegate: FeedPostViewerControllerDelegate?
    
    fileprivate let feedCellId = "feedCellId"
    fileprivate var didPageForMorePosts: Bool = false
    fileprivate var isNewPostsUp = true
    var isFromChat: Bool = false
    
    var user: User?
    var isFromNotifications: Bool = false
    
    var isFirstLayout: Bool = true
    var selectedIndexPath: IndexPath? {
        didSet {
            if isFirstLayout {
                guard let indexPath = selectedIndexPath else { return }
                DispatchQueue.main.async {
                    self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: false)
                }
                isFirstLayout = false
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        navigationController?.navigationBar.tintColor = .black
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
        
        if isFromNotifications {
            fetchPostDetails()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkToPlayVideo()
    }
    
    fileprivate func fetchPostDetails() {
        print("Fetching details")
        guard let id = posts.first?.id else { return }
        let params = ["PID": id]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/loadPostForNotificationViewer", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            var post = Post(dictionary: json)
            print(json,"JSON")
            let user = User(postdictionary: json)
            post.user = user
            print(json, "POST")
            if let expired = json["isExpired"] as? Bool, expired {
                post.expired = true
            }
            self.posts.removeAll()
            self.posts.append(post)
            self.collectionView.reloadData()
        }
    }
    
    fileprivate func setupCollectionView() {
        collectionView?.backgroundColor = .white
        collectionView?.register(PostCell.self, forCellWithReuseIdentifier: feedCellId)
        collectionView?.showsVerticalScrollIndicator = false
        
        if let barHeight = navigationController?.navigationBar.frame.height, isFromNotifications || isFromChat  {
            let h = view.frame.height - barHeight - UIApplication.shared.statusBarFrame.height
            let w = (view.frame.width * (4/3) + 54)
            collectionView.contentInset.top = (h - w) / 4
        }
        else {
            collectionView.contentInset.top = 8
        }
    }

    
    @objc fileprivate func handleBack() {
        self.endPlayingVideos()
        if isFromNotifications, let post = self.posts.first {
            delegate?.sendBackPost(post: post)
        } else {
            if didPageForMorePosts {
                delegate?.didPageForMorePosts(posts: self.posts, isFinishedPaging: self.isFinishedPaging)
            }
            guard let indexPath = collectionView.indexPathsForVisibleItems.first else { return }
            delegate?.viewerWillDismiss(indexPath: indexPath)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        whiteView = UIView()
        whiteView.backgroundColor = .white
        view.addSubview(whiteView)
        whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        endPlayingVideos()
    }
    
    
    var isFinishedPaging: Bool = false
    var posts = [Post]()
    fileprivate func paginateUserPosts() {
        
        if !self.didPageForMorePosts {
            self.didPageForMorePosts = true
        }
        
        guard let user = self.user else { return }
        let lastPost = self.posts.last?.creationDate.timeIntervalSince1970 ?? 0
        let params = ["UID": user.uid, "lastPost": lastPost] as [String: Any]
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginatePostsOnProfile", params: params) { (json, _) in
            
            guard let json = json as? [String: Any] else { return }
            if let postJson = json["Posts"] as? [[String: Any]] {
                if postJson.count > 0 {
                    
                    postJson.forEach({ (snapshot) in
                        var post = Post(dictionary: snapshot)
                        post.user = user
                        self.posts.append(post)
                    })
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
            if let count = json["paginatePostCount"] as? Int {
                print(count, "PAGINATE POST COUNT")
                self.isFinishedPaging = (count < 10 ? true : false)
            } else {
                print("NO PAGINATE COUNT")
            }
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: feedCellId, for: indexPath) as! PostCell
        if indexPath.item == posts.count - 1 && !isFinishedPaging && !isFromNotifications && !isFromChat {
            self.paginateUserPosts()
        }
        
        cell.post = posts[indexPath.item]
        cell.delegate = self
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: (collectionView.frame.width * (4/3)) + 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let postCell = cell as? PostCell {
            postCell.player?.pause()
            postCell.player = nil
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            self.checkToPlayVideo()
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
                    if canPlay && collectionView.frame.contains(collectionView.convert(attributes.center, to: self.view)) {
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
        print("ENDING THAT SHIZZLE")
        let visibleCells = collectionView.visibleCells
        for visibleCell in visibleCells {
            if let cell = visibleCell as? PostCell {
                print("PAUSED")
                cell.player?.pause()
                cell.player = nil
            }
        }
    }
    
}

extension FeedPostViewerController: PostCellDelegate, CommentsLikesControllerDelegate {
    
    func didTapProfile(user: User) {
        self.endPlayingVideos()
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        let profileNavController = UINavigationController(rootViewController: profileController)
        self.present(profileNavController, animated: true, completion: nil)
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
            
            
            cell.post?.changeLikeOnPost { (_) in
                cell.post?.hasLiked = !hasLiked
                
            }
        }
    }
    
    func didTapShare(post: Post) {
        self.endPlayingVideos()
        let sharePostController = SharePostController()
        sharePostController.post = post
        let sharePostNavController = UINavigationController(rootViewController: sharePostController)
        sharePostNavController.modalPresentationStyle = .overFullScreen
        self.present(sharePostNavController, animated: true, completion: nil)
    }
    
    func didTapComments(cell: PostCell) {
        self.endPlayingVideos()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let commentsLikesController = CommentsLikesController(collectionViewLayout: layout)
        commentsLikesController.post = cell.post
        commentsLikesController.delegate = self
        commentsLikesController.index = Int(collectionView.contentOffset.x / view.frame.width)
        let commentsLikesNavController = UINavigationController(rootViewController: commentsLikesController)
        commentsLikesNavController.modalPresentationStyle = .overFullScreen
        present(commentsLikesNavController, animated: true, completion: nil)
    }
    
    func didCommentOrDelete(index: Int, increment: Int) {
        var post = posts[index]
        if let comments = post.comments {
            print(comments)
            post.comments = comments + increment
            self.posts[index] = post
            DispatchQueue.main.async {
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
    
}
