
//
//  ChatLogController.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ChatLogControllerDelegate: class {
    func updateMessages()
}

class ChatLogController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewChatControllerDelegate {
    
    weak var delegate: ChatLogControllerDelegate?
    
    let chatLogCellId = "chatLogCellId"
    
    fileprivate var isFirstLoad: Bool = true
    fileprivate var lastFetchDate: Double?
    static var messageLogUpdateTimer = Timer()
    
    fileprivate let fastSpeed: Double = 7.0
    fileprivate let slowSpeed: Double = 60.0
    
    var fetchFrequency: Double? {
        didSet {
            ChatLogController.messageLogUpdateTimer.invalidate()
            guard let fetchFrequency = fetchFrequency else { return }
            ChatLogController.messageLogUpdateTimer = Timer.scheduledTimer(timeInterval: fetchFrequency, target: self, selector: #selector(fetchNewLogs(onReconnect:)), userInfo: nil, repeats: true)
            print("SETTING FETCH FREQ", fetchFrequency)
        }
    }
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.allowsMultipleSelectionDuringEditing = true
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainTabBarController.requestManager.delegate = self
        setupNavBar()
        setupViews()
        loadAndPaginateChatLogs()
        
    }
    
    fileprivate func setupViews() {
        
        view.backgroundColor = .white
        tableView.backgroundColor = .white
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatLogCell.self, forCellReuseIdentifier: chatLogCellId)
        
        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    fileprivate func setupNavBar() {
        
        navigationController?.makeTransparent()
        navigationController?.navigationBar.tintColor = .black
        
        navigationItem.title = "Messages"
        
        let newChatButton = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(handleNewChat))
        navigationItem.rightBarButtonItem = newChatButton
        
