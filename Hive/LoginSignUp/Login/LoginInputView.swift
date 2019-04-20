//
//  LoginInputView.swift
//  Highve
//
//  Created by Carter Randall on 2018-11-03.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire
protocol LoginInputViewDelegate {
    func login(email: String, password: String)
   
}

class LoginInputView: UIView {
    
    var delegate: LoginInputViewDelegate?
  
    let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "icon")
        return iv
    }()

    let emailTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Username, Email or Mobile Number", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textContentType = .username // make sure that this works fine.
        tf.autocapitalizationType = .none
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    let passwordTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.isSecureTextEntry = true
        tf.textContentType = .password
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    @objc func handleTextInputChange() {
        if let emailCount = emailTextField.text?.count, emailCount > 100 {
            emailTextField.deleteBackward()
        }
        
        if let passwordCount = passwordTextField.text?.count, passwordCount > 100 {
            passwordTextField.deleteBackward()
        }
        
        let isEmailEmpty = (emailTextField.text?.isEmpty)!
        let isPasswordLengthValid = (passwordTextField.text?.count)! >= 6
        
        let isFormValid = !isEmailEmpty && isPasswordLengthValid
        
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.mainRed()
            loginButton.setShadow(offset: CGSize(width: 0, height: 3), opacity: 0.3, radius: 3, color: UIColor.black)
            logoImageView.image = UIImage(named: "iconfilled")
            logoImageView.setShadow(offset: CGSize(width: 0, height: 3), opacity: 0.3, radius: 3, color: UIColor.black)
        } else {
            logoImageView.image = UIImage(named: "icon")
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
            loginButton.setShadow(offset: .zero, opacity: 0, radius: 0, color: UIColor.clear)
            logoImageView.setShadow(offset: .zero, opacity: 0, radius: 0, color: UIColor.clear)
            
        }
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        button.layer.cornerRadius = 2
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    @objc fileprivate func handleLogin() {
       
        guard let email = emailTextField.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let password = passwordTextField.text else { return }
        delegate?.login(email: email, password: password)

    }

    let containerView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(containerView)
        
        addSubview(logoImageView)
        logoImageView.anchor(top: containerView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 16
    
        addSubview(stackView)
        stackView.anchor(top: logoImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 96)
        
        
        addSubview(loginButton)
        loginButton.anchor(top: stackView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        containerView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        containerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
