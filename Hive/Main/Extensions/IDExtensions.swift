//
//  IDExtensions.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

extension Int {
    
    func fetchUser(completion: @escaping (User) -> ()) {
        let params = ["id" : self]
        RequestManager().makeJsonRequest(urlString: "/Hive/api/fetchUserWithID", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            var user = User(dictionary: json)
            
            if let status = json["status"] as? Int, let myId = MainTabBarController.currentUser?.uid {
                user.friendStatus = status.getFriendStatusFromInt(friendId: user.uid, myId: myId)
                print(user.friendStatus)
                
            } else {
                user.friendStatus = 3
            }
            
            completion(user)
            
        }
        
    }
    
    func sendFriendRequest() {
        let params = ["FID": self]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/sendFriendRequest", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("sent friend request")
            } else {
                print("failed to send friend request")
            }
        }
   
    }
    
    func acceptFriendRequest() {
        let params = ["FID": self]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/acceptFriendRequest", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("added friend")
            } else {
                print("failed to add friend")
            }
        }
    }
    
    func cancelFriendRequest() {
        let params = ["FID": self]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/cancelFriendRequest", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("cancelled friend request")
            } else {
                print("failed to cancel friend request")
            }
        }

    }
    
    func removeFriend() {
        let params = ["FID": self]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/requestFriendRemoval", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("removed friend")
            } else {
                print("Failed to remove friend")
            }
        }
    }
}