        let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleDismiss))
        navigationItem.leftBarButtonItem = dismissButton
        
    }
    
    @objc func handleNewChat() {
        let newChatController = NewChatController()
        newChatController.delegate = self
        newChatController.isNewMessage = true
        let newChatNavController = UINavigationController(rootViewController: newChatController)
        present(newChatNavController, animated: true, completion: nil)
    }
    
    @objc func handleDismiss() {
        delegate?.updateMessages()
        print("invalidating")
        if ChatLogController.messageLogUpdateTimer.isValid {
            ChatLogController.messageLogUpdateTimer.invalidate()
            
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if ChatLogController.messageLogUpdateTimer.isValid {
            ChatLogController.messageLogUpdateTimer.invalidate()
            
        }
        chatLogCache.setObject(self.logMessages as AnyObject, forKey: "chatLogs" as AnyObject)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !ChatLogController.messageLogUpdateTimer.isValid {
            self.fetchFrequency = fastSpeed
        }
        
        if AppDelegate.BecameActive {
            self.fetchNewLogs()
        }
        
    }
    
    fileprivate func loadAndPaginateChatLogs() {
        if let logs = chatLogCache.object(forKey: "chatLogs" as AnyObject) as? [LogMessage] {
            self.logMessages = logs
            self.lastIndex = Int(floor(Double(logs.count) / 10)) + 1
            self.tableView.reloadData()
            self.tableView.performBatchUpdates(nil) { (_) in
                DispatchQueue.main.async {
                    self.fetchNewLogs()
                }
            }
        } else {
            print("THERE WAS NO LOGS IN CACHE")
            self.pagainteChatLogs()
        }
    }
    
    var logMessages = [LogMessage]()
    var lastIndex: Int = 0
    var isFinishedPaging: Bool = false
    var flaggedUids = [Int]()
    func pagainteChatLogs() {
        print("PAGINATING")
        self.lastFetchDate = Date().timeIntervalSince1970
        let params = ["lastIndex" : lastIndex]
        self.lastIndex += 1
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/paginateMessageThreads", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            json.count < 10 ? (self.isFinishedPaging = true) : (self.isFinishedPaging = false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    
                    guard let log = self.logFromSnapshot(snapshot: snapshot, isPaginatingOlder: true) else { return }
                    self.logMessages.append(log)
                    
                })
                
                self.tableView.reloadData()
            }
            
            if self.isFirstLoad && self.logMessages.count == 0 {
                self.handleNewChat()
                self.isFirstLoad = false
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let log = self.logMessages[indexPath.row]
        var params = [String: Any]()
        
        if let chatPartnerId = log.message?.chatPartnerId(), log.groupId == "" { params["conversationPartner"] = chatPartnerId }
        else if log.groupId != "" { params["groupId"] = log.groupId } else { return }
        
        MainTabBarController.requestManager.makeResponseRequest(urlString: "/Hive/api/deleteMessageThread", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("Successfully deleted message thread")
            } else {
                print("Failed to delete message thread")
            }
        }
        
        self.logMessages.remove(at: indexPath.item)
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var log = logMessages[indexPath.row]
        log.seen = true
        
        logMessages[indexPath.row] = log
        
        self.tableView.reloadData()
        
        let chatController = ChatController(style: .grouped)
        
        chatController.delegate = self
        if logMessages[indexPath.row].count != nil {
            chatController.groupId = logMessages[indexPath.row].groupId
        } else {
            if let user = logMessages[indexPath.row].userOne {
                chatController.idToUserDict = [user.uid: user]
            }
        }
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    func showChatControllerForUser(idToUserDict: [Int: User]) {
        let chatController = ChatController(style: .grouped)
        chatController.idToUserDict = idToUserDict
        
        chatController.delegate = self
        chatController.isNewMessage = true
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    func showChatControllerForGroup(idToUserDict: [Int : User], groupId: String) {
        let chatController = ChatController(style: .grouped)
        chatController.isNewMessage = true
        
        chatController.groupId = groupId
        chatController.idToUserDict = idToUserDict
        chatController.delegate = self
        navigationController?.pushViewController(chatController, animated: true)
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.item == logMessages.count - 1 && !isFinishedPaging {
            self.pagainteChatLogs()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: chatLogCellId, for: indexPath) as! ChatLogCell
        cell.selectionStyle = .none
        let logMessage = logMessages[indexPath.row]
        cell.logMessage = logMessage
        
        if !(logMessage.seen) && logMessage.message?.fromId != MainTabBarController.currentUser?.uid {
            cell.showNotificationView = true
        } else {
            cell.showNotificationView = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 80.0 }
    
}

extension ChatLogController: ChatControllerDelegate {
    
    
    func updateLogs() {
        self.fetchNewLogs()
    }
    
    
    
    
    
    func didLeaveGroupChat(groupId: String) {
        let i = logMessages.firstIndex(where: { (log) -> Bool in
            return log.groupId == groupId
        })
        if let index = i {
            self.logMessages.remove(at: index)
            self.tableView.reloadData()
        }
    }
    
    func updateMessageLog(message: Message, groupId: String?, user: User?) {
        if let groupId = groupId {
            let idx = logMessages.firstIndex { (log) -> Bool in
                return log.groupId == groupId
            }
            
            if let index = idx {
                var logMessage = self.logMessages[index]
                logMessage.message = message
                self.logMessages.remove(at: index)
                self.logMessages.insert(logMessage, at: 0)
                self.tableView.reloadData()
            }
            
            
        } else if let user = user {
            let idx = logMessages.firstIndex { (log) -> Bool in
                return log.userOne?.uid == user.uid
            }
            
            if let index = idx {
                var logMessage = self.logMessages[index]
                logMessage.message = message
                self.logMessages.remove(at: index)
                self.logMessages.insert(logMessage, at: 0)
                self.tableView.reloadData()
            }
        }
    }
    
    
    func insertNewLog(message: Message, userOne: User, userTwo: User?, groupId: String?, count: Int?) {
        
        if groupId == nil {
            //check if we would merge instead
            let index = logMessages.firstIndex { (log) -> Bool in
                return (log.userOne?.uid == userOne.uid && log.groupId == "")
            }
            
            if let index = index {
                self.mergeLogs(message: message, user: userOne, index: index)
            }
        }
        
        var dictionary: [String: Any]!
        if let userTwo = userTwo, let groupId = groupId {
            dictionary = ["groupId": groupId, "secondId": userTwo.uid, "secondusername": userTwo.username, "secondprofileImageUrl": userTwo.profileImageUrl.absoluteString]
            
        } else {
            dictionary = [:]
        }
        var logMessage = LogMessage(dictionary: dictionary)
        logMessage.message = message
        logMessage.userOne = userOne
        
        if let count = count {
            logMessage.count = count
        }
        
        self.logMessages.insert(logMessage, at: 0)
        self.tableView.reloadData()
        
    }
    
    func mergeLogs(message: Message, user: User, index: Int?) {
        var index = index
        if index == nil {
            index = logMessages.firstIndex { (log) -> Bool in
                return (log.userOne?.uid == user.uid && log.groupId == "")
            }
        }
        
        if let index = index {
            var logMessage = logMessages[index]
            logMessage.message = message
            self.logMessages.remove(at: index)
            self.logMessages.insert(logMessage, at: 0)
            self.tableView.reloadData()
        } else {
            print("NO INDEX")
            flaggedUids.append(user.uid)
            insertNewLog(message: message, userOne: user, userTwo: nil, groupId: nil, count: 1)
        }
        
    }
    
}

extension ChatLogController {
    
    @objc fileprivate func fetchNewLogs(onReconnect:Bool=false) {
        
        
        print("fetching new logs")
        var lastTime: Double!
        if onReconnect {
            lastTime = 0.0
        } else {
            guard let time = self.logMessages.first?.message?.actualDate else { return }
            lastTime = time
        }
        
        let params = ["lastTime": lastTime] as [String: Any]
        
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/updateMessageThreadsForUser", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    
                    guard let log = (self.logFromSnapshot(snapshot: snapshot, isPaginatingOlder: false)) else { return }
                    
                    DispatchQueue.main.async {
                        self.updateLogMessage(with: log)
                    }
                    
                })
                self.tableView.reloadData()
                
                
            } else {
                print("json had count 0")
            }
        }
        
        if let date = self.logMessages.first?.message?.sentDate {
            if Int(Date().timeIntervalSince(date)) > 60 {
                self.fetchFrequency = self.slowSpeed
            }
        } else {
            if self.fetchFrequency != self.fastSpeed {
                self.fetchFrequency = self.fastSpeed
            }
            print("no date")
        }
        
    }
    
    fileprivate func logFromSnapshot(snapshot: [String: Any], isPaginatingOlder: Bool) -> LogMessage? {
        
        var logMessage = LogMessage(dictionary: snapshot)
        let message = Message(dictionary: snapshot)
        
        logMessage.message = message
        let user = User(dictionary: snapshot)
        logMessage.userOne = user
        
        if let count = snapshot["count"] as? Int {
            logMessage.count = count
        }
        
        if let postUsername = snapshot["postUsername"] as? String {
            logMessage.postUsername = postUsername
        }
        
        if let pid = snapshot["pid"] as? Int {
            logMessage.pid = pid
        }
        
        if isPaginatingOlder {
            if snapshot["groupId"] == nil {
                if self.flaggedUids.contains(user.uid) {
                    return nil
                }
            }
        }
        
        return logMessage
    }
    
    fileprivate func updateLogMessage(with log: LogMessage) {
        
        tableView.beginUpdates()
        if log.groupId != "" {
            print("log was group")
            let i = self.logMessages.firstIndex(where: { (logMessage) -> Bool in
                return logMessage.groupId == log.groupId
            })
            if let index = i {
                
                if index == 0 {
                    self.logMessages[index] = log
                    self.tableView.reloadRows(at: [IndexPath(item: index, section: 0)], with: .none)
                } else {
                    self.logMessages.remove(at: index)
                    self.logMessages.insert(log, at: 0)
                    self.tableView.moveRow(at: IndexPath(item: index, section: 0), to: IndexPath(item: 0, section: 0))
                }
            } else {
                print("log didint exist, inserting at 0")
                self.logMessages.insert(log, at: 0)
                self.tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .top)
            }
        } else if let chatPartnerId = log.message?.chatPartnerId() {
            print("log was one to one convo")
            let i = self.logMessages.firstIndex(where: { (log) -> Bool in
                return (log.message?.chatPartnerId() == chatPartnerId) && (log.groupId == "")
            })
            
            if let index = i {
                print("log existed removed at", index, "inserted at 0")
                
                if index == 0 {
                    self.logMessages[index] = log
                    self.tableView.reloadRows(at: [IndexPath(item: index, section: 0)], with: .none)
                } else {
                    self.logMessages.remove(at: index)
                    self.logMessages.insert(log, at: 0)
                    self.tableView.moveRow(at: IndexPath(item: index, section: 0), to: IndexPath(item: 0, section: 0))
                }
            } else {
                print("didint find existing, inserting new one")
                self.logMessages.insert(log, at: 0)
                self.tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .top)
            }
        } else {
            print("something went wrong, couldint get chat partner id, reloading table view")
            self.logMessages.removeAll()
            self.isFinishedPaging = false
            self.lastIndex = 0
            self.pagainteChatLogs()
        }
        
        tableView.endUpdates()
    }
}

extension ChatLogController: RequestManagerDelegate {
    func reconnectedToInternet() {
        print("PAGINATING CHAT LOGS")
        fetchNewLogs(onReconnect: true)
        
    }
}
