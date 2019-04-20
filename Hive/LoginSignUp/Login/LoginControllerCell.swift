//
//  LoginControllerCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-27.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

protocol LoginControllerCellDelegate: class {
    func loggedInSuccessfully()
    func showAlertViewWithTitle(title: String)
    func openPasswordRecovery()
    func lockScreen()
    func unlockScreen()
}

class LoginControllerCell: UICollectionViewCell {
    
    var delegate: LoginControllerCellDelegate?
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    
    let loginInputView = LoginInputView()
    
    lazy var passwordRecoveryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(NSAttributedString(string: "Forgot your password?", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.mainRed().withAlphaComponent(0.5)]), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(handlePasswordRecovery), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handlePasswordRecovery() {
        delegate?.openPasswordRecovery()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        addSubview(scrollView)
        scrollView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        scrollView.contentSize = frame.size
        
        scrollView.addSubview(loginInputView)
        loginInputView.delegate = self
        loginInputView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 278)
        loginInputView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        
        addSubview(passwordRecoveryButton)
        passwordRecoveryButton.anchor(top: nil, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 4, paddingRight: 16, width: 0, height: 0)
        
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
            
            let point = CGPoint(x: 0, y: loginInputView.frame.maxY)
            
            if (!visibleRect.contains(point)) {
                let paddedFrame = CGRect(x: loginInputView.frame.minX, y: loginInputView.frame.minY, width: loginInputView.frame.width, height: loginInputView.frame.height + 16)
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

extension LoginControllerCell: LoginInputViewDelegate, CAAnimationDelegate {
    
    func login(email: String, password: String) {
        delegate?.lockScreen()
        loginInputView.loginButton.isEnabled = false
        self.endEditing(true)
        animate()
        
        let dict = ["credentials": email, "password" : password]
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/userLogIn") else { return }
        
        Alamofire.request(url, method: .post, parameters: dict, encoding: URLEncoding.httpBody, headers: nil).responseJSON { (data) in
            if let json = data.result.value as? [String: Any] {
                self.delegate?.unlockScreen()
                print(json, "LOGIN JSON")
                if let success = json["success"] as? Int {
                    if (success == 1){
                        print("successfully logged in")
                        guard let token = json["token"] as? String else {return}
                        do {
                            let passwordItem = KeychainPasswordItem(service: KeyChainConfig.serviceName,account: email,accessGroup: KeyChainConfig.accessGroup)
                            try passwordItem.savePassword(password)
                            print("token", token)
                            UserDefaults.standard.setIsLoggedIn(isLoggedIn: true, JWT: token, email: email)
                            print(UserDefaults.standard.isLoggedIn(), "IS LOGGED IN")
                        } catch {
                            print("error saving password to keychain")
                        }
                        self.delegate?.loggedInSuccessfully()
                    }else{
                        if let error = json["code"] as? Int, error == 4 {
                            self.loginInputView.loginButton.isEnabled = true
                            self.delegate?.showAlertViewWithTitle(title: "Too many failed attempts, please try again in 24 hours.")
                        }else{
                            self.loginInputView.loginButton.isEnabled = true
                            self.delegate?.showAlertViewWithTitle(title: "Incorrect login information.")
                        }
                    }
                } else {
                    self.loginInputView.loginButton.isEnabled = true
                    self.delegate?.showAlertViewWithTitle(title: "Incorrect login information.")
                }
                // Otherwise, keep the login screen up with an error message.
                // Check for authorization success, or display an error message and continue.
            } else {
                if (!Connectivity.isConnectedToInternet){
                    // display the not connected to internet thing
                    self.delegate?.showAlertViewWithTitle(title: "Please check that you are not connected to the internet and try again.")
                    self.loginInputView.loginButton.isEnabled = true
                }
            }
            self.cancelAnimate()
            }.response { (res) in
                if res.response?.statusCode != 200 {
                    self.delegate?.unlockScreen()
                    self.delegate?.showAlertViewWithTitle(title: "Something went wrong. Please try again.")
                    self.loginInputView.loginButton.isEnabled = true
                }
        }
    }


    func animate() {
        
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.delegate = self
        fullRotation.fromValue = NSNumber(floatLiteral: 0)
        fullRotation.toValue = NSNumber(floatLiteral: Double(CGFloat.pi * 2))
        fullRotation.duration = 0.5
        fullRotation.repeatCount = HUGE
        loginInputView.logoImageView.layer.add(fullRotation, forKey: "360")
        
    }
    
    func cancelAnimate() {
        loginInputView.logoImageView.layer.removeAllAnimations()
        
    }
}
