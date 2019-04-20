//
//  PasswordRecoveryController.swift
//  Hive
//
//  Created by Carter Randall on 2019-03-05.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

protocol PasswordRecoveryCellDelegate: class {
    func endPasswordRecovery()
    func displayVerificationScreen(id: Int?, verificationMethod: String?)
    func showAlertViewWithTitle(title: String)
}

class PasswordRecoveryCell: UICollectionViewCell, UITextFieldDelegate {
    
    weak var delegate: PasswordRecoveryCellDelegate?
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    @objc func handleCancel() {
        self.endEditing(true)
        self.nextButton.isEnabled = false
        self.nextButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        self.hasGottenCode = false
        self.credentialTextField.text = nil
        delegate?.endPasswordRecovery()
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter the email, username or phone number associated to your account."
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    lazy var credentialTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.autocapitalizationType = .none
        tf.textContentType = .username
        tf.addTarget(self, action: #selector(handleTextChange), for: .editingChanged)
        return tf
    }()
    
    var hasGottenCode: Bool = false
    
    @objc fileprivate func handleTextChange() {
        self.hasGottenCode = false
        guard let text = credentialTextField.text else { return }
        
        if text.count < 5 {
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        } else {
            nextButton.isEnabled = true
            nextButton.backgroundColor = UIColor.mainRed()
        }
        
        if text.count > 100 {
            credentialTextField.deleteBackward()
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
    
    lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 2
        button.tintColor = .white
        button.setTitleColor(.white, for: .disabled)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleNext() {
        self.nextButton.isEnabled = false
        self.nextButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)

        if hasGottenCode {
            self.delegate?.displayVerificationScreen(id: nil, verificationMethod: nil)
            self.nextButton.isEnabled = true
            self.nextButton.backgroundColor = UIColor.mainRed()
            return
        }
        
        self.animateLoading()
        self.endEditing(true)
        
        print("Handling next ye cunt")
        guard let text = self.credentialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        Alamofire.request(MainTabBarController.serverurl + "/Hive/api/findAccountWithCredential", method: .post, parameters: ["credential": text], encoding: URLEncoding.httpBody, headers: nil).responseJSON { (data) in
            self.loadingBar.removeFromSuperview()

            if let json = data.result.value as? [String:Any] {
                if let error = json["error"] as? Int {

                    print(error, "Error")
                    if error == 1 {
                        self.delegate?.showAlertViewWithTitle(title: "No user was found. Please try again.")
                    } else {
                        self.delegate?.showAlertViewWithTitle(title: "Something went wrong! Please try again.")
                        self.credentialTextField.text = nil
                    }
                }else{
                    var method: String!
                    print("no error")
                    if let email = json["email"] as? String {
                        method = email
                    } else if let phone = json["phone"] as? String {
                        if (method == nil){
                            method = phone
                        }else{
                            method = method + " and " + phone
                        }
                    }
                    if let id = json["id"] as? Int {
                        print(id, "ID")
                        self.hasGottenCode = true
                        self.delegate?.displayVerificationScreen(id: id, verificationMethod: method)
                        self.nextButton.isEnabled = true
                        self.nextButton.backgroundColor = UIColor.mainRed()
                    } else {
                        self.delegate?.showAlertViewWithTitle(title: "Something went wrong! Please try again.")
                        self.credentialTextField.text = nil
                        print("NO ID in JSON:", json)
                    }

                }
            } else {
                // fuckied
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
        
        credentialTextField.delegate = self
        
        addSubview(cancelButton)
        cancelButton.anchor(top: safeAreaLayoutGuide.topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 50)
        
        addSubview(titleLabel)
        titleLabel.anchor(top: cancelButton.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        addSubview(credentialTextField)
        credentialTextField.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        addGestureRecognizer(tapGesture)
        
        addSubview(nextButton)
        nextButton.anchor(top: credentialTextField.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 32, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func dismissKeyboard() {
        self.endEditing(true)
    }
}
