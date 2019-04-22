//
//  SignUpControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-27.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

protocol SignUpControllerCellDelegate: class {
    func loggedInSuccessfully()
    func showPhotoSelector(photoSelector: PhotoSelectionController)
    func presentPhotoPermissionController()
    func showTOS()
    func showAlertViewWithTitle(title: String)
    func showCountryCode(controller: CountryCodeController)
    func lockScreen()
    func unlockScreen()
    func showTutorial()
}

class SignUpControllerCell: UICollectionViewCell {
    
    weak var delegate: SignUpControllerCellDelegate?
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    
    let signUpInputView = SignUpInputView()
    
    lazy var termsOfUseButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "By clicking Sign Up, you agee to our ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Terms and Data policy.", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.mainRed().withAlphaComponent(0.5)]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(handleTOS), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleTOS() {
        delegate?.showTOS()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(scrollView)
        scrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        scrollView.contentSize = frame.size
        
        scrollView.addSubview(signUpInputView)
        signUpInputView.delegate = self
        signUpInputView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 430)
        signUpInputView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        
        addSubview(termsOfUseButton)
        termsOfUseButton.anchor(top: nil, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 4, paddingRight: 16, width: 0, height: 0)
        
        registerForKeyboardNotifications()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
        @objc func keyboardWillShow(notification: NSNotification) {
    

            if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
    
                var contentInset = self.scrollView.contentInset
                contentInset.bottom = keyboardFrame.size.height
    
                self.scrollView.contentInset = contentInset
                self.scrollView.scrollIndicatorInsets = contentInset
    
                var visibleRect : CGRect = self.frame
                visibleRect.size.height -= keyboardFrame.height
    
                let point = CGPoint(x: 0, y: signUpInputView.frame.maxY)
                
                if (!visibleRect.contains(point)) {
                    let paddedFrame = CGRect(x: signUpInputView.frame.minX, y: signUpInputView.frame.minY, width: signUpInputView.frame.width, height: signUpInputView.frame.height + 16)
                    DispatchQueue.main.async {
                        self.scrollView.scrollRectToVisible(paddedFrame, animated: true)
                    }
                }
            }
    
        }
    
        @objc func keyboardWillBeHidden(notification: NSNotification) {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    self.scrollView.contentInset = .zero
                    self.scrollView.scrollIndicatorInsets = .zero
                })
    
            }
        }
    
}

extension SignUpControllerCell: SignUpInputViewDelegate, CAAnimationDelegate {
    
    func showCountryCode(controller: CountryCodeController) {
        print("SHOWING COUNTRY CODE")
        delegate?.showCountryCode(controller: controller)
    }
  
    
    func presentPhotoPermissionController() {
        delegate?.presentPhotoPermissionController()
    }
    
    func showPhotoSelector(photoSelector: PhotoSelectionController) {
        delegate?.showPhotoSelector(photoSelector: photoSelector)
        
    }
    
    func signUp(email: String, password: String, name: String, username: String, willSignUpWithEmail: Bool) {
        
        
        delegate?.lockScreen()
        self.endEditing(true)
        DispatchQueue.main.async {
            self.animate()
        }
        
        guard let emaildata = email.data(using: .utf8), let passworddata = password.data(using: .utf8), let namedata = name.data(using: .utf8), let usernamedata = username.data(using: .utf8) else {return}
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/signUpUser") else {return}
        var image: UIImage?
        if self.signUpInputView.didSelectPhoto, let photoImage = self.signUpInputView.plusPhotoButton.imageView?.image {
            image = photoImage
        }
        Alamofire.upload(multipartFormData: { (multipart) in
            if self.signUpInputView.didSelectPhoto, let image = image {
                let filename = NSUUID().uuidString
                if let uploadData = image.jpegData(compressionQuality: 0.3) {
                    multipart.append(uploadData, withName: "file", fileName: "\(filename).jpg", mimeType: "image/jpeg")
                }
            }
            multipart.append(emaildata, withName: "email")
            multipart.append(passworddata, withName: "password")
            multipart.append(namedata, withName: "fullName")
            multipart.append(usernamedata, withName: "username")
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: nil) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    //debugPrint(response)
                    self.delegate?.unlockScreen()
                    if let responseData = response.result.value as? [String:Any] {
                        print(responseData)
                        if let success = responseData["success"] as? Bool, success == true, let token = responseData["token"] as? String{
                            UserDefaults.standard.setIsLoggedIn(isLoggedIn: true, JWT: token, email: email)
                            do {
                                let passwordItem = KeychainPasswordItem(service: KeyChainConfig.serviceName,account: email,accessGroup: KeyChainConfig.accessGroup)
                                try passwordItem.savePassword(password)
                            } catch {
                                print("error saving password to keychain")
                            }
                            
                            
                            if UserDefaults.standard.value(forKey: "tutorial") == nil {
                                UserDefaults.standard.set(1, forKey: "tutorial")
                                self.delegate?.showTutorial()
                            } else {
                                self.delegate?.loggedInSuccessfully()
                            }
                        }
                        else{
                            self.cancelAnimate()
                            self.signUpInputView.signUpButton.isEnabled = true
                            if let code = responseData["code"] as? Int {
                                self.alertForSignUpError(code: code, email: willSignUpWithEmail)
                            }else{
                                self.alertForSignUpError(code: 1, email: willSignUpWithEmail)
                                
                                // now we really have a problem
                                print("code error does not exist - probably dont do anything also will have a connectivity check as well, since that is userful in general")
                            }
                            
                        }
                    } else {
                        self.cancelAnimate()
                        self.signUpInputView.signUpButton.isEnabled = true
                        
                        if Connectivity.isConnectedToInternet {
                            self.alertForSignUpError(code: 1,email: willSignUpWithEmail)
                            // if connectvity is good, dismiss the non-connectivity view, so that things work nicely.
                            print("Connected")
                        } else {
                            self.delegate?.showAlertViewWithTitle(title: "Please check that you are connected to the internet and try again.")
                        }
                        
                        
                        // some kind of error with the formatiing.
                    }
                    // not sure why this is here, looks like it will get called whether you sign up or not.
                    
                }
            case .failure(let encodingError):
                print(encodingError)
                self.cancelAnimate()
                self.delegate?.unlockScreen()
            }
        }
        
    }
    
    func alertForSignUpError(code: Int, email: Bool){
        print("SHOW THAT SHIT")
        var em = "email"
        var Em = "Email"
        if (!email){
            em = "mobile number"
            Em = "Mobile number"
        }
        if (code == 1){
            self.delegate?.showAlertViewWithTitle(title: "Something went wrong. Please try again.")
            return
        }
        if (code == 2){
            self.delegate?.showAlertViewWithTitle(title: "That username is already in use.")
            return
        }
        if (code == 3){
            self.delegate?.showAlertViewWithTitle(title: "That \(em) is already in use.")
            return
        }
        if (code == 4){
            self.delegate?.showAlertViewWithTitle(title: "\(Em) and username are already in use.")
            return
        }
        if (code == 5){
            self.delegate?.showAlertViewWithTitle(title: "Something went wrong. Please try again.")
            return
        }
    }

    
    func animate() {
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.delegate = self
        fullRotation.fromValue = NSNumber(floatLiteral: 0)
        fullRotation.toValue = NSNumber(floatLiteral: Double(CGFloat.pi * 2))
        fullRotation.duration = 0.5
        fullRotation.repeatCount = HUGE
        signUpInputView.plusPhotoButton.layer.add(fullRotation, forKey: "360")
    }

    func cancelAnimate() {
        signUpInputView.plusPhotoButton.layer.removeAllAnimations()
    }
    
    
}
