
import UIKit
import CoreLocation

struct KeyChainConfig {
    static let accessGroup : String? = nil
    static let serviceName = "TouchMeIn"
}

struct HiveJson {
    let id: Int
    let name: String
    let url: URL
    let heat: CGFloat
    let center: CLLocation
    let distance: Double
    let inHiveRange: Bool
    let radius: Double
    let range: Double
    let key : String
    let previewImageUrl : URL?
    // heat map URL as well, needs to be added in server side.
    
    init(json: [String: Any], userLocation: CLLocation?, jsonUrl: URL) {
        self.key = json["identifier"] as? String ?? ""
        self.id = json["id"] as? Int ?? 0
        self.radius = json["radius"] as? Double ?? 0.0
        self.name = json["name"] as? String ?? ""
        let lat = json["latitude"] as? Double ?? 0.0
        let lon = json["longitude"] as? Double ?? 0.0
        self.center = CLLocation(latitude: lat, longitude: lon)
        self.url = jsonUrl
        var heat = json["heat"] as? CGFloat ?? 0.1
        if heat < 0.1 {
            heat = 0.1
        }
        self.heat = heat
        if let location = userLocation {
            self.distance = self.center.distance(from: location)
            self.range = self.radius*1000 - self.distance // positive if in hive range, negative if not in hive range
            self.inHiveRange = (self.range >= 0)
        }else{
            self.inHiveRange = false
            self.distance = 0
            self.range = -1.0
        }
        if let stringurl = json["previewImageUrl"] as? String  {
            self.previewImageUrl = URL(string: stringurl)
        }else{
            self.previewImageUrl = nil
        }
    }
}

struct HiveData {
    let id: Int
    let name : String
    
    //    let subtitle: String // Don't seem to need a subtitle
    let center: CLLocation // make center later
    let heat: CGFloat       // Corresponds to the color alpha value
    let radius: Double
    
    let url: String        // Download URL for the geojson file.
    let purl : URL // Delete above url when done.
    var distance: Double // Distance to user, for checking if the user is in hive range.
    var inHiveRange: Bool // true if the user is in the hive range.
    var heatMapUrl : URL?
    let range : Double
    let key: String
    let previewImageUrl: URL?
    // Added in a top post array to attach to each hive, for the rolodex and previews.
    // Dont want to add duplicates in here, so make sure we don't do that, coult make it a dict
    init(json: HiveJson) {
        self.key = json.key.replacingOccurrences(of: ".geojson", with: "")
        self.id = json.id
        self.name = json.name
        self.center = json.center // Make this center later
        self.purl = json.url
        self.url = json.url.absoluteString // Remove this later
        //        self.heat = json.heat
        self.heat = 0.3
        self.inHiveRange = json.inHiveRange
        self.distance = json.distance
        self.range = json.range
        self.radius = json.radius
        self.previewImageUrl = json.previewImageUrl
    }
}

struct User {
    
    var uid: Int
    var fullName: String
    var username: String
    var profileImageUrl: URL
    var friends: Int
    var postcount: Int
    var HID: Int?
    var friendStatus: Int = 3
    var hiveName: String?
    var requestCreationDate: Double?
    var sharingLocation: Bool?
    
    init(dictionary: [String: Any]) {
        
        self.uid = dictionary["id"] as? Int ?? 0
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        
        let urlString = dictionary["profileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
        
        if let notsharingLocation = dictionary["notSharingLocation"] as? Bool {
            self.sharingLocation = !notsharingLocation
        }
    
        self.HID = dictionary["hid"] as? Int ?? nil
        self.friends = dictionary["friends"] as? Int ?? 0
        self.postcount = dictionary["posts"] as? Int ?? 0
        self.hiveName = dictionary["hiveName"] as? String ?? nil
    }
    
    init(postdictionary : [String:Any]) {
        self.uid = postdictionary["userid"] as? Int ?? 103
        self.fullName = postdictionary["userfullName"] as? String ?? ""
        self.username = postdictionary["userusername"] as? String ?? ""
        let urlString = postdictionary["userprofileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!//fix bang here later
        self.HID = postdictionary["userHID"] as? Int ?? nil
        self.friends = postdictionary["userfriends"] as? Int ?? 0
        self.postcount = postdictionary["userposts"] as? Int ?? 0
    }
}

struct BlockedUser {
    
    let username: String
    let id: Int
    init(dictionary: [String: Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.id = dictionary["id"] as? Int ?? 0
    }
    
}

struct Friend {
    
    let uid: Int
    let fullName: String
    let username: String
    let profileImageUrl: URL
    var friendStatus: Int = 0
    
    init(uid: Int, dictionary: [String: Any]) {
        self.uid = uid
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        
        let urlString = dictionary["profileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)! //fix bang here later
    }
}

struct Post {
    
    var id: Int
    var hasLiked: Bool
    var user: User?
    var isPinned: Bool = false
    var comments : Int?
    let imageUrl: URL
    let creationDate: Date
    let uid: Int
    let videoUrl: URL?
    let hiveName: String?
    var seen: Bool? //used for header
    var expired: Bool?
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? Int ?? 0
        let urlString = dictionary["imageUrl"] as? String ?? ""
        self.imageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)! //fix bang here later
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        let videoUrlString = dictionary["videoUrl"] as? String ?? ""
        self.videoUrl = URL(string: videoUrlString) ?? nil //fix bang here later //we should make convinience method for these stirng to urls
        self.uid = dictionary["uid"] as? Int ?? 0
        self.isPinned = dictionary["isPinned"] as? Bool ?? false
        self.hiveName = dictionary["hiveName"] as? String ?? ""

        self.comments = dictionary["comments"] as? Int ?? 0
        self.hasLiked = dictionary["status"] as? Bool ?? false

    }
}

struct Story {
    var user: User
    var posts: [Post]
    var hasSeenAllPosts: Bool = true
    var firstUnseenPostIndex: Int?
    
    init(user: User, posts: [Post]) {
        self.user = user
        self.posts = posts
    }
}

struct Comment {
    
    let user: User
    let text: String
    let uid: Int
    let creationDate: Date
    var commentId: Int
    let pid : Int
    
    init(user: User, dictionary: [String: Any]) {
        self.commentId = dictionary["commentId"] as? Int ?? 0
        self.user = user
        self.pid = dictionary["pid"] as? Int ?? 0
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? Int ?? 0
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)

    }
}

struct LogMessage {
    
