
import UIKit
import AVFoundation
import CoreLocation

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return topViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}


extension UserDefaults { // Set logged in, JWT, email in one go, consider loggin in via username
    func setIsLoggedIn(isLoggedIn: Bool, JWT: String?, email: String?) {
        set(isLoggedIn, forKey: "isLoggedIn")
        set(JWT, forKey: "JWT")
        set(email, forKey: "email")
        set(NSDate().timeIntervalSince1970, forKey: "date")
        let header = ["Authorization": JWT]
        set(header, forKey: "AuthorizationHeader")
        synchronize()
    }
    func setJWTtoken(JWT: String){
        set(JWT, forKey: "JWT") // might be able to get rid of this
        set(NSDate().timeIntervalSince1970, forKey: "date")
        let header = ["Authorization": JWT]
        set(header, forKey: "AuthorizationHeader")
        synchronize()
    }
    func getDate() -> Double? {
        return double(forKey: "date")
    }
    
    func isLoggedIn() -> Bool {
        return bool(forKey: "isLoggedIn")
    }
    func getEmail() -> String?{
        return string(forKey: "email")
    }
    func getJWT() -> String?{
        return string(forKey: "JWT")
    }
    func setDeviceToken(token: String) {
        set(token, forKey: "deviceToken")
        synchronize()
    }
    func getDeviceToken() -> String? {
        return string(forKey: "deviceToken")
    }
    
    func getAuthorizationHeader() -> [String:String]? {
        if let header = dictionary(forKey: "AuthorizationHeader") as? [String:String]{
            return header
        }
        else{
            if let jwt = getJWT() {
                let header = ["Authorization":jwt]
                return header
            }else{
                return nil
            }
        }
    }
}

extension Double {   // miles in the US & A -- this seems to work fairly reasonably now.
    func metricformat() -> String {
        // self is the distance is meters.
        if let country = NSLocale.current.regionCode, country == "US" {
            //            let yards = self*1.09361
            let feet = self * 3.28084
            if feet < 1000 {
                return "\(Int(feet.rounded())) yd"
            }else{
                let miles = self*0.000621371*10
                return "\((miles).rounded()/10) mi"
            }
            
        }
        if self < 1000 {
            return "\(Int(self.rounded())) m"
        }
        else {
            if self > 100*1000{
                return "\(Int((self/1000).rounded())) km"
            }else{
                return "\((self/100.0).rounded()/10) km"
            }
            
        }
    }
}

extension UIColor {
    static func heatColor(rank: Int, outOf: Int) -> UIColor{
        var denom = outOf
        if (denom == 0){
            denom = 1
        }
        var alpha = 0.15 + 0.2 * (1.0-(CGFloat(rank + 1)/CGFloat(denom)))
        if (alpha > 0.22){
            alpha = 0.22
        }
        if (alpha < 0.15){
            alpha = 0.15
        }
        return UIColor.red.withAlphaComponent(alpha)
    }
    
    static func blueHeatColor(rank : Int, outOf : Int) -> UIColor{
        var denom = outOf
        if (denom == 0){
            denom = 1
        }
        var alpha = 0.15 + 0.2 * (1.0-(CGFloat(rank + 1)/CGFloat(denom)))
        if (alpha > 0.22){
            alpha = 0.22
        }
        if (alpha < 0.15){
            alpha = 0.15
        }
        
        return UIColor.blue.withAlphaComponent(alpha)
    }

    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static func mainPurple() -> UIColor {
        return UIColor.rgb(red: 186, green: 165, blue: 255)
    }
    
    static func mainRed() -> UIColor {
        return UIColor.rgb(red: 255, green: 45, blue: 85)
//        #ff2d55
    }
    
    static func mainBlue() -> UIColor {
        return UIColor.rgb(red: 29, green: 203, blue: 211)
//        #1dcbd3
    }
    
    static func offWhite() -> UIColor {
        return UIColor.rgb(red: 240, green: 240, blue: 240)
    }
    
    static func darkLineColor() -> UIColor {
        return UIColor(white: 0, alpha: 0.1)
    }
    
}

extension Date {
    func timeAgoDisplay() -> String {
        
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let month = 4 * week
        
        let quotient: Int
        let unit: String
        
        if secondsAgo < minute {
            quotient = secondsAgo
            unit = "second"
        } else if secondsAgo < hour {
            quotient = secondsAgo / minute
            unit = "minute"
        } else if secondsAgo < day {
            quotient = secondsAgo / hour
            unit = "hour"
        } else if secondsAgo < week {
            quotient = secondsAgo / day
            unit = "day"
        } else if secondsAgo < month {
            quotient = secondsAgo / week
            unit = "week"
        } else {
            quotient = secondsAgo / month
            unit = "month"
        }
        
        return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"
    }
    
}

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 0.5)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

extension UINavigationController {
    func makeTransparent() {
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.barTintColor = .clear
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Element {
        return self[index(startIndex, offsetBy: offset)]
    }
}

extension String {
    func tags() -> [String] {
        if let regex = try? NSRegularExpression(pattern: "@[a-z0-9]+", options: .caseInsensitive) {
            let string = self as NSString
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count)).map {                    string.substring(with: $0.range).replacingOccurrences(of: "@", with: "").lowercased()
            }
        }
        return []
    }
    
}

