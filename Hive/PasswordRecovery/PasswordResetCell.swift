//
//  PasswordResetCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-03-06.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

protocol PasswordResetCellDelegate: class {
    func backReset()
    func donePasswordReset()
    func showAlertViewWithTitle(title: String)
}

class PasswordResetCell: UICollectionViewCell {
    
    weak var delegate: PasswordResetCellDelegate?
    
    var header: [String: String]?
    
    lazy var backButton: UIButton = {
        let button = UIButton()
        button.setTitle("Back", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleBack() {
        self.endEditing(true)
        delegate?.backReset()
    }
    
    lazy var newPasswordTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        tf.attributedPlaceholder = NSAttributedString(string: "New Password", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return tf
    }()
    
    lazy var confirmTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        tf.attributedPlaceholder = NSAttributedString(string: "Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return tf
    }()
    
    @objc fileprivate func handleTextChange() {
        guard let text = newPasswordTextField.text, let confirmText = confirmTextField.text else { return }
        
        if text.count > 100 { newPasswordTextField.deleteBackward() }
        if confirmText.count > 100 { confirmTextField.deleteBackward() }
        
        if text.count < 6 && text.count > 0 {
            doneButton.isEnabled = false
            newPasswordTextField.validButton.isHidden = false
            doneButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
            newPasswordTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else {
            newPasswordTextField.validButton.setImage(UIImage(named: "check"), for: .normal)
        }
        
        if confirmText.count < 6 && confirmText.count > 0 {
            doneButton.isEnabled = false
            doneButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)

            confirmTextField.validButton.isHidden = false
            confirmTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else if confirmText == text && text.count > 5 {
            confirmTextField.validButton.setImage(UIImage(named: "check"), for: .normal)
        } else {
            confirmTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        }
        
        if text.count > 5 && confirmText == text {
            doneButton.isEnabled = true
            doneButton.backgroundColor = .mainRed()
        } else {
            doneButton.isEnabled = false
            doneButton.backgroundColor = UIColor.mainRed()
        }
        
    }
    
    
    lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 2
        button.tintColor = .white
        button.setTitleColor(.white, for: .disabled)
        button.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDone() {
        animateLoading()
        self.endEditing(true)
        self.doneButton.isEnabled = false
        self.doneButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        if let header = self.header, let newPass = self.newPasswordTextField.text {
            self.handleSetNewPassword(header: header, newPass: newPass)
        }
    }
    
    func handleSetNewPassword(header: [String:String], newPass: String){
        // this assumes that the passwords are valid and confirmed.
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/recoverPasswordSet") else {return}
        Alamofire.request(url, method: .post, parameters: ["password": newPass], encoding: URLEncoding.httpBody, headers: header).response { (res) in
            if let statuscode = res.response?.statusCode {
                self.doneButton.isEnabled = true
                self.doneButton.backgroundColor = UIColor.mainRed()
                self.loadingBar.removeFromSuperview()
                if (statuscode == 200) {
                    print("You are good, tell them that there was a great success, then take them to the login screen (Alert view might be stupid for this, instead slide them to a new page that says Great Success with a check or something, then take them back to the login screen.")
                    self.delegate?.donePasswordReset()
                    self.delegate?.showAlertViewWithTitle(title: "Password Successfully changed.")
                    self.confirmTextField.text = nil
                    self.newPasswordTextField.text = nil
                    
                }else if statuscode == 401 {
                    
                    // Your header had expired or something, restart the entire process.
                    
                }else if statuscode == 500 {
                    // Have alex look at this
                }
                
            }else{
                // no reponse, pretty fucked
            }
        }
    }
    
    var loadingBar: UIView!
    fileprivate func animateLoading() {
        loadingBar = UIView()
        loadingBar.backgroundColor = UIColor.mainRed()
        addSubview(loadingBar)
        loadingBar.anchor(top: topAnchor, left: leftAnchor, bottom: safeAreaLayoutGuide.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: -4, paddingRight: 0, width: 0, height: 4)
        let loadingBarWidth = loadingBar.widthAnchor.constraint(equalToConstant: 0)
        loadingBarWidth.isActive = true
        
        layoutIfNeeded()
        
        loadingBarWidth.constant = UIScreen.main.bounds.width + 10
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.0, options: [.curveEaseIn,.repeat,.autoreverse], animations: {
            self.layoutIfNeeded()
        }) { (_) in
            
        }
        
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backButton)
        backButton.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 50)
        
        addSubview(newPasswordTextField)
        newPasswordTextField.anchor(top: backButton.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        addSubview(confirmTextField)
        confirmTextField.anchor(top: newPasswordTextField.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        addSubview(doneButton)
        doneButton.anchor(top: confirmTextField.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 32, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        addGestureRecognizer(tapGesture)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func dismissKeyboard() {
        self.endEditing(true)
    }
}
