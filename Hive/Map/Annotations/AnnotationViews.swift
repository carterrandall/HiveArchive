
import UIKit
import Mapbox

class CustomUserAnnotationView: MGLUserLocationAnnotationView {
    let dim = 0.14 * UIScreen.main.bounds.width
    var didsetview = false
    override func update() {
        if frame.isNull {
            
            frame = CGRect(x: 0, y: 0, width: dim, height: dim)
        }
        if !didsetview && CLLocationCoordinate2DIsValid(userLocation!.coordinate), let currentUser = MainTabBarController.currentUser {
            didsetview = true
            setView(currentUser: currentUser)
        }
        else{
            return
        }
    }
    
    func setView(currentUser: User){
        // figure out why this is being called 1 million times, make sure this glitch is fixed.
        let view : CustomImageView = {
            
            let v = CustomImageView(frame: CGRect(x: -dim/2, y: -dim/2, width: dim, height: dim))
            v.layer.borderColor = UIColor.mainRed().cgColor
            v.layer.borderWidth = 2
            v.clipsToBounds = true
            v.layer.cornerRadius = dim/2
            v.profileImageCache(url: currentUser.profileImageUrl, userId: currentUser.uid)
            return v
        }()
        
        self.addSubview(view)
    }
    
}

class CustomFriendAnnotationView: MGLAnnotationView {
    
    let dim = 0.14 * UIScreen.main.bounds.width
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 2
        return iv
    }()
    
    required init(postannotation: MGLAnnotation, reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        frame = CGRect(x:0, y:0, width: dim, height: dim) // Make frame size the size of icon.
        annotation = postannotation
        guard let friendannotation = postannotation as? friendMGLAnnotation else { return }
        
        setupAnnotationView(postannotataion: friendannotation)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupAnnotationView(postannotataion: friendMGLAnnotation) {
        
        
        profileImageView.profileImageCache(url: postannotataion.profileImageUrl, userId: postannotataion.id)
        profileImageView.layer.cornerRadius = dim / 2
        if let _ = postannotataion.hiveName {
            profileImageView.layer.borderColor = UIColor.mainPurple().cgColor
        } else {
            profileImageView.layer.borderColor = UIColor.mainBlue().cgColor
        }
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: dim, height: dim)
        profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if postannotataion.unreadMessage {
            let messageView = UIView()
            messageView.backgroundColor = UIColor.mainRed()
            messageView.layer.cornerRadius = 7
            addSubview(messageView)
            messageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 14, height: 14)
            let padding: CGFloat = -(CGFloat(dim/2) * cos((CGFloat.pi / 4)))
            
            messageView.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor, constant: -padding).isActive = true
            messageView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: padding).isActive = true
        }
        
    }
    
}

class TopPostAnnotationView : MGLAnnotationView {
    required init(postannotation: MGLAnnotation, reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        let dim = 0.1066666667 * UIScreen.main.bounds.width
        frame = CGRect(x: dim/2, y: dim/2, width: dim, height: dim) // Make frame size the size of icon.
        annotation = postannotation
        setupAnnotationView(dim: dim)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupAnnotationView(dim: CGFloat) {
        let view : UIView = {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: dim, height: dim))
            let iv = UIImageView(frame: v.frame)
            iv.clipsToBounds = true
            iv.layer.cornerRadius = dim / 2
            v.addSubview(iv)
            iv.anchor(top: v.topAnchor, left: v.leftAnchor, bottom: v.bottomAnchor, right: v.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: dim, height: dim)
            return v
        }()
        
        self.addSubview(view)
    }
    
    
    
}


