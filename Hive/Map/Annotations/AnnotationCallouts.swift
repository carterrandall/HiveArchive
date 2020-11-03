//
import UIKit
import Mapbox

class CreateHiveCalloutView: UIView, MGLCalloutView{
    var representedObject: MGLAnnotation
    
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()
    
    var delegate: MGLCalloutViewDelegate?
    
    let view : UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 5
        v.setShadow(offset: CGSize(width: 0, height: 1.5), opacity: 0.3, radius: 2, color: UIColor.black)
        return v
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    required init(annotation: MGLAnnotation) {
        
        self.representedObject = annotation
        
        let height: CGFloat = 58
        
        let attributedTitle = NSMutableAttributedString(string: "Tap and hold to drag", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black])
        let width = attributedTitle.size().width
        
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width + 20, height: height)))
        
        addSubview(view)
        view.anchor(top: nil, left: nil, bottom: topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width + 20, height: 40)
        view.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        view.addSubview(titleLabel)
        titleLabel.attributedText = attributedTitle
        titleLabel.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
        self.center = CGPoint(x: rect.origin.x + 30, y: rect.origin.y)
        
    }
    
    func dismissCallout(animated: Bool) {
        removeFromSuperview()
    }
}

protocol UserCalloutDelegate: class {
    func goToProfile(id: Int)
    func goToChat(user: User)
}

class UserCalloutView :UIView, MGLCalloutView {
    
    var delegate: MGLCalloutViewDelegate?
    var calloutDelegate: UserCalloutDelegate?
    var representedObject: MGLAnnotation
    
    var profileIVWidth: NSLayoutConstraint!
    var profileIVHeight: NSLayoutConstraint!
    
    var buttonContainerViewWidth: NSLayoutConstraint!
    var buttonContainerViewHeight: NSLayoutConstraint!
    var buttonContainerLeft: NSLayoutConstraint!
    
    var chatRight: NSLayoutConstraint!
    var profileRight: NSLayoutConstraint!
    
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()
    
