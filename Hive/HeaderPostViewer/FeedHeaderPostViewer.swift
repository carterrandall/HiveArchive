//
//  FeedHeaderPostViewer.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-21.
//  Copyright © 2018 Carter Randall. All rights reserved.


import UIKit

protocol FeedHeaderPostViewerDelegate: class {
    func scrollToUserWithUidAndUpdateHeaderCell(uidToScrollTo: Int, orderedUids: [Int], storiesDict: [Int: Story], isFinishedPaging: Bool, lastIndex: Int)
    func updateMessageCount(count: Int)
    
}

class FeedHeaderPostViewer: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    weak var delegate: FeedHeaderPostViewerDelegate?
    
    fileprivate var centerUserId: Int?
    
    var indexPath: IndexPath?
    
    var HID: Int?
    
    let postViewerCellId = "postViewerCellId"
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    lazy var pageIndicator: FeedHeaderPageIndicator = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let pi = FeedHeaderPageIndicator(frame: .zero, collectionViewLayout: layout)
        return pi
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.isScrollEnabled = false
        return cv
    }()
    
    let centerProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let centerProfileButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleProfile), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleProfile() {
        self.endPlayingVideos()
        let profileController = ProfileMainController()
        if let centerUserId = centerUserId {
            profileController.userId = centerUserId
            self.pageIndicator.isHidden = true
            let profileNavController = UINavigationController(rootViewController: profileController)
            self.present(profileNavController, animated: true, completion: nil)
        }
    }

    let leftProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let rightProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        view.addSubview(blurView)
        blurView.isUserInteractionEnabled = true
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        blurView.addGestureRecognizer(swipe)
        
        setupCollectionViews()
        displayPostsForUser()
        
        view.backgroundColor = .clear
    
    }
    fileprivate func endPlayingVideos() {
        if let visibleCell = collectionView.visibleCells.first as? PostViewerCell {
            visibleCell.player?.pause()
            visibleCell.player = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let visibleCell = collectionView.visibleCells.first as? PostViewerCell, let player = visibleCell.player, !player.isPlaying {
            visibleCell.player?.play()
        }
        
    }

    static let updateFeedHeaderNotificationName = NSNotification.Name(rawValue: "updateFeedHeaderCells")
    @objc fileprivate func handleDismiss() {
        
        NotificationCenter.default.post(name: FeedHeaderPostViewer.updateFeedHeaderNotificationName, object: nil, userInfo: storiesDict)
        
        self.dismiss(animated: true, completion: nil)
        
        self.endPlayingVideos()
        
    }
    
    fileprivate func setupCollectionViews() {
        
        view.addSubview(pageIndicator)
        pageIndicator.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 4, paddingBottom: 0, paddingRight: 4, width: view.frame.width / 3, height: 6)
        pageIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let profileDim: CGFloat = UIScreen.main.bounds.width <  375 ? 60 : 80
        centerProfileImageView.layer.cornerRadius = profileDim / 2
        view.addSubview(centerProfileImageView)
        centerProfileImageView.anchor(top: pageIndicator.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: (view.frame.height < 736 ? 8 : 20), paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: profileDim, height: profileDim)
        centerProfileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    
        view.addSubview(usernameLabel)
        usernameLabel.anchor(top: centerProfileImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(centerProfileButton) //change so it goes to either username left right or profile image depending on which is wider
        centerProfileButton.anchor(top: centerProfileImageView.topAnchor, left: centerProfileImageView.leftAnchor, bottom: centerProfileImageView.bottomAnchor, right: centerProfileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let lrDim: CGFloat = UIScreen.main.bounds.width <  375 ? 50 : 60
        leftProfileImageView.layer.cornerRadius = lrDim / 2
        rightProfileImageView.layer.cornerRadius = lrDim / 2
        view.addSubview(leftProfileImageView)
        leftProfileImageView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: -lrDim/2, paddingBottom: 0, paddingRight: 0, width: lrDim, height: lrDim)
        leftProfileImageView.centerYAnchor.constraint(equalTo: centerProfileImageView.centerYAnchor).isActive = true
        let leftUserTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLeftUserTap))
        leftProfileImageView.addGestureRecognizer(leftUserTapGestureRecognizer)
        
        view.addSubview(rightProfileImageView)
        rightProfileImageView.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: -lrDim/2, width: lrDim, height: lrDim)
        rightProfileImageView.centerYAnchor.constraint(equalTo: centerProfileImageView.centerYAnchor).isActive = true
        let rightUserTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleRightUserTap))
        rightProfileImageView.addGestureRecognizer(rightUserTapGestureRecognizer)
        
        
        let ratio = view.frame.height / view.frame.width
        if ratio > 16/9 { //iphone X and up
            let alignmentView = UIView()
            view.addSubview(alignmentView)
            alignmentView.anchor(top: usernameLabel.bottomAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            view.addSubview(collectionView)
            collectionView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: (view.frame.width * (4/3)) + 40)
            collectionView.centerYAnchor.constraint(equalTo: alignmentView.centerYAnchor).isActive = true
            
        } else {
            view.addSubview(collectionView)
            collectionView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.width * (4/3) + 40)
        }
        
        collectionView.register(PostViewerCell.self, forCellWithReuseIdentifier: postViewerCellId)

    }
    
    @objc fileprivate func handleLeftUserTap() {
        
        let visibleCells = collectionView.visibleCells
        
        if let visibleCell = visibleCells.first as? PostViewerCell {
            guard let indexPath = collectionView.indexPath(for: visibleCell) else { return }
            let postsTillPrevSection = indexPath.item
            
            if indexPath.section == 0 { //section behind does not exists
                let cellUID = visibleCell.post?.user?.uid
                arrangeMorePosts(indexShift: -1) { (didReachBegining, offSetFactor) in
                    if didReachBegining {
                        print("drb returning")
                        return
                    } else {
                        DispatchQueue.main.async {
                          
                            if let rightId = cellUID {
                                if let rightIdIndex = self.orderedUids.firstIndex(of: rightId), rightIdIndex != 0 {
                                    let centerId = self.orderedUids[rightIdIndex - 1]
                                    
                                    var leftId: Int?
                                    if rightIdIndex >= 2 {
                                        leftId = self.orderedUids[rightIdIndex - 2]
                                    }
                                    
                                    self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: true, goingForward: false)
                                    
                                } else {
                                    print("right id index was zero")
                                }
                            }
                            
                            self.observePosts(indexPath: IndexPath(item: 0, section: 0))
                            
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.collectionView.contentOffset.x = self.collectionView.contentOffset.x - (self.collectionView.frame.width * CGFloat(self.posts[indexPath.section - 1].count + postsTillPrevSection))
                    if let rightId = visibleCell.post?.user?.uid {
                        if let rightIdIndex = self.orderedUids.firstIndex(of: rightId) {
                            let centerId = self.orderedUids[rightIdIndex - 1]
                            
                            var leftId: Int?
                            if rightIdIndex >= 2 {
                                leftId = self.orderedUids[rightIdIndex - 2]
                            }
                            
                            self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: true,  goingForward: false)
                        }
                    }
                    
                    
                    self.observePosts(indexPath: IndexPath(item: 0, section: indexPath.section - 1))
                    
                }
            }
        }
    }
    
    @objc fileprivate func handleRightUserTap() {
        
        let visibleCells = collectionView.visibleCells
        
        if let visibleCell = visibleCells.first as? PostViewerCell {
            guard let indexPath = collectionView.indexPath(for: visibleCell) else { return }
            let postsTillNextSection = CGFloat(self.posts[indexPath.section].count - indexPath.item)
            if indexPath.section == posts.count - 1 { //section ahead does not exist
                arrangeMorePosts(indexShift: 1) { (didReachEnd, _) in
                    if didReachEnd {
                        
                        return
                    } else {
                        
                        DispatchQueue.main.async {
                            self.collectionView.contentOffset.x = self.collectionView.contentOffset.x + (self.collectionView.frame.width * postsTillNextSection)
                            
                            if let leftId = visibleCell.post?.user?.uid {
                                if let leftIdIndex = self.orderedUids.firstIndex(of: leftId) {
                                    let centerId = self.orderedUids[leftIdIndex + 1]
                                    var rightId: Int?
                                    if self.orderedUids.count - 1 >= leftIdIndex + 2 {
                                        rightId = self.orderedUids[leftIdIndex + 2]
                                    }
                                    self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: true,  goingForward: true)
                                }
                                
                                
                            }
                            
                            self.observePosts(indexPath: IndexPath(item: 0, section: self.posts.count - 1))
                        }
                    }
                }
            } else {
                print("section existed, offsetting")
                DispatchQueue.main.async {
                    self.collectionView.contentOffset.x = self.collectionView.contentOffset.x + (self.collectionView.frame.width * postsTillNextSection)
                    
                    if let leftId = visibleCell.post?.user?.uid {
                        if let leftIdIndex = self.orderedUids.firstIndex(of: leftId) {
                            let centerId = self.orderedUids[leftIdIndex + 1]
                            var rightId: Int?
                            if self.orderedUids.count - 1 >= leftIdIndex + 2 {
                                rightId = self.orderedUids[leftIdIndex + 2]
                            }
                            self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: true, goingForward: true)
                        }
                    }
                    
                    self.observePosts(indexPath: IndexPath(item: 0, section: indexPath.section + 1))
                    
                }
            }
        }
    }
    
    var posts = [[Post]]()
    fileprivate func displayPostsForUser() {
        guard let startingUid = startingUid else { return }
        guard let postsForUser = storiesDict[startingUid]?.posts else { return }
        
        if let user = storiesDict[startingUid]?.user {
            centerProfileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
            usernameLabel.text = user.username
            self.centerUserId = startingUid
        }
        
        let userIndex = orderedUids.firstIndex(of: startingUid)
        
        if let index = userIndex {
            if index != 0 {
                let leftUid = orderedUids[index - 1]
                if let leftUser = storiesDict[leftUid]?.user {
                    leftProfileImageView.profileImageCache(url: leftUser.profileImageUrl, userId: leftUser.uid)
                }
            }
            if index != orderedUids.count - 1 {
                let rightUid = orderedUids[index + 1]
                if let rightUser = storiesDict[rightUid]?.user {
                    rightProfileImageView.profileImageCache(url: rightUser.profileImageUrl, userId: rightUser.uid)
                }
            }
        }
        
        self.pageIndicator.numberOfItems = postsForUser.count
        posts.append(postsForUser)
        reloadCollectionView {
            DispatchQueue.main.async {
                guard var startingIndex = self.storiesDict[startingUid]?.firstUnseenPostIndex else {print("no index"); return }
                
                if let hasSeenAllPosts = self.storiesDict[startingUid]?.hasSeenAllPosts, hasSeenAllPosts {
                    self.pageIndicator.selectedPostIndex = 0
                    startingIndex = 0
                } else {
                    self.pageIndicator.selectedPostIndex = startingIndex
                }
                
                self.collectionView.scrollToItem(at: IndexPath(item: startingIndex, section: 0), at: .centeredHorizontally, animated: false)
                self.observePosts(indexPath: IndexPath(item: startingIndex, section: 0))
            }
        }
    }
    
    func reloadCollectionView(completion: @escaping() -> ()) {
        DispatchQueue.main.async {
            print("RELOADING 2")
            self.collectionView.reloadData()
            self.collectionView.performBatchUpdates(nil) { (_) in
                completion()
            }
        }
        
    }
    
    var didReachBegining: Bool = false
    var didReachEnd: Bool = false
    fileprivate func arrangeMorePosts(indexShift: Int, completion: @escaping(Bool, Int) -> () = {_,_  in }) {
        var prevId: Int?
        if indexShift > 0 {
            prevId = posts.last?.first?.user?.uid
        } else {
            prevId = posts.first?.first?.user?.uid
        }
        
        if let prevId = prevId {
            guard let prevIdIndex = orderedUids.firstIndex(of: prevId) else { return }
            if ((prevIdIndex + indexShift + 1) > orderedUids.count) && (indexShift > 0) {didReachEnd = true; completion(didReachEnd, 0); return }
            if (prevIdIndex == 0) && (indexShift < 0) { didReachBegining = true; completion(didReachBegining, 0); return }
            let id = orderedUids[prevIdIndex + indexShift]
            guard let postsToAppend = storiesDict[id]?.posts else {print("no posts to return"); return }
            
            if indexShift > 0 {
                posts.append(postsToAppend)
                if let post = postsToAppend.first {
                    cacheImage(post: post)
                }
            } else {
                posts.insert(postsToAppend, at: 0)
                if let post = postsToAppend.last {
                    cacheImage(post: post)
                }
            }
            
            DispatchQueue.main.async {
                print("RELOADING 3")
                self.collectionView.reloadData()
                self.collectionView.performBatchUpdates(nil, completion: { (_) in
                     completion(false, postsToAppend.count)
                })
            }
           
        } else {
            completion(false, 0)
            print("no id!")
        }
        
    }
    
    fileprivate func changeProfileImagesAndPageIndicator(leftId: Int?, centerId: Int, rightId: Int?, userTap: Bool, goingForward: Bool) {
        
        if let centerUser = storiesDict[centerId]?.user {
            centerProfileImageView.profileImageCache(url: centerUser.profileImageUrl, userId: centerUser.uid)
            usernameLabel.text = centerUser.username
            self.centerUserId = centerId
            if let numberOfPosts = storiesDict[centerId]?.posts.count {
                self.pageIndicator.numberOfItems = numberOfPosts
                if goingForward || userTap {
                    self.pageIndicator.selectedPostIndex = 0
                } else {
                    self.pageIndicator.selectedPostIndex = numberOfPosts - 1
                }
            }
        }
        
        if let lid = leftId {
            if let leftUser = storiesDict[lid]?.user {
                leftProfileImageView.profileImageCache(url: leftUser.profileImageUrl, userId: leftUser.uid)
            }
        } else {
            leftProfileImageView.image = nil
        }
        
        if let rid = rightId {
            if let rightUser = storiesDict[rid]?.user {
                rightProfileImageView.profileImageCache(url: rightUser.profileImageUrl, userId: rightUser.uid)
            }
        } else {
            rightProfileImageView.image = nil
            
            if goingForward && !isFinishedPaging {
                self.paginateHeader()
            } else {
                print("finished paging or going back")
            }
        }
    }
    
    var orderedUids = [Int]() 
    var storiesDict = [Int: Story]()
    var startingUid: Int?
    var isFinishedPaging: Bool = false
    var lastIndex: Int = 0
    fileprivate var pids = [Int]()
    fileprivate func paginateHeader() {
        print("paginating header here")
        self.lastIndex += 1
        var params = ["lastIndex": self.lastIndex] as [String: Any]
        if let hid = self.HID { params["HID"] = hid }
        RequestManager().makeJsonRequest(urlString: "/Hive/api/paginateHeader", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let messageCount = json["Messages"] as? Int, messageCount > 0  {
                self.delegate?.updateMessageCount(count: messageCount)
            } else {
                print("UPDATING MESSAGE COUNT TO 0 from paginateheader")
                self.delegate?.updateMessageCount(count: 0)
            }
            
            if let postJson = json["Header"] as? [[String: Any]], let count = json["HeaderCount"] as? Int {
                let hjson = ["json": postJson, "count": count] as [String: Any]
                self.processHeaderJson(headerJson: hjson)
            }
        }
    }
    
    fileprivate func processHeaderJson(headerJson: [String: Any]) {
        
        if let count = headerJson["count"] as? Int {
            print("HEADER COUNT", count)
            isFinishedPaging = (count < 10 ? true : false)
        } else {
            print("NO COUNT")
        }
        
        if let json = headerJson["json"] as? [[String: Any]] {
            if json.count > 0 {
                json.forEach({ (snapshot) in
                   
                    var post = Post(dictionary: snapshot)
                    
                    if !pids.contains(post.id) {
                        pids.append(post.id)
                    } else {
                        print("returning")
                        return
                    }
                    
                    let user = User(postdictionary: snapshot)
                    print(user.username, "username here")
                    post.user = user
                    
                    if let seen = snapshot["seen"] as? Bool, seen {
                        post.seen = true
                    } else {
                        post.seen = false
                    }
                    post.setPostCache()
                    if self.storiesDict[user.uid] == nil {
                        self.orderedUids.append(user.uid)
                        var story = Story(user: user, posts: [post])
                        
                        if let seen = post.seen, !seen {
                            
                            story.firstUnseenPostIndex = 0
                            story.hasSeenAllPosts = false
                        }
                        
                        self.storiesDict[user.uid] = story
                        
                    } else {
                        
                        self.storiesDict[user.uid]?.posts.append(post)
                        
                        self.storiesDict[user.uid]?.posts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                        })
                        
                        if let seen = post.seen, !seen {
                            if self.storiesDict[user.uid]?.firstUnseenPostIndex == nil {
                                let story = self.storiesDict[user.uid]
                                
                                self.storiesDict[user.uid]?.firstUnseenPostIndex = (story?.posts.count ?? 1) - 1
                                self.storiesDict[user.uid]?.hasSeenAllPosts = false
                            }
                            
                        }
                    }
                    
                })
                print("RELOADING 1")
                self.collectionView.reloadData()
                self.updateRightProfileAfterPaginate()
                
            } else {
                print("no posts in header json paginate")
            }
        } else {
            print("NO HEADER JSON", headerJson)
        }
        
    }
    
    fileprivate func updateRightProfileAfterPaginate() {
        guard let centerUserId = self.centerUserId else { return }
        if let centerIndex = self.orderedUids.firstIndex(of: centerUserId) {
            if let rightUser = self.storiesDict[self.orderedUids[centerIndex + 1]]?.user {
                self.rightProfileImageView.profileImageCache(url: rightUser.profileImageUrl, userId: rightUser.uid)
            }
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return posts.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postViewerCellId, for: indexPath) as! PostViewerCell
        
        cell.post = posts[indexPath.section][indexPath.item]
        cell.delegate = self
        
        self.cacheImagesWithinSection(indexPath: indexPath)
        
        return cell
        
    }
    
    fileprivate func cacheImagesWithinSection(indexPath: IndexPath) {
        if !(indexPath.item + 1 >= self.posts[indexPath.section].count) {
            cacheImage(post: posts[indexPath.section][indexPath.item + 1])
        } else if !(indexPath.section + 1 >= self.posts.count), let post = posts[indexPath.section + 1].first {
            cacheImage(post: post)
        }

        if indexPath.item != 0 {
            cacheImage(post: posts[indexPath.section][indexPath.item - 1])
        } else if indexPath.section != 0, let post = posts[indexPath.section - 1].last { //if not first section
            cacheImage(post: post)
        }
    }
    
    let dummyImageView = CustomImageView()
    fileprivate func cacheImage(post: Post) {
        DispatchQueue.main.async {
            
            self.dummyImageView.postImageCache(url: post.imageUrl, postId: post.id)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.width * (4/3) + 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let postCell = cell as? PostViewerCell {
            postCell.player?.pause()
            postCell.player = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let postCell = cell as? PostViewerCell {
            postCell.handlePlay()
        }
    }

}

extension FeedHeaderPostViewer: PostViewerCellDelegate, CommentsLikesControllerDelegate {
    
    func leftTap(cell: PostViewerCell) {
        
        let contentOffSetX = collectionView.contentOffset.x
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        if indexPath.item == 0 { //first post in section moving to new one
            if self.posts.first?.first?.id == cell.post?.id { //no section exists before this one
                if didReachBegining {
                    
                    self.handleDismiss()
                    return
                    
                } else {
                    let cellUID = cell.post?.user?.uid
                    arrangeMorePosts(indexShift: -1) { (didReachBegining, offSetFactor) in
                       
                        if didReachBegining {
                            self.handleDismiss()
                            return
                        } else {
                            self.didReachBegining = false
                            DispatchQueue.main.async {
                                self.collectionView.contentOffset.x = contentOffSetX + (CGFloat(offSetFactor - 1) * self.view.frame.width)
                            }
                            
                            if let prevId = cellUID {
                            
                                if let prevIdIndex = self.orderedUids.firstIndex(of: prevId), prevIdIndex != 0 {
                                    let rightId = prevId
                                    let centerId = self.orderedUids[prevIdIndex - 1]
                                    var leftId: Int?
                                    if prevIdIndex >= 2 {
                                        leftId = self.orderedUids[prevIdIndex - 2]
                                    }
                                    
                                    self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: false, goingForward: false)
                                } else {
                                    print("Prev Id index was 0")
                                }
                            }
                            
                        }
                        
                        self.observePosts(indexPath: IndexPath(item: self.posts[indexPath.section].count - 1, section: indexPath.section))

                    }
                }
            } else {
                self.didReachBegining = false
                DispatchQueue.main.async {
                    self.collectionView.contentOffset.x = contentOffSetX + (CGFloat(-1) * self.view.frame.width)
                }
                
                if let prevId = cell.post?.user?.uid {
                    if let prevIdIndex = self.orderedUids.firstIndex(of: prevId) {
                        let rightId = prevId
                        let centerId = self.orderedUids[prevIdIndex - 1]
                        var leftId: Int?
                        if prevIdIndex >= 2 {
                            leftId = self.orderedUids[prevIdIndex - 2]
                        }
                        self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: false, goingForward: false)
                    }
                }
                
                observePosts(indexPath: IndexPath(item: posts[indexPath.section].count - 1, section: indexPath.section))

            }
            
            
        } else {
            self.pageIndicator.selectedPostIndex = indexPath.item - 1
            collectionView.contentOffset.x = contentOffSetX - view.frame.width
            
            observePosts(indexPath: IndexPath(item: indexPath.item - 1, section: indexPath.section))
        }
    }

    func rightTap(cell: PostViewerCell) {
        
        let contentOffSetX = collectionView.contentOffset.x

        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        if (indexPath.item == self.posts[indexPath.section].count - 1) { //last post in a section, moving to new section
            
            if self.posts.count - 1 == indexPath.section { //section doesint exist yet
                arrangeMorePosts(indexShift: 1) { (didReachEnd,_) in
                    if didReachEnd {
                        self.handleDismiss()
                        return
                    } else {
                        
                        self.didReachEnd = false
                        DispatchQueue.main.async {
                            self.collectionView.contentOffset.x = contentOffSetX + self.view.frame.width
                        }
                        
                        if let prevId = cell.post?.user?.uid {
                            if let prevIdIndex = self.orderedUids.firstIndex(of: prevId) {
                                let leftId = prevId
                                let centerId = self.orderedUids[prevIdIndex + 1]
                                var rightId: Int?
                                if self.orderedUids.count - 1 >= prevIdIndex + 2{
                                    rightId = self.orderedUids[prevIdIndex + 2]
                                }
            
                                self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: false, goingForward: true)
                            }
                        }
                        
                        self.observePosts(indexPath: IndexPath(item: 0, section: indexPath.section + 1))

                    }
                }
            } else {
                
                self.didReachEnd = false
                DispatchQueue.main.async {
                    self.collectionView.contentOffset.x = contentOffSetX + self.view.frame.width
                }
                
                if let prevId = cell.post?.user?.uid {
                    if let prevIdIndex = self.orderedUids.firstIndex(of: prevId) {
                        let leftId = prevId
                        let centerId = self.orderedUids[prevIdIndex + 1]
                        var rightId: Int?
                        if self.orderedUids.count - 1 >= prevIdIndex + 2{
                            rightId = self.orderedUids[prevIdIndex + 2]
                        }
                        
                        self.changeProfileImagesAndPageIndicator(leftId: leftId, centerId: centerId, rightId: rightId, userTap: false, goingForward: true)
                    }
                }
                
                observePosts(indexPath: IndexPath(item: 0, section: indexPath.section + 1))
                
            }
            
        }
        else {
            self.pageIndicator.selectedPostIndex = indexPath.item + 1
            collectionView.contentOffset.x = contentOffSetX + view.frame.width
            
            observePosts(indexPath: IndexPath(item: indexPath.item + 1, section: indexPath.section))
        }

       
    }
    
    
    
    fileprivate func observePosts(indexPath: IndexPath) {
        if indexPath.section <= posts.count - 1 {
            if indexPath.item <= posts[indexPath.section].count - 1 {
                var post = self.posts[indexPath.section][indexPath.item]
                if let seen = post.seen, !seen {
                    let params = ["PID": post.id]
                    RequestManager().makeResponseRequest(urlString: "/Hive/api/observeHeaderPost", params: params) { (response) in
                        if response.response?.statusCode == 200 {
                            print("observed header post")
                        } else {
                            print("failed to observe header post")
                        }
                    }
        
                    post.seen = true
                    self.posts[indexPath.section][indexPath.item] = post
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadItems(at: [indexPath])
                    }
                    
                    if let user = post.user {
                        if post.id == storiesDict[user.uid]?.posts.last?.id {//mark for borders
                            storiesDict[user.uid]?.hasSeenAllPosts = true
                            let storyDictCount = storiesDict[user.uid]?.posts.count
                            storiesDict[user.uid]?.firstUnseenPostIndex = (storyDictCount ?? 1) - 1
                        } else {//update firstUnseen post index
                            let index = storiesDict[user.uid]?.posts.firstIndex(where: { (p) -> Bool in
                                return p.id == post.id
                            })
                            
                            if let i = index {
                                storiesDict[user.uid]?.firstUnseenPostIndex = i + 1
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func swipeDown() {
        DispatchQueue.main.async {
            if let visibleCell = self.collectionView.visibleCells.first as? PostViewerCell {
                if visibleCell.post?.videoUrl != nil {
                    visibleCell.player?.pause()
                    visibleCell.player = nil
                }
                
                if let uid = visibleCell.post?.user?.uid {
                    self.delegate?.scrollToUserWithUidAndUpdateHeaderCell(uidToScrollTo: uid, orderedUids: self.orderedUids, storiesDict: self.storiesDict, isFinishedPaging: self.isFinishedPaging, lastIndex: self.lastIndex)
                }
            }
            self.handleDismiss()
        }
        
    }
    
    
    
    
    
    func didTapLike(for cell: PostViewerCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard var post = cell.post else { return }
        let hasLiked = post.hasLiked
        post.hasLiked = !hasLiked
        post.setPostCache()
        DispatchQueue.main.async {
            self.posts[indexPath.section][indexPath.item] = post
            
            if !hasLiked {
                cell.animateLike()
            }
            
            cell.post?.changeLikeOnPost(completion: { (_) in
                cell.post?.hasLiked = !hasLiked
            })
        }
       
    }
    
    func didTapComments(cell: PostViewerCell) {
        self.endPlayingVideos()
        guard let post = cell.post else { return }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let commentsLikesController = CommentsLikesController(collectionViewLayout: layout)
        commentsLikesController.post = post
        commentsLikesController.delegate = self
        commentsLikesController.index = 0
        self.pageIndicator.isHidden = true
        let commentsLikesNavController = UINavigationController(rootViewController: commentsLikesController)
        commentsLikesNavController.modalPresentationStyle = .overFullScreen
        present(commentsLikesNavController, animated: true, completion: nil)
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        self.indexPath = indexPath
        
    }
    
    func didCommentOrDelete(index: Int, increment: Int) {
        guard let indexPath = self.indexPath else { return }
        var post = posts[indexPath.section][indexPath.item]
        if let comments = post.comments {
            post.comments = comments + increment
            self.posts[indexPath.section][indexPath.item] = post
            DispatchQueue.main.async {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    func didTapShare(post: Post) {
        let sharePostController = SharePostController()
        sharePostController.post = post
        self.pageIndicator.isHidden = true
        let sharePostNavController = UINavigationController(rootViewController: sharePostController)
        sharePostNavController.modalPresentationStyle = .overFullScreen
        self.present(sharePostNavController, animated: true, completion: nil)
        self.endPlayingVideos()
    }
    
}

