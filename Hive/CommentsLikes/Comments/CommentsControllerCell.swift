//
//  CommentsControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
 
protocol CommentsControllerCellDelegate: class {
    func showProfile(profileController: ProfileMainController)
    func didCommentOrDelete(increment: Int)
    func presentAlertController(alertController: UIAlertController)
}

class CommentsControllerCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: CommentsControllerCellDelegate?
    
    let commentCellId = "commentsCellId"
    internal let flipTransform = CGAffineTransform(scaleX: 1, y: -1)
    fileprivate var additionalTextViewHeight: CGFloat = 0.0
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.dataSource = self
        tv.delegate = self
        tv.backgroundColor = .white
        tv.keyboardDismissMode = .interactive
        tv.showsVerticalScrollIndicator = false
        tv.transform = flipTransform
        return tv
    }()
    
    var post: Post? {
        didSet {
            guard post != nil else { return }
            DispatchQueue.main.async {
                self.paginateComments()
                
                if self.post?.expired != nil {
                    self.containerView.isHidden = true
                }
            }
        }
    }
    
    
    lazy var containerView: InputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 50)
        let inputAccessoryView = InputAccessoryView(frame: frame)
        inputAccessoryView.placeHolderText = "Comment"
        inputAccessoryView.delegate = self
        return inputAccessoryView
    }()
    
    override var canBecomeFirstResponder: Bool { return true }

    fileprivate var uid: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        
        setupTableView()
        setCurrentUserId()
        registerForKeyboardNotifications()
        
    }
    
    var containerViewBottomConstraint: NSLayoutConstraint!
    var containerViewHeightContraint: NSLayoutConstraint!
    var tableViewHeightConstraint: NSLayoutConstraint!
    fileprivate func setupTableView() {
        
        tableView.register(CommentCell.self, forCellReuseIdentifier: commentCellId)
        addSubview(tableView)
        tableView.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 1000)
        tableViewHeightConstraint.isActive = true
        
        addSubview(containerView)
        containerView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0)
        containerViewBottomConstraint.isActive = true
        
        containerViewHeightContraint = containerView.heightAnchor.constraint(equalToConstant: 50)
        containerViewHeightContraint.isActive = true
    
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipe:)))
        downSwipe.direction = .down
        containerView.addGestureRecognizer(downSwipe)
        
    }
    
    @objc fileprivate func handleSwipe(swipe: UISwipeGestureRecognizer) {
        self.containerView.textView.resignFirstResponder()
    }
    
    fileprivate func setCurrentUserId() {
        guard let uid = MainTabBarController.currentUser?.uid else { return }
        self.uid = uid
    }
    
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var keyboardHeight: CGFloat = 0.0
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]) as? Double, let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]) as? UInt {
            self.keyboardHeight = keyboardFrame.height
            self.containerView.layoutIfNeeded()
            print(keyboardHeight, "KEYBOARD HEIGHT")
//            if keyboardHeight < 60 {
//                return
//            }
            DispatchQueue.main.async {
                self.containerViewBottomConstraint.constant = -keyboardFrame.height
                
                UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
                    self.layoutIfNeeded()
                }, completion: { (_) in
                    
                })
                
            }
            
            let firstCellRect = tableView.rectForRow(at: IndexPath(item: 0, section: 0))
            
            if firstCellRect == .zero { return }
            
            let flippedConvertedCellRect = tableView.convert(firstCellRect.applying(flipTransform), to: self)
            let y = (flippedConvertedCellRect.origin.y - flippedConvertedCellRect.height)
            let lastCellRect = CGRect(x: flippedConvertedCellRect.origin.x, y: (y < 0 ? 0 : y), width: flippedConvertedCellRect.width, height: flippedConvertedCellRect.height)
            
            var visibleRect = self.bounds
            
            visibleRect.size.height -= (keyboardFrame.height + self.containerViewHeightContraint.constant)
            
            if !visibleRect.contains(lastCellRect) {
         
                DispatchQueue.main.async {
                    self.tableView.contentInset.top = keyboardFrame.height + self.containerViewHeightContraint.constant - (self.frame.height - self.tableViewHeightConstraint.constant) + self.safeAreaInsets.top
                    let portionFistCellRect = CGRect(x: firstCellRect.origin.x, y: firstCellRect.origin.y, width: 50, height: 50)
                    self.tableView.scrollRectToVisible(portionFistCellRect, animated: true)
                }
            }
            
        }
        
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        
        
        if let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]) as? Double, let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]) as? UInt {
            
            self.containerView.layoutIfNeeded()
            DispatchQueue.main.async {
                self.containerViewBottomConstraint.constant = 0.0
                
                UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
                    self.layoutIfNeeded()
    
                    if self.tableViewHeightConstraint.constant < (self.frame.height - self.safeAreaInsets.top - self.containerViewHeightContraint.constant) {
                        print("X")
                        self.tableView.contentInset.top = 0.0
                    } else {
                        print("Y")
                        self.tableView.contentInset.top = self.containerViewHeightContraint.constant
                    }
                }, completion: { (_) in
                    
                })
                
            }
        }
    }
    
    var comments = [Comment]()
    var isFinishedPagingComments: Bool = false
    var lastIndexComments: Int = 0
    func paginateComments() {
        print("paginating commentS")
        guard let postId = self.post?.id, let userId = post?.user?.uid else { return }
        let params = ["PID": postId, "lastIndex": lastIndexComments, "posterUID": userId]
        print(params)
        self.lastIndexComments += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateComments", params: params) { (json, _) in
            guard let json = json as? [[String: Any]]  else { return }
                print("comments json", json)
                json.count < 10 ? (self.isFinishedPagingComments = true) : (self.isFinishedPagingComments = false)
                if json.count > 0 {
                    json.forEach({ (snapshot) in
                        let user = User(dictionary: snapshot)
                        let comment = Comment(user: user, dictionary: snapshot)
                        print(comment.text, "COMMENT TEXT")
                        self.comments.append(comment)
                    })
                    
                    DispatchQueue.main.async {
                        self.layoutTableView()
                    }
                }
            
        }
        
    }

    fileprivate func layoutTableView() {
        UIView.animate(withDuration: 0, animations: {
            self.tableView.reloadData()
        }) { (complete) in
            UIView.animate(withDuration: 0, animations: {
                self.layoutIfNeeded()
            }) { (complete) in
                DispatchQueue.main.async {
                    var heightOfTableView: CGFloat = 0.0
                    
                    let cells = self.tableView.visibleCells
                    
                    for cell in cells {
                        heightOfTableView += cell.frame.height
                    }
                    
                    if heightOfTableView >= self.frame.height - self.safeAreaInsets.top - self.containerViewHeightContraint.constant {
                        self.tableViewHeightConstraint.constant = self.frame.height - self.safeAreaInsets.top
                        if let expired = self.post?.expired, expired {
                            self.tableView.contentInset.top = 0.0
                        } else {
                            // print(self.safeAreaInsets.bottom, self.containerView.frame.height, "SHIT NIGGA")
                            self.tableView.contentInset.top = self.containerViewHeightContraint.constant
                            let lastRect = self.tableView.rectForRow(at: IndexPath(item: 0, section: 0))
                            let portionRect = CGRect(x: lastRect.origin.x, y: lastRect.origin.y, width: 50, height: 50)
                            self.tableView.scrollRectToVisible(portionRect, animated: false)
                        }
                        
                        self.tableView.bounces = true
                        
                    } else {
                        print("Z")
                        self.tableViewHeightConstraint.constant = heightOfTableView
                        self.tableView.contentInset.top = 0.0
                        self.tableView.bounces = false
                    }
                }
                
            }
        }
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.item == comments.count - 1 && !isFinishedPagingComments {
            self.paginateComments()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as! CommentCell
        cell.selectionStyle = .none
        cell.comment = comments[indexPath.item]
        cell.delegate = self
        
        cell.transform = flipTransform
        cell.accessoryView?.transform = flipTransform
        
        if let currentUID = self.uid {
            if let postUID = post?.user?.uid, currentUID == postUID { //if its our post
                cell.showMore = true
            } else {
                if comments[indexPath.item].uid == currentUID {
                    cell.showMore = true
                } else {
                    cell.showMore = false
                }
            }
        } else {
            cell.showMore = false
        }
   
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
}

extension CommentsControllerCell: CommentCellDelegate {
    
    func showProfile(user: User) {
        let profileController = ProfileMainController()
        profileController.userId = user.uid
        profileController.partialUser = user
        profileController.wasPushed = true
        delegate?.showProfile(profileController: profileController)
    }
    
    func showMore(cell: CommentCell) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let showMore = cell.showMore, showMore {
            alertController.addAction(UIAlertAction(title: "Delete Comment", style: .destructive, handler: { (_) in
                
                guard let indexPath = self.tableView.indexPath(for: cell) else { return }
                self.deleteComment(indexPath: indexPath)
                
            }))
        } else {
            alertController.addAction(UIAlertAction(title: "Reply", style: .default, handler: { (_) in
                print("replying")
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        delegate?.presentAlertController(alertController: alertController)
        
    }
    
    fileprivate func deleteComment(indexPath: IndexPath) {

        guard let post = self.post, let user = post.user else { return }
        let comment = comments[indexPath.item]
        let commentId = comment.commentId
        
        let commentUserId = comment.uid
  
        let params = ["commentId" : commentId, "commentUserId" : commentUserId, "commentPostId": post.id, "posterUID": user.uid]
        print(params, "params")
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/deleteComment", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("successfully deleted comments")
            } else {
                print("Failed to delete comment")
            }
        }
        
        removeRowAtIndexPath(indexPath: indexPath)
  
    }
    
    fileprivate func removeRowAtIndexPath(indexPath: IndexPath) {
        
        self.comments.remove(at: indexPath.item)
        
        let rectToRemove = self.tableView.rectForRow(at: indexPath)
        
        if (self.tableView.contentSize.height - rectToRemove.height) < self.tableViewHeightConstraint.constant - self.containerViewHeightContraint.constant {
            
            self.tableView.bounces = false
            self.tableViewHeightConstraint.constant -= rectToRemove.height
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.contentInset.top = 0.0
                self.layoutIfNeeded()
            })
            
        }
        
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        self.tableView.endUpdates()
        
        if self.comments.count > 0 {
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
        
        self.delegate?.didCommentOrDelete(increment: -1)
        
    }
    
}

extension CommentsControllerCell: InputAccessoryViewDelegate {
    
    func tag(add: Bool) {
        if add {
            print("showing tag")
            self.containerViewHeightContraint.constant += 40
            UIView.animate(withDuration: 0.0) {
               self.layoutIfNeeded()
            }
            
        } else {
            print("hiding tag")
            self.containerViewHeightContraint.constant -= 40
            UIView.animate(withDuration: 0.0) {
                self.layoutIfNeeded()
            }
            
        }
    }
    
    func didSubmit(for text: String, taggedUids: [Int]) {
        guard let pid = self.post?.id, let uid = self.post?.uid, let username = self.post?.user?.username else { return }
        let params = ["PID": pid, "postuid": uid, "postusername": username, "text" : text, "taggedUsers": taggedUids] as [String: Any]
    
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/newComment", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("successfully commented")
            } else {
                print("failed to comment")
            }
        }

        guard let user = MainTabBarController.currentUser else {return}
        let values = ["uid": user.uid, "text": text, "creationDate": Date().timeIntervalSince1970] as [String : Any]
        
        let comment = Comment(user: user, dictionary: values)
        self.comments.insert(comment, at: 0)
        
        self.insertRow()
        
        self.delegate?.didCommentOrDelete(increment: 1)
        
    }
    
    fileprivate func insertRow() {
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .top)
        self.tableView.endUpdates()
        
        let rowHeight = self.tableView.rectForRow(at: IndexPath(item: 0, section: 0)).height

        if (self.tableView.contentSize.height + rowHeight) < (self.frame.height - self.safeAreaInsets.top - self.containerViewHeightContraint.constant) {
            
            self.tableView.bounces = false
            
            if comments.count == 1 {
                self.tableViewHeightConstraint.constant = rowHeight ////if first comment remove the 1.0 we added so that it rendered
            } else {
                self.tableViewHeightConstraint.constant += rowHeight
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.contentInset.top = 0.0
                
                self.layoutIfNeeded()
                
                
            }) { (_) in
                
                
            }
        } else {
            self.tableView.bounces = true
            
            self.tableViewHeightConstraint.constant = self.frame.height - self.safeAreaInsets.top
            UIView.animate(withDuration: 0) {
                self.tableView.layoutIfNeeded()
            }
            self.tableView.contentInset.top = self.containerViewHeightContraint.constant
            
        }
        
        self.containerView.clearTextField()
        self.containerView.textView.resignFirstResponder()
        self.containerViewHeightContraint.constant = 50
        self.containerViewBottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
        
    }
    
    func updateTableViewForText(additionalTextViewHeight: CGFloat) {
        if self.comments.count > 0 && self.tableView.bounces {
            self.additionalTextViewHeight += additionalTextViewHeight
            
            if (self.additionalTextViewHeight + additionalTextViewHeight) < self.additionalTextViewHeight { // if moving down animate it
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.tableView.contentInset.top += additionalTextViewHeight
                    })
                }
            } else { //else animation is automatic
                self.tableView.contentInset.top += additionalTextViewHeight
            }
            let rect = self.tableView.rectForRow(at: IndexPath(item: 0, section: 0))
            let partialRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: 50, height: 50)
            self.tableView.scrollRectToVisible(partialRect, animated: true)
            
        }
        
        self.containerViewHeightContraint.constant += additionalTextViewHeight
        UIView.animate(withDuration: 0.0) {
            self.layoutIfNeeded()
        }
        
    }
}

