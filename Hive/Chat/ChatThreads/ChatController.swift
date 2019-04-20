//
//  ChatController.swift
//  Highve
//
//  Created by Carter Randall on 2018-08-05.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ChatControllerDelegate: class {
    func updateMessageLog(message: Message, groupId: String?, user: User?)
    func insertNewLog(message: Message, userOne: User, userTwo: User?, groupId: String?, count: Int?)
    func mergeLogs(message: Message, user: User, index: Int?)
    func didLeaveGroupChat(groupId: String)
    func updateLogs()
    
}

class ChatController: UITableViewController, ChatInputAccessoryViewDelegate, ChatMessagePostAndTextCellDelegate, ChatMessagePostCellDelegate {
    
    fileprivate let messageCellId = "messageCellId"
    fileprivate let postCellId = "postCellId"
    fileprivate let postAndTextCellId = "postAndTextCellId"
    fileprivate let headerId = "headerId"
    fileprivate let typingCellId = "typingCellId"
    fileprivate let noticeCellId = "noticeCellId"
    
    fileprivate var isFirstFetch: Bool = true
    fileprivate var shouldMergeLogs: Bool = false
    
    fileprivate var typingTimer = Timer()
    fileprivate var isTypingCellShown: Bool = false
    fileprivate var additionalTextViewHeight: CGFloat = 0.0
    static var chatUpdateTimer = Timer()
    
    fileprivate var lastFetchDate: Double?
    
    fileprivate let slowSpeed: Double = 45.0
    fileprivate let fastSpeed: Double = 10.0
    fileprivate let extraFastSpeed: Double = 6.0
    
