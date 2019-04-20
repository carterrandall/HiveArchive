//
//  MainTabBarController.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-24.
//  Copyright © 2018 Carter Randall. All rights reserved.
//fasdfasdf

import UIKit
import Alamofire
import AVFoundation
import UserNotifications
let messageCache = NSCache<AnyObject, AnyObject>()
let chatLogCache = NSCache<AnyObject, AnyObject>()
let postCache = NSCache<AnyObject, AnyObject>() //id: Post

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    static var currentUser : User?
  //  static let serverurl = "https://hiveproduction.appspot.com"
    static let defualtProfileImageUrl = "https://storage.googleapis.com/hive_productionbucket/defaultimage3lowsize.png"
    
    
    static let serverurl = "https://hivebuild-c7559.appspot.com"
//    static let serverurl = "http://192.168.2.26:8080"
    static var didLogout = false
    static let requestManager = RequestManager()
    var connectivityPage: ConnectivityPage!
    fileprivate func getCurrentUser(isRetrying: Bool = false) {
        guard let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/fetchCurrentUserInformation") else {print("shit url");return}
        var params = [String:Any]()
        if let notificationToken = UserDefaults.standard.getDeviceToken(), notificationToken != "nil" {
            params["token"] = notificationToken
        }
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
            if let response = data.result.value as? [String:Any], let json = response["json"] as? [String:Any], let jwt = response["token"] as? String {
                UserDefaults.standard.setJWTtoken(JWT: jwt)
                MainTabBarController.currentUser = User(dictionary: json)
                self.setupViewControllers()
                if isRetrying {
                    self.connectivityPage.dismiss(animated: true, completion: nil)
                }
            }else{
                
                if !isRetrying {
                    if (Connectivity.isConnectedToInternet){
                        self.presentLoginSignUp()
                    }else {
                        //present splash page, and put a timeer on check if user is logged in.
                        print("get current user not connected to internet")
                        self.connectivityPage = ConnectivityPage()
                        self.connectivityPage.delegate = self
                        self.present(self.connectivityPage, animated: true, completion: nil)
                    }
                } else {
                    print("user is connected to internet but something went wrong, server error")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        view.backgroundColor = .white
        self.tabBar.barTintColor = UIColor.white.withAlphaComponent(0.8)
        self.tabBar.layer.borderWidth = 0.0
        self.tabBar.clipsToBounds = true
        
       // self.tabBar.shadowImage = UIImage()//UIImage.imageWithColor(color: UIColor(white: 0, alpha: 0.00))
        checkIfUserIsLoggedIn()

    }
    
    
    
    func configureNotification() {
        if #available(iOS 12, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound, .provisional, .providesAppNotificationSettings, .criticalAlert]){ (granted, error) in
                if (granted) {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }else{
                    print(error as Any)
                }
            }
        }
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound, .provisional, .providesAppNotificationSettings, .criticalAlert]){ (granted, error) in
                if (granted){
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    
    override func viewWillLayoutSubviews() {
            var tabBarFrame = self.tabBar.frame
            tabBarFrame.size.height = tabBarFrame.size.height - 8
            tabBarFrame.origin.y += 8
            self.tabBar.frame = tabBarFrame
    }
    
    fileprivate func checkIfUserIsLoggedIn() {
        if UserDefaults.standard.isLoggedIn(), let email = UserDefaults.standard.getEmail(), let date = UserDefaults.standard.getDate(), let _ = UserDefaults.standard.getAuthorizationHeader() { // Get username and password and get a key.
            if NSDate().timeIntervalSince1970 - date > 47*60*60 { //6*60*60
                do{
                    print("doing")
                    let passwordItem = KeychainPasswordItem(service: KeyChainConfig.serviceName,account: email,accessGroup: KeyChainConfig.accessGroup)
                    let password = try passwordItem.readPassword()
                    generateJWT(email: email, password: password)
                }catch{
                    print("catch-do something with the error. ")
                    UserDefaults.standard.setIsLoggedIn(isLoggedIn: false, JWT: nil, email: nil)
                    presentLoginSignUp()
                }
            }else{
                print("token is still valid for a while")
                // good for just off of login, so we don't generate an extra toke, setup with a flag.
                getCurrentUser()
            }
        }else{
            print("not logged in")
            presentLoginSignUp()
        }
    }
    
    fileprivate func presentLoginSignUp() {
        UserDefaults.standard.setIsLoggedIn(isLoggedIn: false, JWT: "nothing", email: "air")
        DispatchQueue.main.async {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let loginSignUpController = LoginSignUpMainController(collectionViewLayout: layout)
            self.present(loginSignUpController, animated: true, completion: nil)
        }
    }
    
    func generateJWT(email:String, password:String){
        print("in the new generate jwt token right now.")
        print(email, password)
        let params = ["credentials":email, "password": password]
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/generateJWTtoken") else {presentLoginSignUp(); return}
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil).responseJSON { (data) in
            if let json = data.result.value as? [String:Any]{
                if let success = json["success"] as? Bool, success == true, let token = json["token"] as? String, let userjson = json["user"] as? [String:Any]{
                    UserDefaults.standard.setIsLoggedIn(isLoggedIn: true, JWT: token, email: email)
                    MainTabBarController.currentUser = User(dictionary: userjson)
                    self.setupViewControllers()
                }else{
                    print("success was false")
                    self.presentLoginSignUp()
                }
            }else{
                if (Connectivity.isConnectedToInternet){
                    self.presentLoginSignUp()
                    print("enerate JWT connected to internat")
                }else{
                    
                    print("generate JWT not connected to internet")
                }
                print("dead json in geneate jwt")
                
                //
            }
        }
    }
    
    var feedMainController: FeedMainController!
    var mapRender: MapRender!
    func setupViewControllers() {
        mapRender = MapRender()
        let homeNavController = templateNavController(unselectedImage: UIImage(named: "map")!, selectedImage: UIImage(named: "map")!, rootViewController: mapRender)
        
        let cameraController = templateNavController(unselectedImage: UIImage(named: "camera")!, selectedImage: UIImage(named: "camera")!)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        feedMainController = FeedMainController(collectionViewLayout: layout)
        let feedNavController = templateNavController(unselectedImage: UIImage(named: "feed_selected")!, selectedImage: UIImage(named: "feed_selected")!, rootViewController: feedMainController)
        
        tabBar.tintColor = .mainRed()
        tabBar.unselectedItemTintColor = .black
    
        viewControllers = [homeNavController, cameraController, feedNavController]
        
        guard let items = tabBar.items else { return }
        
        for item in items {
            item.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        }
        
        configureNotification()
        
        
    }
    
    fileprivate func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let viewController = rootViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        return navController
    }

    var isMapSelected: Bool = true
    var hasSelectedFeed: Bool = false
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.firstIndex(of: viewController)
        
        if index == 0  {
            if hasSelectedFeed {
                feedMainController.endVideosInChildCells()
            }
            
            if isMapSelected {
                MapRender.toCurrentLocation()
                return true
            }
            else {
                isMapSelected = true
                return true
            }
        }
        
        if index == 2 {
            mapRender.endVideosInPreview()
            isMapSelected = false
            hasSelectedFeed = true
        }
        
        if index == 1 {
            presentCamera(selectedIndex: tabBarController.selectedIndex)
            
            return false
        }
        
        return true
        
    }
    
    func presentCamera(selectedIndex: Int) {
        if selectedIndex == 0 {
            mapRender.endVideosInPreview()
        } else {
            feedMainController.endVideosInChildCells()
        }
        
        isMapSelected = false
        
        checkVideoAndMicAuthStatus { (videoResult, micResult) in
            if videoResult && micResult {
                DispatchQueue.main.async {
                    let cameraController = HiveCameraController()
                    let navController = UINavigationController(rootViewController: cameraController)
                    self.present(navController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    let permissionsViewController = PermissionsViewController()
                    permissionsViewController.isCameraEnabled = videoResult
                    permissionsViewController.isMicrophoneEnabled = micResult
                    let permissionsNavController = UINavigationController(rootViewController: permissionsViewController)
                    self.present(permissionsNavController, animated: true, completion: nil)
                }
                
            }
        }
    }
    
    fileprivate func checkVideoAndMicAuthStatus(completion: @escaping(Bool, Bool) -> ()) {
        var videoResult: Bool = false
        var micResult: Bool = false
        
        checkVideoAuthStatus { (vResult) in
            videoResult = vResult
            self.checkMicAuthStatus(completion: { (mResult) in
                micResult = mResult
                completion(videoResult, micResult)
            })
        }
        
    }
    
    fileprivate func checkVideoAuthStatus(completion: @escaping(Bool) -> ()){
        
        var videoResult: Bool = false
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            videoResult = true
            completion(videoResult)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if !granted {
                    videoResult = false
                } else {
                    videoResult = true
                }
                completion(videoResult)

            }
        case .denied:
            videoResult = false
            completion(videoResult)
        case .restricted:
            videoResult = false
            completion(videoResult)
        }
        
    }
    
    fileprivate func checkMicAuthStatus(completion: @escaping(Bool) -> ()){
        
        var microphoneResult: Bool = false
        
        switch AVAudioSession.sharedInstance().recordPermission {
            
        case .granted:
            microphoneResult = true
            print("Permission granted")
            completion(microphoneResult)
            break
            
        case .denied:
            microphoneResult = false
            print("Pemission denied")
            completion(microphoneResult)
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                if granted {
                    microphoneResult = true
                } else {
                    microphoneResult = false
                }
                completion(microphoneResult)
            }
            print("Request permission here")
        default:
            break
        }
        
    }
    
}

extension MainTabBarController: ConnectivityPageDelegate {
    func retryInternet() {
        self.getCurrentUser(isRetrying: true)
    }
}
