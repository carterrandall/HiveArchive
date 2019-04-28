import UIKit
import Mapbox

class friendMGLAnnotation: NSObject, MGLAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var username: String
    var image: UIImage?
    var profileImageUrl: URL
    var reuseIdentifier: String?
    var id : Int
    var hiveName: String?
    var unreadMessage: Bool
    
    init(coordinate: CLLocationCoordinate2D, username: String, profileImageUrl: URL, FUID: Int, hiveName: String?,unreadMessage: Bool) {
        self.coordinate = coordinate
        self.title = username
        self.username = username
        self.id = FUID
        self.profileImageUrl = profileImageUrl
        self.reuseIdentifier = "\(FUID)-friend"
        self.hiveName = hiveName
        self.unreadMessage = unreadMessage
    }
}