    var fetchFrequency: Double? {
        didSet {
            ChatController.chatUpdateTimer.invalidate()
            guard let fetchFrequency = fetchFrequency else { return }
            ChatController.chatUpdateTimer = Timer.scheduledTimer(timeInterval: fetchFrequency, target: self, selector: #selector(fetchNewMessages), userInfo: nil, repeats: true)
            print("SETTING FETCH FREQ", fetchFrequency)
        }
    }
    
    weak var delegate: ChatControllerDelegate?
    
    var isFromProfile: Bool = false
    var isNewMessage: Bool = false
    var isFromMap: Bool = false
    
    var groupId: String? {
        didSet {
            
            guard let id = groupId else { return }
            DispatchQueue.main.async {
                self.loadAndPaginateMessages(fid: nil, groupId: id)
            }
        }
    }
    
    var idToUserDict: [Int: User]? {
        didSet {
            guard let dict = idToUserDict else { return }
            
            if dict.count == 1, let user = dict.values.first {
                DispatchQueue.main.async {
                    self.loadAndPaginateMessages(fid: user.uid, groupId: nil)
                }
            }
        }
    }
    
    fileprivate func loadAndPaginateMessages(fid: Int?, groupId: String?) {
        var key: String?
        print("LOADING AND PAGINATING")
        if let fid = fid { key = String(fid) } else if let gid = groupId { key = gid }
        
        if let messageDict = messageCache.object(forKey: (key ?? "") as AnyObject) as? [Int: [Message]] {
            print("THERE WAS A KEY")
            self.groupedMessages = messageDict
            
            let sortedKeys = messageDict.keys.sorted()
            sortedKeys.forEach { (day) in
                if !(days.contains(day)) {
                    self.days.append(day)
                }
            }
            
            self.tableView.reloadData()
            self.tableView.performBatchUpdates(nil) { (_) in
                DispatchQueue.main.async {
                    self.fetchNewMessages()
                }
            }
            
        } else {
            print("THERE WAS NO KEY")
            paginateMessages(fid: fid, groupId: groupId)
        }
    }
    
    var messagesFromServer = [Message]()
    var groupedMessages = [Int: [Message]]()
    var days = [Int]()
    var isFinishedPaging: Bool = false
    func paginateMessages(fid: Int?, groupId: String?) {
        print("PAGINATING MESSAGES")
        
        var params = [String: Any]()
        
        if let fid = fid { params["FID"] = fid} else if let groupId = groupId {params["groupId"] = groupId}
        if let day = days.last {
            if let oldestTime = groupedMessages[day]?.last?.actualDate {
                params["lastTime"] = oldestTime
            }
        }
        
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateMessagesWithUser", params: params) { (json, _) in
            guard let messageJson = json as? [String: Any] else { return }
            
            if let typing = messageJson["typing"] as? Bool, typing {
                if !(self.isTypingCellShown) {
                    self.fetchFrequency = self.extraFastSpeed
                }
            }
            
            if let json = messageJson["json"] as? [[String:Any]], let user = MainTabBarController.currentUser {
                
                json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
                if json.count > 0 {
                    
                    json.forEach({ (snapshot) in
                        
                        var message = Message(dictionary: snapshot)
                        
                        if let isNotice = snapshot["joinleftGroup"] as? Int{
                            message.isNotice = isNotice
                        }
                        
                        if message.fromId == user.uid {
                            message.isIncoming = false
                        } else {
                            message.isIncoming = true
                        }
                        
                        if snapshot["toId"] == nil {
                            message.fromUser = FromUser(dictionary: snapshot)
                        }
                        
                        if let pid = snapshot["pid"] as? Int {
                            
                            var post = Post(dictionary: snapshot)
                            
                            var user = User(dictionary: snapshot)
                            user.uid = snapshot["uid"] as? Int ?? 0
                            
                            post.user = user
                            
                            post.id = pid
                            message.post = post
                        }
                        
                        if let deleted = snapshot["postDeleted"] as? Int, deleted > 0 {
                            message.postDeleted = deleted
                        }
                        
                        self.messagesFromServer.append(message)
                        
                    })
                    
                    let groupedDict = Dictionary(grouping: self.messagesFromServer) { (message) -> Int in
                        return message.daysAgo
                    }
                    
                    self.messagesFromServer.removeAll()
                    
                    let sortedDays = groupedDict.keys.sorted()
                    
                    sortedDays.forEach({ (day) in
                        let values = groupedDict[day]
                        let currentValues = self.groupedMessages[day]
                        self.groupedMessages[day] = (currentValues ?? []) + (values ?? [])
                        
                        if !(self.days.contains(day)) {
                            print("appending day")
                            self.days.append(day)
                        }
                    })
                    
                    if self.isFirstFetch {
                        if self.days.count > 0 && self.groupId == nil {
                            self.isNewMessage = false
                            self.isFirstFetch = false
                            self.shouldMergeLogs = true
                            
                            if let day = self.days.first {
                                
                                if let firstMessage = self.groupedMessages[day]?.first {
                                    
                                    let latestTime = firstMessage.sentDate
                                    if Int(Date().timeIntervalSince(latestTime)) < 600 {
                                        self.fetchFrequency = self.fastSpeed
                                    } else {
                                        self.fetchFrequency = self.slowSpeed
                                        self.containerView.shouldSendTypingStatus = false
                                    }
                                    
                                    self.lastFetchDate = firstMessage.actualDate
                                    
                                } else {
                                    self.fetchFrequency = self.slowSpeed
                                    self.containerView.shouldSendTypingStatus = false
                                }
                            }
                        }
                    }
                    
                    if let key = fid {
                        messageCache.setObject(NSDictionary(dictionary: self.groupedMessages), forKey: String(key) as AnyObject)
                    } else if let key = groupId {
                        messageCache.setObject(NSDictionary(dictionary: self.groupedMessages), forKey: key as AnyObject)
                    }
                    
                    print("reloading")
                    self.tableView.reloadData()
                    
                }
            }
        }
        
    }
    
    lazy var containerView: ChatInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let inputAccessoryView = ChatInputAccessoryView(frame: frame)
        
