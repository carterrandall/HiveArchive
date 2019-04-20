//
//  SettingsController.swift
//  
//
//  Created by Carter Randall on 2018-08-05.
//

import UIKit
import Alamofire

protocol SettingsControllerDelegate {
    func didMakeChangesToUser(user: User)
}

class SettingsController: UICollectionViewController, UICollectionViewDelegateFlowLayout, LogOutSettingsCellDelegate {
    
    var delegate: SettingsControllerDelegate?
    
    let cellId = "cellId"
    let locationCellId = "locationCellId"
    let notificationsCellId = "notificationsCellId"
    let myInfoCellId = "myInfoCellId"
    let tosCellId = "tosCellId"
    let blockedCellId = "blockedCellId"

    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.title = "Settings"
        
        setupCollectionView()
        setupViews()
        fetchSettings()
    }
    
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        whiteView = UIView()
        whiteView.backgroundColor = .white
        view.addSubview(whiteView)
        whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height)!)
      
    }
   
    fileprivate func setupCollectionView() {
        collectionView.backgroundColor = .white
        collectionView.register(LogOutSettingsCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(LocationSettingsCell.self, forCellWithReuseIdentifier: locationCellId)
        collectionView.register(NotificationsSettingsCell.self, forCellWithReuseIdentifier: notificationsCellId)
        collectionView.register(MyInfoSettingsCell.self, forCellWithReuseIdentifier: myInfoCellId)
        collectionView.register(BlockedCell.self, forCellWithReuseIdentifier: blockedCellId)
        collectionView.register(TosSettingsCell.self, forCellWithReuseIdentifier: tosCellId)
        collectionView.alwaysBounceVertical = true
    }
    
    fileprivate func setupViews() {
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        collectionView.addGestureRecognizer(swipeGesture)
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
        navigationController?.navigationBar.tintColor = .black
        
    }
    
    @objc func handleBack() {
        
        navigationController?.popViewController(animated: true)
    }
    
    var settings: UserSettings?
    fileprivate func fetchSettings() {
        MainTabBarController.requestManager.makeJsonRequest(urlString: "/Hive/api/fetchSettingsForUser", params: nil) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            self.settings = UserSettings(dictionary: json)
            self.collectionView.reloadData()
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 3 {
            self.openBlocked()
        } else if indexPath.item == 4 {
            self.openTOS()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.user == nil {
            return 0
        } else {
            return 6
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationCellId, for: indexPath) as! LocationSettingsCell
            cell.ghost = self.settings?.ghost
            cell.privateProfile = self.settings?.privateProfile
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: notificationsCellId, for: indexPath) as! NotificationsSettingsCell
            cell.likesNotifications = self.settings?.likeNotifications
            cell.commentsNotifications = self.settings?.commentNotifications
            cell.friendsNotifications = self.settings?.friendNotifications
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: myInfoCellId, for: indexPath) as! MyInfoSettingsCell
            cell.delegate = self
            cell.user = self.user
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: blockedCellId, for: indexPath) as! BlockedCell
            cell.delegate = self
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tosCellId, for: indexPath) as! TosSettingsCell
            cell.delegate = self
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LogOutSettingsCell
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
        switch indexPath.item {
        case 0:
            return CGSize(width: view.frame.width, height: 144)
        case 1:
            return CGSize(width: view.frame.width, height: 180)
        case 2:
            return CGSize(width: view.frame.width, height: 180)
        default:
            return CGSize(width: view.frame.width, height: 60)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func didTapLogout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            MainTabBarController.didLogout = true
            if let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/logoutUser") {
                Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.httpBody, headers: header).response(completionHandler: { (res) in
                    if let code = res.response?.statusCode {
                        print("logging out the user with a status code of \(code)")
                    }
                })
                
            }
            UserDefaults.standard.setIsLoggedIn(isLoggedIn: false, JWT: "cock", email: "andballs")
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let loginSignUpController = LoginSignUpMainController(collectionViewLayout: layout)
            UIApplication.shared.keyWindow?.rootViewController = loginSignUpController
            self.present(loginSignUpController, animated: true, completion: {
                if let annotation = MapRender.mapView.annotations{
                    MapRender.mapView.removeAnnotations(annotation)
                }
                let camera = MapRender.mapView.camera
                camera.pitch = 0
                MapRender.mapView.setCamera(camera, animated: false)
                MapRender.profileCache.removeObject(forKey: "CachedProfile")
                MapRender.currentHiveInfo = []
                messageCache.removeAllObjects()
                postCache.removeAllObjects()
                chatLogCache.removeAllObjects()
            })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    internal func openTOS() {
        let tosController = TermsOfServiceController()
        tosController.wasPushed = true
        self.navigationController?.pushViewController(tosController, animated: true)
    }

}

extension SettingsController: MyInfoSettingsCellDelegate, EditNameControllerDelegate, BlockedCellDelegate, TosSettingsCellDelegate {
    
    func openTOScell() {
        openTOS()
    }

    func didClickEditPassword() {
        let passwordController = PasswordController()
        navigationController?.pushViewController(passwordController, animated: true)
    }
    
    func didClickEdit(editing: String) {
        
        let editNameController = EditNameController()
        editNameController.delegate = self
        editNameController.editingProperty = editing
        if editing == "username" {
            editNameController.placeholderText = self.user?.username
        } else {
            editNameController.placeholderText = self.user?.fullName
        }
        editNameController.uid = self.user?.uid
        navigationController?.pushViewController(editNameController, animated: true)
        
    }
    
    func didMakeChanges(editingProperty: String, editedString: String) {
        guard var user = self.user else { return }
        if editingProperty == "username" {
            user.username = editedString
            MainTabBarController.currentUser?.username = editedString
        } else {
            user.fullName = editedString
            MainTabBarController.currentUser?.fullName = editedString
        }
        
        self.user = user
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        self.delegate?.didMakeChangesToUser(user: user)
        
        
    }
    
    func openBlocked() { //probably dont need this delegate here as is handled in did select item at but make sure button is diabled or something
        let blockedUsersController = BlockedUsersController()
        navigationController?.pushViewController(blockedUsersController, animated: true)
    }
    
}