extension UIView {
    
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(lessThanOrEqualTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        if let bottom = bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        if let right = right {
            self.rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        if width != 0 {
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if height != 0 {
            self.heightAnchor.constraint(equalToConstant: height ).isActive = true
        }
    }

    func setShadow(offset: CGSize, opacity: Float, radius: CGFloat, color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        clipsToBounds = false
    }

    func backgroundGradientTwoColors(colorOne: UIColor, colorTwo: UIColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
       
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        layer.addSublayer(gradientLayer)
    }

}

extension UIViewController {
    
    func hideKeyboardWhenTappedOutside() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func handleDismissKeyboard() {
        view.endEditing(true)
    }
    
    func fadeAnimation() {
        let transition: CATransition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = .fade
        self.view.window!.layer.add(transition, forKey: nil)
    }
    
    func animatePopup(title: String) {
        DispatchQueue.main.async {
            let frame = CGRect(x: 0, y: 0, width: 160, height: 100)
            let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            backgroundView.frame = frame
            backgroundView.center = self.view.center
            backgroundView.clipsToBounds = true
            backgroundView.layer.cornerRadius = 10
            
            self.view.addSubview(backgroundView)
            let savedLabel = UILabel()
            savedLabel.text = title
            savedLabel.font = UIFont.systemFont(ofSize: 18)
            savedLabel.textColor = .black
            savedLabel.textAlignment = .center
            savedLabel.numberOfLines = 0
            savedLabel.frame = frame
            savedLabel.center = self.view.center
            
            
            self.view.addSubview(savedLabel)
            
            let zeroTrans = CATransform3DMakeScale(0, 0, 0)
            backgroundView.layer.transform = zeroTrans
            savedLabel.layer.transform = zeroTrans
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                let oneTrans = CATransform3DMakeScale(1, 1, 1)
                savedLabel.layer.transform = oneTrans
                backgroundView.layer.transform = oneTrans
                
            }, completion: { (completed) in
                
                UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    
                    let pointTrans = CATransform3DMakeScale(0.1, 0.1, 0.1)
                    savedLabel.layer.transform = pointTrans
                    backgroundView.layer.transform = pointTrans
                    
                    savedLabel.alpha = 0
                    backgroundView.alpha = 0
                    
                }, completion: { (_) in
                    
                    savedLabel.removeFromSuperview()
                    backgroundView.removeFromSuperview()
                    
                })
            })
            
        }
    }
}






extension UICollectionView {
    
    func getIndex() -> IndexPath {
        var cellIndex: Int!
        var visibleIndeces = self.indexPathsForVisibleItems
        
        visibleIndeces.sort { (i1, i2) -> Bool in
            return i1.item < i2.item
        }
        if visibleIndeces.count == 3 {
            cellIndex = visibleIndeces[1].item
        } else if visibleIndeces.first?.item == 0 {
            if contentOffset.x > 0.0 {
                cellIndex = visibleIndeces[1].item
            } else {
                cellIndex = visibleIndeces[0].item
            }
        } else {
            let lastIndexItem = visibleIndeces.last?.item
            cellIndex = lastIndexItem!
        }
        return IndexPath(item: cellIndex, section: 0)
    }
}



extension Post {
    
    func changeLikeOnPost(completion: @escaping(Post) -> ()) {
        var url: String!
        let params = ["PID" : self.id, "UID": self.uid] as [String : Any]
        
        if self.hasLiked {
            url = "/Hive/api/secretUnlikePost"
        } else {
            url = "/Hive/api/secretLikePost"
        }
        
        RequestManager().makeResponseRequest(urlString: url, params: params) { (response) in
            var post = self
            
            let hasLiked = post.hasLiked
            post.hasLiked = !hasLiked
            completion(post)
            if response.response?.statusCode == 200 {
                print("liked post")
            } else {
                print("Failed to like post")
            }
        }
    }
    
    func setPostCache() { //to be used in fetching or on liking / commenting
        postCache.setObject(self as AnyObject, forKey: self.id as AnyObject)
    }
    
    func getPostCache(completion: @escaping(Post) -> ()) { //to be used in cell
        if let post = postCache.object(forKey: self.id as AnyObject) as? Post {
            completion(post)
        } else {
            completion(self)
        }
    }

}


extension Int {
    
    func getFriendStatusFromInt(friendId: Int, myId: Int) -> Int {
        let minId = (myId < friendId) ? myId : friendId
        if self == 0 {
            return 0
        }
        else {
            if self == 1 {
                return minId == myId ? 1 : 2
            } else {
                if self == 2 {
                    return minId == myId ? 2 : 1
                } else {
                    return ((self == 3) || (self == 4)) ? 9 : 10
                    
                }
            }
        }
    }
    
}

extension String {
    
    func checkIfUsernameIsUnique(completion: @escaping(Bool) -> ()) {
        let params = ["username": self]
        RequestManager().makeJsonRequest(urlString: "/Hive/api/checkIfUsernameUnique", params: params) { (json, _) in
            guard let json = json as? [String: Any], let unique = json["unique"] as? Bool else { return }
            completion(unique)
        }
        
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withContainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func containsSwearWord(text: String) -> Bool {
        let swearWords = ["anal","anus","assfucker","asshole","assshole","bastard","bitch","bukake","bukkake","cock","cockfucker","cocksuck","cocksucker","coon","coonnass","crap","cunt","cyberfuck","damn","darn","dick","dirty","douche","dummy","erect","erection","erotic","escort","fag","faggot","fuck","fuckass","fuckhole","gook","homoerotic","whore","lesbian","mother fucker","motherfuck","motherfucker","negro","nigger","orgasm","penis","penisfucker","piss","porn","porno","pornography","pussy","retard","sadist","sex","sexy","shit","slut","suck","tits","viagra","whore","xxx"]
        
        return swearWords
            .reduce(false) { $0 || text.lowercased().contains($1.lowercased()) }
    }
}