        inputAccessoryView.placeHolderText = "Message"
        inputAccessoryView.delegate = self
        inputAccessoryView.sendButton.setTitleColor(.mainBlue(), for: .normal)
        if let id = self.idToUserDict?.values.first?.uid {
            inputAccessoryView.chatPartnerId = id
        }
        return inputAccessoryView
    }()
    
    func didSubmit(for text: String) {
        
        if fetchFrequency == self.slowSpeed && !(self.isNewMessage) {
            self.fetchFrequency = self.fastSpeed
        }
        
        
        var params = ["text": text] as [String: Any]
        if groupId != nil, let groupId = self.groupId {
            params["groupId"] = groupId
            if let idArray = idToUserDict?.keys, isNewMessage && self.groupedMessages.count == 0 {
                
                params["idArray"] = Array(idArray)
            }
        } else if let toId = idToUserDict?.keys.first {
            params["toId"] = toId
        }
        
        let serverParams = params
        
        DispatchQueue.main.async {
            
            params["fromId"] = MainTabBarController.currentUser?.uid ?? 0
            let date = Date().timeIntervalSince1970
            params["sentDate"] = date
            var message = Message(dictionary: params)
            message.isIncoming = false
            
            let day = message.daysAgo
            let dayCount = self.groupedMessages[day]?.count
            var currentValues = self.groupedMessages[day]
            if self.isTypingCellShown {
                if let typingMessage = currentValues?[0] {
                    currentValues?.remove(at: 0)
                    self.groupedMessages[day] = [typingMessage] + [message] + (currentValues ?? [])
                }
            } else {
                self.groupedMessages[day] = [message] + (currentValues ?? [])
                
            }
            
            if !(self.days.contains(day)) {
                self.days.insert(day, at: 0)
            }
            
            self.tableView.reloadData()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.contentInset.top -= self.additionalTextViewHeight
                self.additionalTextViewHeight = 0.0
            })
            
            //update log
            //send to server n stuff
            self.updateMessagesAfterSending(serverParams: serverParams, message: message, dayCount: dayCount, day: day)
            
        }
        
        self.containerView.clearTextField()
        
    }
    
    func updateMessagesAfterSending(serverParams: [String: Any], message: Message, dayCount: Int?, day: Int) {
        
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/newMessage", params: serverParams) { (json, response) in
            if let timeJson = json as? [String: Any], let time = timeJson["timeStamp"] as? Double {
                
                var message = message
                message.actualDate = time
                self.groupedMessages[day]?[0] = message
                
                print("message after updating", message)
                if self.isNewMessage {
                    var userOne: User!
                    var userTwo: User?
                    var groupId: String?
                    
                    guard let values = self.idToUserDict?.values else { return }
                    
                    let users = Array(values)
                    if let firstUser = users.first { userOne = firstUser }
                    if users.count > 1 {
                        userTwo = users[1]
                    }
                    
                    if let gid = self.groupId {
                        groupId = gid
                    }
                    
                    self.delegate?.insertNewLog(message: message, userOne: userOne, userTwo: userTwo, groupId: groupId, count: values.count == 1 ? nil : values.count)
                    
                    self.isNewMessage = false
                    
                } else if self.shouldMergeLogs {
                    
                    if let values = self.idToUserDict?.values, let user = values.first {
                        self.delegate?.mergeLogs(message: message, user: user, index: nil)
                        self.shouldMergeLogs = false
                    }
                } else {
                    
                    if let gid = self.groupId {
                        self.delegate?.updateMessageLog(message: message, groupId: gid, user: nil)
                    } else if let values = self.idToUserDict?.values, let user = values.first {
                        self.delegate?.updateMessageLog(message: message, groupId: nil, user: user)
                    }
                }
                
            } else {
                print(response as Any, "new message response")
            }
        }
    }
    
    
    func updateTableViewForText(additionalTextViewHeight: CGFloat) {
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
        let lastCellRect = tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        let invertedCellRect = CGRect(x: lastCellRect.minY, y: tableView.frame.height - lastCellRect.height - lastCellRect.minY, width: lastCellRect.width, height: lastCellRect.height)
        
        var visibleRect = tableView.frame
        visibleRect.size.height -= (keyboardHeight)
        if !(visibleRect.contains(invertedCellRect)) {
            print(lastCellRect, "LAST CELL RECT")
            let portionRect = CGRect(x: lastCellRect.origin.x, y: lastCellRect.origin.y, width: 50, height: 50)
            self.tableView.scrollRectToVisible(portionRect, animated: true)
            
        }
        
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return containerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MainTabBarController.requestManager.delegate = self
        setupNavBarAppearance()
        setupTableView()
        setupNavBarCollectionView()
        registerForKeyboardNotifications()
        
    }
    
    let navBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    fileprivate func setupNavBarAppearance() {
        
        guard let navBar = navigationController?.navigationBar else { return }
        
        if isFromMap {
            navigationController?.makeTransparent()
        } else {
            navBlurView.layer.borderColor = UIColor.darkLineColor().cgColor
            navBlurView.layer.borderWidth = 0.5
            navigationController?.navigationBar.insertSubview(navBlurView, at: 0)
            navBlurView.anchor(top: navBar.topAnchor, left: navBar.leftAnchor, bottom: navBar.bottomAnchor, right: navBar.rightAnchor, paddingTop: -UIApplication.shared.statusBarFrame.height, paddingLeft: 0, paddingBottom: -25, paddingRight: 0, width: 0, height: 0)
        }
        
        
        navigationItem.hidesBackButton = true
        navBar.tintColor = .black
        
        if isFromMap {
            print("is from map")
            let cancelButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleBack))
            navigationItem.leftBarButtonItem = cancelButton
        } else {
            let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    var chatBarCollectionView: ChatBarCollectionView!
    fileprivate func setupNavBarCollectionView() {
        
        guard let navBar = navigationController?.navigationBar else { return }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        chatBarCollectionView = ChatBarCollectionView(frame: .zero, collectionViewLayout: layout)
        chatBarCollectionView.cvDelegate = self
        
        if isNewMessage, let users = idToUserDict?.values {
            chatBarCollectionView.users = Array(users)
        } else if let groupId = groupId {
            chatBarCollectionView.groupId = groupId
        } else if let user = idToUserDict?.values.first {
            chatBarCollectionView.users.append(user)
        }
        
        navBar.addSubview(chatBarCollectionView)
        chatBarCollectionView.anchor(top: navBar.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 130, height: 65)
        chatBarCollectionView.centerXAnchor.constraint(equalTo: navBar.centerXAnchor).isActive = true
        
    }
    
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupTableView() {
        tableView.allowsSelection = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: messageCellId)
        tableView.register(ChatMessagePostCell.self, forCellReuseIdentifier: postCellId)
        tableView.register(ChatMessagePostAndTextCell.self, forCellReuseIdentifier: postAndTextCellId)
        tableView.register(HeaderContainerView.self, forHeaderFooterViewReuseIdentifier: headerId)
        tableView.register(TypingCell.self, forCellReuseIdentifier: typingCellId)
        tableView.register(ChatNoticeCell.self, forCellReuseIdentifier: noticeCellId)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        if isFromMap {
            tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            tableView.backgroundColor = UIColor.clear
        } else {
            tableView.backgroundColor = .white
        }
        tableView.keyboardDismissMode = .onDrag
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        tableView.addGestureRecognizer(swipeGesture)
        
    }
    
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var shouldScroll: Bool = true
    var keyboardHeight: CGFloat = 0.0
    @objc func keyboardWillShow(notification: NSNotification) {
        
        if keyboardHeight > 50 { return }
        if shouldScroll {
            
            if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let convertedKeyboard = self.view.convert(keyboardFrame, from: nil)
                keyboardHeight = convertedKeyboard.height
                var contentInset = self.tableView.contentInset
                if convertedKeyboard.height > 50 {
                    contentInset.top += convertedKeyboard.size.height - 50
                    
                } else { //just input view
                    
                    contentInset.top += convertedKeyboard.size.height
                }
                
                self.tableView.contentInset = contentInset
                
                let lastCellRect = self.tableView.rectForRow(at: IndexPath(item: 0, section: 0))
                let rectForCellInSuperView = self.tableView.convert(lastCellRect, to: self.view)
                DispatchQueue.main.async {
                    let portionRect = CGRect(x: rectForCellInSuperView.origin.x, y: rectForCellInSuperView.origin.y, width: 50, height: 50)
                    self.tableView.scrollRectToVisible(portionRect, animated: true)
                }
                
            }
            
        } else {
            shouldScroll = true
        }
        
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        
        if adjustScrollSizeOnHide {
            
            shouldScroll = false
            keyboardHeight = 50
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: {
                    if self.containerView.textView.text.isEmpty {
                        self.tableView.contentInset.top = 66
                    } else {
                        self.tableView.contentInset.top = 66 + self.additionalTextViewHeight
                    }
                })
            }
            
        } else {
            adjustScrollSizeOnHide = true
        }
    }
    
    @objc func handleBack() {
        
        if let day = self.days.first {
            if let latestMessage = self.groupedMessages[day]?.first {
                if let isIncoming = latestMessage.isIncoming, isIncoming {
                    self.delegate?.updateLogs()
                }
            }
        }
        
        self.removeTypingCell()
        if isFromMap {
            self.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        ChatController.chatUpdateTimer.invalidate()
        self.typingTimer.invalidate()
        
        navBlurView.isHidden = true
        if chatBarCollectionView != nil {
            self.chatBarCollectionView.isHidden = true
        }
        
        let visibleCells = tableView.visibleCells
        visibleCells.forEach { (cell) in
            if let postCell = cell as? ChatMessagePostCell {
                postCell.player?.pause()
            }
        }
        
        if let groupId = self.groupId {
            messageCache.setObject(NSDictionary(dictionary: self.groupedMessages), forKey: groupId as AnyObject)
        } else if let user = self.idToUserDict?.values.first {
            messageCache.setObject(NSDictionary(dictionary: self.groupedMessages), forKey: String(user.uid) as AnyObject)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("VIEW WILL APPEAR")
        if chatBarCollectionView != nil {
            self.chatBarCollectionView.isHidden = false
        }
        
        navBlurView.isHidden = false
        
        if AppDelegate.BecameActive {
            fetchFrequency = fastSpeed
            self.fetchNewMessages()
        }
        
        
        
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let postCell = cell as? ChatMessagePostCell {
            postCell.player?.pause()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TypingCell {
            cell.animateScale()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerId) as! HeaderContainerView
        if let lastMessageInSection = groupedMessages[days[section]]?.last {
            view.label.text = lastMessageInSection.sentDate.timeAgoDisplay()
        }
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groupedMessages.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedMessages[days[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == days.count - 1 && indexPath.item == (groupedMessages[days[indexPath.section]]?.count ?? 0) - 1 && !isFinishedPaging {
            if let id = self.groupId {
                self.paginateMessages(fid: nil, groupId: id)
            } else if let user = self.idToUserDict?.values.first {
                self.paginateMessages(fid: user.uid, groupId: nil)
            }
        }
        
        let message = groupedMessages[days[indexPath.section]]?[indexPath.item] ?? Message(dictionary: [:])
        
        if message.isNotice != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: noticeCellId, for: indexPath) as! ChatNoticeCell
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            cell.message = message
            return cell
        }
        
        if let isTypingIndicator = message.isTypingIndicator, isTypingIndicator {
            let cell = tableView.dequeueReusableCell(withIdentifier: typingCellId, for: indexPath) as! TypingCell
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            if let user = idToUserDict?.values.first {
                cell.user = user
            }
            return cell
        }
        
        if message.post != nil {
            if message.text != "" {
                return getChatPostAndTextCell(message: message, indexPath: indexPath)
            } else {
                return getChatPostCell(message: message, indexPath: indexPath)
            }
        } else {
            return getChatMessageCell(message: message, indexPath: indexPath)
        }
        
    }
    
    var adjustScrollSizeOnHide: Bool = true
    func didTapExpandPost(cell: ChatMessagePostCell) {
        
        adjustScrollSizeOnHide = false
        guard let message = cell.message, let index = tableView.indexPath(for: cell) else { return }
        showPostViewer(message: message, index: index.item)
    }
    
    func didTapExpandPost(cell: ChatMessagePostAndTextCell) {
        adjustScrollSizeOnHide = false
        guard let message = cell.message, let index = tableView.indexPath(for: cell) else { return }
        showPostViewer(message: message, index: index.item)
        
    }
    
    fileprivate func showPostViewer(message: Message, index: Int) {
        
        self.shouldScroll = false
        let layout = UICollectionViewFlowLayout()
        let postViewer = FeedPostViewerController(collectionViewLayout: layout)
        postViewer.isFromChat = true
        postViewer.posts = [message.post] as! [Post]
        self.navigationController?.pushViewController(postViewer, animated: true)
        
    }
    
}

extension ChatController: ChatBarCollectionViewDelegate {
    
    func showProfile(user: User) {
        
        if isFromProfile {
            navigationController?.popViewController(animated: true)
        } else {
            let profileController = ProfileMainController()
            profileController.userId = user.uid
            if !isFromMap {
                profileController.partialUser = user
            }
            profileController.isFromChat = true
            profileController.wasPushed = true
            navigationController?.pushViewController(profileController, animated: true)
        }
        
    }
    
    func showGroupDetail(users: [User], isFinishedPaging: Bool, lastIndex: Int, allIds: [Int], uids: [Int]) {
        
        let layout = UICollectionViewFlowLayout()
        let groupChatDetailController = GroupChatDetailController(collectionViewLayout: layout)
        groupChatDetailController.users = users
        for user in users {
            groupChatDetailController.uids.append(user.uid)
        }
        groupChatDetailController.isFinishedPagingUsers = isFinishedPaging
        groupChatDetailController.lastIndex = lastIndex
        groupChatDetailController.delegate = self
        groupChatDetailController.allIds = allIds
        groupChatDetailController.uids = uids
        groupChatDetailController.isNewMessage = self.isNewMessage
        if let groupId = self.groupId {
            groupChatDetailController.groupId = groupId
        }
        navigationController?.pushViewController(groupChatDetailController, animated: true)
    }
    
}

extension ChatController: GroupChatDetailControllerDelegate {
    
    func didLeaveGroupChat(groupId: String) {
        delegate?.didLeaveGroupChat(groupId: groupId)
    }
    
    func didAddUsersToGroupChat(idToUserDict: [Int : User]) {
        self.fetchNewMessages()
        idToUserDict.values.forEach { (user) in
            self.chatBarCollectionView.users.append(user)
        }
        self.chatBarCollectionView.reloadData()
    }
    
}

extension ChatController: CAAnimationDelegate {
    
    fileprivate func insertTypingCell() {
        print("INSERTING TYPING CELL\n\n")
        self.isTypingCellShown = true
        self.fetchFrequency = extraFastSpeed
        let dictionary = ["sentDate": Date().timeIntervalSince1970] as [String: Any]
        var message = Message(dictionary: dictionary)
        message.isIncoming = true
        message.isTypingIndicator = true
        let day = message.daysAgo
        let currentValues = self.groupedMessages[day]
        self.groupedMessages[day] = [message] + (currentValues ?? [])
        
        if !(self.days.contains(day)) {
            self.days.insert(day, at: 0)
        }
        
        self.tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .top)
        
        typingTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(removeTypingCell), userInfo: nil, repeats: false)
        
        
    }
    
    @objc fileprivate func removeTypingCell() {
        if isTypingCellShown {
            isTypingCellShown = false
            typingTimer.invalidate()
            if let day = self.days.first {
                var currentValues = self.groupedMessages[day]
                currentValues?.remove(at: 0)
                if currentValues?.count == 0 {
                    self.days.remove(at: 0)
                    self.groupedMessages[day] = nil
                } else {
                    self.groupedMessages[day] = (currentValues ?? [])
                }
            }
            
            self.tableView.deleteRows(at: [IndexPath(item: 0, section: 0)], with: .top)
        }
    }
    
    fileprivate func getChatPostAndTextCell(message: Message, indexPath: IndexPath) -> ChatMessagePostAndTextCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: postAndTextCellId, for: indexPath) as! ChatMessagePostAndTextCell
        
        cell.message = message
        cell.delegate = self
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.accessoryView?.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if let isIncoming = message.isIncoming, isIncoming {
            if groupId != nil {
                
                cell.constraintConfig = 0
                
                if indexPath.item != 0 {
                    if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1] {
                        
                        if prevMessage.fromId == message.fromId {
                            cell.senderImageView.isHidden = true
                        } else {
                            cell.senderImageView.isHidden = false
                            if let user = message.fromUser {
                                cell.senderImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                            }
                        }
                        
                    }
                } else {
                    cell.senderImageView.isHidden = false
                    if let user = message.fromUser {
                        cell.senderImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                    }
                }
            } else {
                cell.constraintConfig = 1
            }
            
            cell.readReceiptTime = nil
            
        } else {
            cell.senderImageView.isHidden = true
            cell.constraintConfig = 2
            
            if indexPath.section == 0 && indexPath.item == 0 {
                if groupId == nil && message.seen != nil {
                    cell.readReceiptTime = message.seen
                } else {
                    cell.readReceiptTime = nil
                }
            } else if indexPath.item != 0 {
                if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1] {
                    if prevMessage.seen != nil && groupId == nil {
                        cell.readReceiptTime = nil
                    } else if message.seen != nil && groupId == nil {
                        cell.readReceiptTime = message.seen
                    } else {
                        cell.readReceiptTime = nil
                    }
                    
                }
                
            }
            
        }
        
        return cell
        
    }
    
    fileprivate func getChatPostCell(message: Message, indexPath: IndexPath) -> ChatMessagePostCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: postCellId, for: indexPath) as! ChatMessagePostCell
        cell.delegate = self
        cell.message = message
        
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.accessoryView?.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if let isIncoming = message.isIncoming, isIncoming {
            if groupId != nil {
                cell.constraintConfig = 0
                if indexPath.item != 0 {
                    
                    if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1]  {
                        if prevMessage.fromId == message.fromId {
                            cell.senderImageView.isHidden = true
                        } else {
                            cell.senderImageView.isHidden = false
                            if let user = message.fromUser {
                                cell.senderImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                            }
                        }
                    }
                    
                } else {
                    cell.senderImageView.isHidden = false
                    if let user = message.fromUser {
                        cell.senderImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                    }
                }
            } else {
                cell.constraintConfig = 1
            }
            
            cell.readReceiptTime = nil
            
        } else {
            cell.constraintConfig = 2
            
            if indexPath.section == 0 && indexPath.item == 0 {
                if groupId == nil && message.seen != nil {
                    cell.readReceiptTime = message.seen
                } else {
                    cell.readReceiptTime = nil
                }
            } else if indexPath.item != 0 {
                if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1] {
                    if prevMessage.seen != nil && groupId == nil {
                        cell.readReceiptTime = nil
                    } else if message.seen != nil && groupId == nil {
                        cell.readReceiptTime = message.seen
                    } else {
                        cell.readReceiptTime = nil
                    }
                    
                }
                
            }
        }
        
        return cell
        
    }
    
    fileprivate func getChatMessageCell(message: Message, indexPath: IndexPath) -> ChatMessageCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: messageCellId, for: indexPath) as! ChatMessageCell
        
        cell.message = message
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.accessoryView?.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if let isIncoming = message.isIncoming, isIncoming {
            if groupId != nil {
                
                cell.constraintConfig = 0
                
                if indexPath.item != 0 {
                    if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1] {
                        if prevMessage.fromId == message.fromId {
                            cell.profileImageView.isHidden = true
                        } else {
                            cell.profileImageView.isHidden = false
                            if let user = message.fromUser {
                                cell.profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                            }
                        }
                    }
                } else {
                    cell.profileImageView.isHidden = false
                    if let user = message.fromUser {
                        cell.profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.id)
                    }
                }
            } else {
                
                cell.constraintConfig = 1
            }
            
            cell.readReceiptTime = nil
            
        } else {
            cell.profileImageView.isHidden = true
            
            cell.constraintConfig = 2
            
            
            if indexPath.section == 0 && indexPath.item == 0 { //need something else so read extends into previous days
                if groupId == nil && message.seen != nil {
                    cell.readReceiptTime = message.seen
                } else {
                    cell.readReceiptTime = nil
                }
            } else if indexPath.item != 0 {
                
                if let prevMessage = groupedMessages[days[indexPath.section]]?[indexPath.item - 1] {
                    if prevMessage.seen != nil && groupId == nil {
                        cell.readReceiptTime = nil
                    } else if message.seen != nil && groupId == nil {
                        cell.readReceiptTime = message.seen
                    } else {
                        cell.readReceiptTime = nil
                    }
                }
                
            }
        }
        
        return cell
        
    }
}