    lazy var profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "profile")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleProfile), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleProfile() {
        if let anot = self.representedObject as? friendMGLAnnotation {
            calloutDelegate?.goToProfile(id: anot.id)
        }
    }
    
    lazy var chatButton: ButtonWithCount = {
        let button = ButtonWithCount(type: .system)
        button.setImage(UIImage(named: "chat")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.count = 0
        button.paddingTop = 3
        button.paddingRight = 2
        button.addTarget(self, action: #selector(handleChat), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleChat() {
        if let anot = self.representedObject as? friendMGLAnnotation {
            let user = User(dictionary: ["username":anot.username, "profileImageUrl": anot.profileImageUrl, "id": anot.id])
            calloutDelegate?.goToChat(user: user)
            if (anot.unreadMessage){
                // Will need a little bit of animation / move into the goToChat function (idontknowwherethatis) so that the user does not see the changes that are occuring (b4 the chat thing pops up)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.chatButton.count = 0
                    MapRender.mapView.removeAnnotation(self.representedObject)
                    anot.unreadMessage = false
                    MapRender.mapView.addAnnotation(anot)
                    MapRender.mapView.selectAnnotation(anot, animated: false)
                }
                
            }
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        
        iv.layer.borderWidth = 2
        return iv
    }()
    
    let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        view.layer.borderWidth = 2
        return view
    }()
    
    let dim = 0.14 * UIScreen.main.bounds.width
    
    required init(annotation: MGLAnnotation) {
        self.representedObject = annotation
        
        
        super.init(frame: CGRect(x: 0, y: 0, width: 140.0, height: 80.0))
        
        self.performWorkForAnnotation(annotation: annotation)
        
        if let annotation = annotation as? friendMGLAnnotation {
            addSubview(buttonContainerView)
            buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
            buttonContainerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            buttonContainerLeft = buttonContainerView.leftAnchor.constraint(equalTo: centerXAnchor, constant: -20)
            buttonContainerLeft.isActive = true
            
            buttonContainerViewHeight = buttonContainerView.heightAnchor.constraint(equalToConstant: 40)
            buttonContainerViewHeight.isActive = true
            
            buttonContainerViewWidth = buttonContainerView.widthAnchor.constraint(equalToConstant: 40)
            buttonContainerViewWidth.isActive = true
            buttonContainerView.layer.cornerRadius = 20
            
            if let _ = annotation.hiveName {
                buttonContainerView.layer.borderColor = UIColor.mainPurple().cgColor
            } else {
                buttonContainerView.layer.borderColor = UIColor.mainBlue().cgColor
            }
            
            buttonContainerView.addSubview(profileButton)
            profileButton.anchor(top: buttonContainerView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
            profileRight = profileButton.rightAnchor.constraint(equalTo: buttonContainerView.rightAnchor, constant: 0)
            profileRight.isActive = true
            
            buttonContainerView.addSubview(chatButton)
            chatButton.anchor(top: nil, left: nil, bottom: buttonContainerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
            chatRight = chatButton.rightAnchor.constraint(equalTo: buttonContainerView.rightAnchor, constant: 0)
            chatRight.isActive = true
            buttonContainerView.isUserInteractionEnabled = true
            
        }
        
        addSubview(profileImageView)
        profileImageView.layer.cornerRadius = dim/2
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileIVWidth = profileImageView.widthAnchor.constraint(equalToConstant: dim)
        profileIVWidth.isActive = true
        
        profileIVHeight = profileImageView.heightAnchor.constraint(equalToConstant: dim)
        profileIVHeight.isActive = true
        
        profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func performWorkForAnnotation(annotation: MGLAnnotation) {
        if let friend = annotation as? friendMGLAnnotation {
            profileImageView.profileImageCache(url: friend.profileImageUrl, userId: friend.id)
            if let _ = friend.hiveName {
                profileImageView.layer.borderColor = UIColor.mainPurple().cgColor
            } else {
                profileImageView.layer.borderColor = UIColor.mainBlue().cgColor
            }
            
            if friend.unreadMessage {
                self.chatButton.count = -1
            }
        }
        else{
            if annotation is MGLUserLocation, let currentUser = MainTabBarController.currentUser {
                profileImageView.profileImageCache(url: currentUser.profileImageUrl, userId: currentUser.uid)
                profileImageView.layer.borderColor = UIColor.mainRed().cgColor
            }
        }
    }
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        view.addSubview(self)
        
        self.center = CGPoint(x: rect.midX, y: rect.midY)
        self.layoutIfNeeded()
        self.profileIVWidth.constant = 80
        self.profileIVHeight.constant = 80
        if let _ = self.representedObject as? friendMGLAnnotation {
            self.buttonContainerView.isHidden = false
            self.buttonContainerViewWidth.constant = 140
            self.buttonContainerViewHeight.constant = 80
            self.buttonContainerLeft.constant = -40
            self.profileRight.constant = -20
            self.chatRight.constant = -20
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.profileImageView.layer.cornerRadius = 40
            self.layoutIfNeeded()
            if let _ = self.representedObject as? friendMGLAnnotation {
                self.buttonContainerView.layer.cornerRadius = 40
            }
        }) { (_) in
            
            
        }
    }
    
    func dismissCallout(animated: Bool) {
        
        var isFriend: Bool = false
        if animated {
            DispatchQueue.main.async {
                if let _ = self.representedObject as? friendMGLAnnotation {
                    self.buttonContainerViewWidth.constant = 40
                    self.buttonContainerViewHeight.constant = 40
                    self.buttonContainerLeft.constant = -20
                    self.profileRight.constant = 0
                    self.chatRight.constant = 0
                    isFriend = true
                    
                }
                self.profileIVWidth.constant = self.dim
                self.profileIVHeight.constant = self.dim
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.profileImageView.layer.cornerRadius = self.dim/2
                    if isFriend {
                        self.chatButton.countLabel.alpha = 0.0
                        self.chatButton.countView.alpha = 0.0
                        self.buttonContainerView.layer.cornerRadius = 20
                    }
                    self.layoutIfNeeded()
                }) { (_) in
                    
                    self.removeFromSuperview()
                }
            }
            
        } else {
            self.removeFromSuperview()
        }
        
        
    }
}