    var message: Message?

    var seen: Bool
    
    let groupId: String
    let secondId: Int
    let secondusername: String
  
    let secondprofileImageUrl: URL
    
    var userOne: User?
    var count: Int? //isGroup
    var postUsername: String?
    var pid: Int?

    
    init(dictionary: [String: Any]) {
        
        self.groupId = dictionary["groupId"] as? String ?? ""
        self.secondId = dictionary["secondId"] as? Int ?? 0
        self.secondusername = dictionary["secondusername"] as? String ?? ""
        let urlString = dictionary["secondprofileImageUrl"] as? String ?? ""
        self.secondprofileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
        self.seen = dictionary["seen"] as? Bool ?? false
    }
}

struct FromUser {
    
    let username: String
    let fullName: String
    let profileImageUrl: URL
    let id: Int
    
    init(dictionary: [String: Any]) {
        self.username = dictionary["fromusername"] as? String ?? ""
        self.fullName = dictionary["fromfullName"] as? String ?? ""
        let urlString = dictionary["fromprofileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
        self.id = dictionary["fromId"] as? Int ?? 0
    }
    
}

struct UserSettings {
    var ghost: Bool
    let commentNotifications: Bool
    let likeNotifications: Bool
    let friendNotifications: Bool
    let privateProfile: Bool
    
    init(dictionary: [String: Any]) {
        let ghostInt = dictionary["ghost"] as? Int ?? 1
        self.ghost = (ghostInt == 1 ? true : false)
        let commentNotificationInt = dictionary["commentNotifications"] as? Int ?? 0
        self.commentNotifications = (commentNotificationInt == 1 ? true : false)
        let likesNotificationsInt = dictionary["likeNotifications"] as? Int ?? 0
        self.likeNotifications = (likesNotificationsInt == 1 ? true : false)
        let friendsNotificationsInt = dictionary["friendNotifications"] as? Int ?? 0
        self.friendNotifications = (friendsNotificationsInt == 1 ? true : false)
        let privateProfileInt = dictionary["privateProfile"] as? Int ?? 0
        self.privateProfile = (privateProfileInt == 1 ? true : false)
    }
}

struct Group {
    let id: String
    let count: Int
    let uid: Int
    let username: String
    let profileImageUrl: URL
    let secondUid: Int
    let secondUsername: String
    let secondProfileImageUrl: URL
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["groupId"] as? String ?? ""
        self.count = dictionary["count"] as? Int ?? 2
        self.uid = dictionary["id"] as? Int ?? 0
        self.username = dictionary["username"] as? String ?? ""
        let urlString = dictionary["profileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
        self.secondUid = dictionary["secondId"] as? Int ?? 0
        self.secondUsername = dictionary["secondusername"] as? String ?? ""
        let urlStringTwo = dictionary["secondprofileImageUrl"] as? String ?? ""
        self.secondProfileImageUrl = URL(string: urlStringTwo) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
    }
}

struct Message {
    
    let text: String?
    let toId: Int
    let fromId: Int
    let sentDate: Date
    var daysAgo: Int
    let id: Int
    var actualDate: Double
    var seen: Date?
    var post: Post?
    
    var isIncoming: Bool?
    var fromUser: FromUser?
    var postDeleted: Int?
    var isNotice: Int?
    
    var isTypingIndicator: Bool?
    
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.toId = dictionary["toId"] as? Int ?? 0
        self.fromId = dictionary["fromId"] as? Int ?? 0
        self.id = dictionary["mid"] as? Int ?? 0
        let secondsFrom1970 = dictionary["sentDate"] as? Double ?? 0
        let date = Date(timeIntervalSince1970: secondsFrom1970)
        self.actualDate = secondsFrom1970
        self.daysAgo = Int(Date().timeIntervalSince(date)) / 86400
        self.sentDate = date
        
        if let seenSecondsFrom1970 = dictionary["seen"] as? Double {
            self.seen = Date(timeIntervalSince1970: seenSecondsFrom1970)
        } else {
            self.seen = nil
        }
        
    }
    
    func chatPartnerId() -> Int? {
        return fromId == MainTabBarController.currentUser?.uid ? toId : fromId
    }
    
}

struct HiveNotification {
    
    let uid: Int
    let creationDate: Date
    let message: String
    
    let type: Int
    let username: String
    let fullName: String
    let profileImageUrl: URL
    let seen: Bool

    var post: Post?
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary["uid"] as? Int ?? 0
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.message = dictionary["text"] as? String ?? ""
        self.type = dictionary["type"] as? Int ?? 0
        self.username = dictionary["username"] as? String ?? ""
        self.fullName = dictionary["fullName"] as? String ?? ""
        let urlString = dictionary["profileImageUrl"] as? String ?? ""
        self.profileImageUrl = URL(string: urlString) ?? URL(string: MainTabBarController.defualtProfileImageUrl)!
        let seenInt = dictionary["seen"] as? Int ?? 0
        self.seen = (seenInt == 1 ? true : false)
    }
}