extension ChatController {
    
    @objc fileprivate func fetchNewMessages(onReconnect:Bool=false) {
        
        print("fetching new messages")
        var params = [String: Any]()
        if let groupId = self.groupId { params["groupId"] = groupId }
        else if let fid = self.idToUserDict?.keys.first { params["FID"] = fid }
        
        if let mostRecentDate = self.lastFetchDate {
            params["lastTime"] = mostRecentDate
        } else {
            if let day = self.days.first {
                if let newestMessageDate = self.groupedMessages[day]?.first?.actualDate {
                    params["lastTime"] = newestMessageDate
                }
            }
            if onReconnect {
                params["lastTime"] = 0.0
            }
            print("no last FetchDate");
        }
        print("fetching new")
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/updateMessagesWithUser", params: params) { (json, _) in
            
            guard let json = json as? [String: Any] else {print("fd"); return }
            
            var shouldInsertTypingCell: Bool = false
            
            if let messageJson = json["json"] as? [[String: Any]] {
                if let typing = json["typing"] as? Int, typing == 1 {
                    print(typing, "tpying")
                    if !(self.isTypingCellShown) {
                        shouldInsertTypingCell = true
                        self.fetchFrequency = self.extraFastSpeed
                    }
                }
                self.processNewMessageJson(messageJson: messageJson, shouldInsertTypingCell: shouldInsertTypingCell)
            } else {
                print("no message json")
                if let typing = json["typing"] as? Int, typing == 1 {
                    print(typing, "tpying")
                    if !(self.isTypingCellShown) {
                        shouldInsertTypingCell = true
                        self.fetchFrequency = self.extraFastSpeed
                    }
                }
                self.processNewMessageJson(messageJson: [], shouldInsertTypingCell: shouldInsertTypingCell)
            }
            
        }
        
    }
    
    fileprivate func processNewMessageJson(messageJson: [[String: Any]], shouldInsertTypingCell: Bool) {
        
        guard let user = MainTabBarController.currentUser else {print("no cu"); return }
        
        if messageJson.count > 0 {
            print(messageJson, "MESSAGE JSON")
            if self.isTypingCellShown {
                self.removeTypingCell()
            }
            
            if self.fetchFrequency == self.slowSpeed {
                self.fetchFrequency = self.fastSpeed
            }
            
            self.containerView.shouldSendTypingStatus = true
            
            self.messagesFromServer.removeAll()
            
            messageJson.forEach({ (snapshot) in
                
                var message = Message(dictionary: snapshot)
                print("message in fetching new", message)
                if let isNotice = snapshot["joinleftGroup"] as? Int{
                    message.isNotice = isNotice
                }
                
                var shouldExitFor: Bool = false
                
                if let day = self.days.first {
                    if var messagesOfTheDay = self.groupedMessages[day] {
                        var index = 0
                        for existingMessage in messagesOfTheDay {
                            if shouldExitFor { return }
                            
                            if existingMessage.id == message.id {
                                print("already had one with this id")
                                if message.seen != nil {
                                    
                                    messagesOfTheDay.remove(at: index)
                                    self.groupedMessages[day] = messagesOfTheDay
                                    
                                } else {
                                    shouldExitFor = true
                                }
                            } else {
                                
                                if existingMessage.actualDate == message.actualDate && existingMessage.id == 0 {
                                    if message.seen != nil {
                                        print("replacing messagin")
                                        messagesOfTheDay.remove(at: index)
                                        self.groupedMessages[day] = messagesOfTheDay
                                        
                                    } else {
                                        print("exiting for")
                                        shouldExitFor = true
                                    }
                                } else {
                                    
                                }
                            }
                            index += 1
                        }
                    }
                }
                
                if shouldExitFor { return }
                
                if message.fromId == user.uid {
                    message.isIncoming = false
                } else {
                    message.isIncoming = true
                }
                
                if snapshot["toId"] == nil {
                    message.fromUser = FromUser(dictionary: snapshot)
                }
                
                if (snapshot["pid"] as? Int) != nil {
                    var post = Post(dictionary: snapshot)
                    post.user = User(dictionary: snapshot) //fix later here id post and id user same accessor
                    message.post = post
                    
                }
                
                if let deleted = snapshot["postDeleted"] as? Int, deleted > 0 {
                    message.postDeleted = deleted
                }
                
                self.messagesFromServer.append(message)
                
                print(messagesFromServer.count, "MESSAGES FROM SERVER COUNT")
                
            })
            
            let groupedDict = Dictionary(grouping: self.messagesFromServer) { (message) -> Int in
                return message.daysAgo
            }
            
            self.messagesFromServer.removeAll()
            
            let sortedDays = groupedDict.keys.sorted()
            
            sortedDays.forEach({ (day) in
                let values = groupedDict[day]
                var currentValues = self.groupedMessages[day]
                
                if self.isTypingCellShown {
                    if let typingMessage = currentValues?[0] {
                        currentValues?.remove(at: 0)
                        var newValues = (values ?? []) + (currentValues ?? [])
                        newValues.sort(by: { (m1, m2) -> Bool in
                            return m1.sentDate.compare(m2.sentDate) == .orderedDescending
                        })
                        self.groupedMessages[day] = [typingMessage] + newValues
                    }
                } else {
                    
                    var newValues = (values ?? []) + (currentValues ?? [])
                    newValues.sort(by: { (m1, m2) -> Bool in
                        return m1.sentDate.compare(m2.sentDate) == .orderedDescending
                    })
                    
                    self.groupedMessages[day] = newValues
                    
                }
                
                if !(self.days.contains(day)) {
                    self.days.insert(day, at: 0)
                }
            })
            
            if let day = self.days.first {
                if let newestMessageDate = self.groupedMessages[day]?.first?.actualDate {
                    self.lastFetchDate = newestMessageDate
                }
            }
            
            self.tableView.reloadData()
            
        } else if let day = self.days.first {
            print("zero count")
            if let latestMessage = self.groupedMessages[day]?.first {
                let latestTime = latestMessage.sentDate
                if Int(Date().timeIntervalSince(latestTime)) > 120 && self.fetchFrequency != self.slowSpeed {
                    self.fetchFrequency = self.slowSpeed
                    self.containerView.shouldSendTypingStatus = false
                }
            }
            if shouldInsertTypingCell {
                print("inserting typing cell")
                self.insertTypingCell()
            } else {
                print("not inserting typing cell")
            }
        }
        
    }
    
}

extension ChatController: RequestManagerDelegate {
    func reconnectedToInternet() {
        self.fetchNewMessages(onReconnect: true)
        
    }
}
