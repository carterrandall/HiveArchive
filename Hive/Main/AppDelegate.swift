
import UIKit

import AVFoundation
import Alamofire
import UserNotifications

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.setDeviceToken(token: deviceToken.reduce("", {$0 + String(format: "%02X", $1)}))
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
 
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        
        print("got a notificaiton")
        print(userInfo)
    }
    
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        //prevent audio from being paused
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isOtherAudioPlaying { 
            _ = try? audioSession.setCategory(AVAudioSession.Category.ambient, mode: .default, options: [.mixWithOthers])
            _ = try? audioSession.setActive(true, options: [])
        }
        
        window = UIWindow()
        window?.backgroundColor = .white
        window?.rootViewController = MainTabBarController()
        
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ChatLogController.messageLogUpdateTimer.invalidate()
        ChatController.chatUpdateTimer.invalidate()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func handleOpenApp() {
        if UserDefaults.standard.isLoggedIn(), let header = UserDefaults.standard.getAuthorizationHeader(), let date = UserDefaults.standard.getDate(), let url = URL(string: MainTabBarController.serverurl+"/Hive/api/refreshJWT"){
            // new little bit for the location thing.
            // This seems to work just fine now
            MapRender.mapView.showsUserLocation = true
            if let _ = MainTabBarController.currentUser?.HID{
                
            }else{
                MapRender.mapView.setUserTrackingMode(.follow, animated: true)
            }
            // move the mapview shows user locaiton in here
            
            NotificationCenter.default.post(name: MapRender.didEnterForegroundForMapNotificationName, object: nil) // new notification thing that handles this function call, could also probably move the below into it, but does not really matter at this point.
            if (NSDate().timeIntervalSince1970 - date > 4*60*60) {
                Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
                    if let json = data.result.value as? [String:Any], let JWT = json["JWT"] as? String{
                        print("gettingn the toke")
                        UserDefaults.standard.setJWTtoken(JWT: JWT)
                    }else{
                        if let status = data.response?.statusCode{
                            if (status == 500){
                                print("internal server error, hive/api/refreshjwt")
                                // this is an internal server error, which is a strange problem for sure.
                            }
                            if (status == 401){
                                // user is invalidated, or there is something wrong with my renewal code, but probably invalidated, since I don't make mistakes,
                                if let rootViewController = UIApplication.topViewController() {
                                    MainTabBarController.didLogout = true
                                    UserDefaults.standard.setIsLoggedIn(isLoggedIn: false, JWT: "cock", email: "andballs")
                                    let layout = UICollectionViewFlowLayout()
                                    layout.scrollDirection = .horizontal
                                    let loginSignUpController = LoginSignUpMainController(collectionViewLayout: layout)
                                    UIApplication.shared.keyWindow?.rootViewController = loginSignUpController
                                    rootViewController.present(loginSignUpController, animated: true, completion: {
                                        if let annotation = MapRender.mapView.annotations{
                                            MapRender.mapView.removeAnnotations(annotation)
                                        }
                                        let camera = MapRender.mapView.camera
                                        camera.pitch = 0
                                        MapRender.mapView.setCamera(camera, animated: false)
                                        MapRender.profileCache.removeObject(forKey: "CachedProfile")
                                        messageCache.removeAllObjects()
                                        postCache.removeAllObjects()
                                    })
                                    
                                    //do sth with root view controller
                                }
                                if Connectivity.isConnectedToInternet {
                                    print("have internet, so good here")
                                }else{
                                    print("something here to do with connectivity -- could hancle here or pickup using the functions specific to the view controllers.")
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        handleOpenApp()
    }

    static var BecameActive: Bool = false
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AppDelegate.BecameActive = true
        
        let topViewController = UIApplication.topViewController()
        topViewController?.viewWillAppear(false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppDelegate.BecameActive = false
        }
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}
