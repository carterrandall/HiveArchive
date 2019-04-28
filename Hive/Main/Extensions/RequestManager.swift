//
//  AlamofireExtensions.swift
//  Hive
//
//  Created by Carter Randall on 2019-03-14.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import Alamofire
import UIKit

protocol RequestManagerDelegate {
    func reconnectedToInternet() //do stuff like call reload feed etc.
}

class RequestManager {
    
    enum ConnectivityState {
        case connected, disconnected
    }
    
    var connectivityPage: ConnectivityPage!
    var currentState: ConnectivityState = .connected
    
    var delegate: RequestManagerDelegate?
    
    func getJsonRequest(urlString: String, params:[String: Any]?, completion: @escaping([String: Any]) -> ()) {
        if let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + urlString) {
            Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
                if let messages = data.result.value as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(messages)
                    }
                }
            }
        }
        
    }
    
    
    
    
    func makeResponseRequest(urlString: String, params: [String: Any]?, completion: @escaping(DefaultDataResponse) -> ()) {
        print("making request: ",urlString)
        if self.currentState == .disconnected || UIApplication.shared.keyWindow?.rootViewController is LoginSignUpMainController {print("disconnected, return"); return }
        if (UserDefaults.standard.isLoggedIn()), let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + urlString) {
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: header).response { (response) in
                DispatchQueue.main.async {
                    completion(response)
                }
            }
        }
    }
    
    func makeJsonRequest(urlString: String, params: [String: Any]?, completion: @escaping(Any, Int?) -> ()) {
        print("making request: ",urlString)
        if self.currentState == .disconnected || UIApplication.shared.keyWindow?.rootViewController is LoginSignUpMainController {print("disconnected, return"); return }
        if (UserDefaults.standard.isLoggedIn()),let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + urlString) {
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
                if let json = data.result.value as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(json, data.response?.statusCode)
                    }
                    
                    self.handleReconnectedToInternet()
                    
                } else if let json = data.result.value as? [[String: Any]] {
                    DispatchQueue.main.async {
                        completion(json, data.response?.statusCode)
                    }
                } else {
                    //bad json
                    print("bad json", data.result.value as Any)
                    self.checkConnectivityHandleErrors(response: data.response)
                }
                
            }
        } else {
            //bad header or url
            self.logoutandpresentLoginSignUp()
        }
    }
    func checkConnectivityHandleErrors(response: HTTPURLResponse?) { // also could use this place to handle errors.
        // check for a code first:
        if let code = response?.statusCode { // This implies internet connectivity, so use else block.
            if code == 200 {
                // no error.
                return
            } else if code == 401 {
                print("401 unauthorized called, checking header now")
                checkAndUpdateToken() // This is the function that checks things.
            } else if code == 500 {
                print("status code 500 in checkconnectivity handle errors, Alex figure your shit out.", response as Any)
                return
            }
        }else{
            if !Connectivity.isConnectedToInternet {
                handleNoInternet()
                print("Not connected to internet, display appropriate thing to keep things stable.")
            }
        }
    }
    
    fileprivate func handleNoInternet() {
        if self.currentState == .connected && !(UIApplication.topViewController() is ConnectivityPage) {
            print("setting to disconnected")
            self.currentState = .disconnected
            self.connectivityPage = ConnectivityPage()
            connectivityPage.delegate = self
            UIApplication.topViewController()?.present(connectivityPage, animated: true, completion: nil)
        }
    }
    
    func checkAndUpdateToken() {
        if let header = UserDefaults.standard.getAuthorizationHeader(), let date = UserDefaults.standard.getDate() {
            if (NSDate().timeIntervalSince1970 - date > 604800){ // 7 days in seconds
                // lets get them a new header
                attemptHeaderReset(oldHeader: header)
            }else{
                quickCheckHeader(header: header)
            }
        }else{
            // logout the user.
            self.logoutandpresentLoginSignUp()
        }
    }
    
    func quickCheckHeader(header:[String:String]) {
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/quickCheckJWT") else {return}
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.httpBody, headers: header).response { (res) in
            if let status = res.response?.statusCode {
                if status == 401 {
                    // this is a weird situation, where the token is invalid, but seems to be valid device side,
                    self.attemptHeaderReset(oldHeader: header)
                }else if status == 200{
                    // header is good, must be another param
                    print("Got 401 status code, header is valid, so must be another param")
                    return
                }else{
                    print("quick check header status is fucked",status)
                   
                    self.logoutandpresentLoginSignUp()
                }
            }else{
                if (!Connectivity.isConnectedToInternet){
                    self.handleNoInternet()
                }else{
                    print("connected to internet, but no status code, something is fucked I tell ya.")
                }
            }
        }
    }
    
    func attemptHeaderReset(oldHeader: [String:String]) {
        if let id = MainTabBarController.currentUser?.uid, let email = UserDefaults.standard.getEmail() {
            do{
                let passwordItem = KeychainPasswordItem(service: KeyChainConfig.serviceName,account: email,accessGroup: KeyChainConfig.accessGroup)
                let password = try passwordItem.readPassword()
                // This is where we can call a generating extension on UserDefaults.
                // say generateNewJWT(oldHeader, email, password)
                regenerateJWT(oldHeader: oldHeader, pass: password, id: id, email: email)
                //                UserDefaults.standard.regenerateJWT(oldHeader: oldHeader, pass: password, id: id, email: email)
            }catch{
                logoutandpresentLoginSignUp()
            }
        }else{
            // no current user, logout and present login sign up.
            logoutandpresentLoginSignUp()
        }
    }
    
    func regenerateJWT(oldHeader: [String:String], pass: String, id: Int, email:String) { // note that email may be a phone number as well.
        if let url = URL(string: MainTabBarController.serverurl + "/Hive/api/regenerateJWT"){
            let params = ["id": id, "password": pass, "credentials": email] as [String : Any]
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: oldHeader).responseJSON { (data) in
                if let json = data.result.value as? [String: Any] {
                    if let _ = json["error"] as? Int {
                        // log the user out, note that error codes [1,2,3] = [ids dont mathc, passwords dont match, credentials dont match.]
                        // logout the user here.
                        self.logoutandpresentLoginSignUp()
                    } else if let token = json["token"] as? String {
                        UserDefaults.standard.setIsLoggedIn(isLoggedIn: true, JWT: "JWT "+token, email: email)
                    }
                } else {
                    if (!Connectivity.isConnectedToInternet){
                        self.handleNoInternet()
                    } else {
                        print("no response, but connected to internet, something is fucked")
                    }
                }
            }
        }else{
            // url error, shouldn't really ever occur, but keep track of it.
            print("url error regenerateJWT")
        }
    }
    
    fileprivate func logoutandpresentLoginSignUp() {
        // this should be a complete logout function.
        // could also clear the keychain, although not that importnat.
        // Check with carter if DispatchQueue.main.async is even needed here, as it is not used in the settings thing.
        print("LOGGING OUT -----------------------------")
        DispatchQueue.main.async {
            MainTabBarController.didLogout = true
            UserDefaults.standard.setIsLoggedIn(isLoggedIn: false, JWT: "cock", email: "andballs")
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let loginSignUpController = LoginSignUpMainController(collectionViewLayout: layout)
            UIApplication.topViewController()?.present(loginSignUpController, animated: true, completion: {
                UIApplication.shared.keyWindow?.rootViewController = loginSignUpController
                if let annotation = MapRender.mapView.annotations{
                    MapRender.mapView.removeAnnotations(annotation)
                }
                let camera = MapRender.mapView.camera
                camera.pitch = 0
                MapRender.mapView.setCamera(camera, animated: false)
                MapRender.profileCache.removeObject(forKey: "CachedProfile")
                messageCache.removeAllObjects()
                postCache.removeAllObjects()
                chatLogCache.removeAllObjects()
            })
        }
    }
    
    fileprivate func handleReconnectedToInternet() {
        if (Connectivity.isConnectedToInternet){ // if is connected to internet and internet displays are up, then remove them (add an && check if possible - depending on structure.)
            print("CURRENT STATE", self.currentState)
            if self.currentState == .disconnected {
                self.currentState = .connected
                self.connectivityPage.dismiss(animated: true, completion: nil)
                DispatchQueue.main.async {
                    self.delegate?.reconnectedToInternet()
                    self.delegate = nil
                }
               
            }
            
        } else {
            // leave the no internet views up.
        }
    }
    
}

extension RequestManager: ConnectivityPageDelegate {
    func retryInternet() {
        print("RETRY RETRY RETRY")
        self.handleReconnectedToInternet()
    }
}


