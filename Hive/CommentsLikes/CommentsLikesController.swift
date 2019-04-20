//
//  CommentsLikesController.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol CommentsLikesControllerDelegate: class {
    func didCommentOrDelete(index: Int, increment: Int)
}

class CommentsLikesController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: CommentsLikesControllerDelegate?
    var index: Int?
    var totalCommentIncrement = 0
    
    fileprivate let commentsControllerCellId = "commentsControllerCellId"
    fileprivate let likesControllerCellId = "likesControllerCellId"
    
    var post: Post? {
        didSet {
            guard let post = post else { return }
            
            if let postUid = post.user?.uid, let currentUid = MainTabBarController.currentUser?.uid {
                if postUid == currentUid {
                    showLikes = true
                } else {
                    showLikes = false
                }
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.menuBar.commentCount = post.comments
            }
        }
    }
    
    var showLikes: Bool = false {
        didSet {
            self.menuBar.showLikes = showLikes
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    
    lazy var menuBar: CommentsLikesMenuBar = {
        let mb = CommentsLikesMenuBar()
        mb.commentsLikesController = self
        return mb
    }()
    
    lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .black
        button.setImage(UIImage(named: "cancel"), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDismiss() {
        if let parent = self.navigationController?.presentingViewController as? FeedHeaderPostViewer {
            parent.pageIndicator.isHidden = false
        }
        if let index = self.index {
            print(self.totalCommentIncrement, "TOTATL INCREMENT")
            delegate?.didCommentOrDelete(index: index, increment: self.totalCommentIncrement)
        }
        if var post = self.post, let commentCount = post.comments {
            post.comments = commentCount + totalCommentIncrement
            post.setPostCache()
        }
        
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        MainTabBarController.requestManager.delegate = self
        setupNavBar()
        setupCollectionView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuBar.isHidden = false
        dismissButton.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuBar.isHidden = true
        dismissButton.isHidden = true
    }
    
    fileprivate func setupNavBar() {
        navigationController?.makeTransparent()
        
        guard let navBar = navigationController?.navigationBar else { return }
        
        navBar.addSubview(menuBar)
        menuBar.anchor(top: navBar.topAnchor, left: navBar.leftAnchor, bottom: navBar.bottomAnchor, right: navBar.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        navBar.addSubview(dismissButton)
        dismissButton.anchor(top: nil, left: navBar.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        dismissButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor).isActive = true
    }
    
    fileprivate func setupCollectionView() {
        
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        collectionView.register(CommentsControllerCell.self, forCellWithReuseIdentifier: commentsControllerCellId)
        collectionView.register(LikesControllerCell.self, forCellWithReuseIdentifier: likesControllerCellId)
    }
    
    fileprivate var isFirstLoad: Bool = true
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if isFirstLoad {
            if showLikes {
                scrollToMenuIndex(menuIndex: 1, animated: false)
                menuBar.collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            } else {
                menuBar.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            }
            isFirstLoad = false
        }
    }
    
    func scrollToMenuIndex(menuIndex: Int, animated: Bool) {
        let indexPath = IndexPath(item: menuIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        menuBar.horizontalBarLeftConstraint?.constant = scrollView.contentOffset.x / 2
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let item = targetContentOffset.pointee.x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuBar.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showLikes ? 2 : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if showLikes {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: likesControllerCellId, for: indexPath) as! LikesControllerCell
                if let post = self.post {
                    
                    cell.post = post
                }
                cell.delegate = self
                
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: commentsControllerCellId, for: indexPath) as! CommentsControllerCell
                if let post = self.post {
                    cell.post = post
                }
                cell.delegate = self
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: commentsControllerCellId, for: indexPath) as! CommentsControllerCell
            if let post = self.post {
                cell.post = post
            }
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        print(collectionView.frame.height, "CV HEIGHT", view.frame.height, "V HEIGHT")
        return CGSize(width: view.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}

extension CommentsLikesController: LikesControllerCellDelegate, CommentsControllerCellDelegate {
  
    func showProfile(profileController: ProfileMainController) {
        navigationController?.pushViewController(profileController, animated: true)
    }
    
    func didCommentOrDelete(increment: Int) {
        
        self.totalCommentIncrement += increment
        if let commentCount = self.menuBar.commentCount {
            DispatchQueue.main.async {
                self.menuBar.commentCount = commentCount + increment
                if self.showLikes {
                    self.menuBar.collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                } else {
                    self.menuBar.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                }
            }
        }
        
    }
    
    func presentAlertController(alertController: UIAlertController) {
        present(alertController, animated: true, completion: nil)
    }
    
}

extension CommentsLikesController: RequestManagerDelegate {
    func reconnectedToInternet() {
        print("recconected comments likes")
        DispatchQueue.main.async {
            let visibleCell = self.collectionView.visibleCells.first
            if let vc = visibleCell as? LikesControllerCell {
                vc.lastIndexLikes = 0
                vc.likedUsers.removeAll()
                vc.isFinishedPagingLikes = false
                vc.paginateLikes()
            } else if let vc = visibleCell as? CommentsControllerCell {
                print("tis comments")
                vc.comments.removeAll()
                vc.isFinishedPagingComments = false
                vc.lastIndexComments = 0
                vc.paginateComments()
            }
        }
        
    }
}
