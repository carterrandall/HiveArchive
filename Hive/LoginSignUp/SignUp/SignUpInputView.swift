//
//  SignUpInputView.swift
//  Highve
//
//  Created by Carter Randall on 2018-11-03.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire
import Photos

protocol SignUpInputViewDelegate {
    func signUp(email: String, password: String, name: String, username: String, willSignUpWithEmail: Bool)
//    func showAlertViewWithTitle(title: String)
    func showPhotoSelector(photoSelector: PhotoSelectionController)
    func presentPhotoPermissionController()
    func showCountryCode(controller: CountryCodeController)
}

class SignUpInputView: UIView, phoneValidatorDelegate, UITextFieldDelegate {
    
    func handleDisplayCountryCode() {
        let countryCodeController = CountryCodeController()
        countryCodeController.delegate = self
        delegate?.showCountryCode(controller: countryCodeController)
    }
    
    func handlePhoneTextChange() {
        handleTextInputChange()
    }
    
    var delegate: SignUpInputViewDelegate?
    var didSelectPhoto: Bool = false
    var isEmailValid: Bool = false
    var isNameValid: Bool = false
    var isUsernameValid: Bool = false
    var isPasswordValid: Bool = false
    var willSignUpWithEmail = true // (true for using email, false for phone number)
    
    var toggleEmailPhoneNumber: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Or use your mobile number", for: .normal)
        button.setTitleColor(UIColor.mainRed().withAlphaComponent(0.6), for: .normal)
        button.addTarget(self, action: #selector(handleTogglePhone), for: .touchUpInside)
        return button
    }()
    // Have to replace all instances of email text field this time now.
    
    let emailPhoneField: UIView = {
        // tags are email = 1, phone = 2, area code selector = 3, otherthing = 4
        let v = UIView()
        let ef = LoginSignUpTextField()
        ef.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        ef.font = UIFont.systemFont(ofSize: 14)
        ef.addTarget(self, action: #selector(handleEmailTextInputChange), for: .editingChanged)
        ef.textContentType = UITextContentType.emailAddress
        ef.tag = 1
        v.addSubview(ef)
        ef.anchor(top: v.topAnchor, left: v.leftAnchor, bottom: v.bottomAnchor, right: v.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: v.frame.width, height: v.frame.height)
        let pf = LoginSignUpphoneField()
        pf.tag = 2
        pf.isHidden = true
        v.addSubview(pf)
        pf.anchor(top: v.topAnchor, left: v.leftAnchor, bottom: v.bottomAnchor, right: v.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: v.frame.width, height: v.frame.height)
        return v
    }()
    
    @objc func handleTogglePhone(){
        if let tf = emailPhoneField.viewWithTag(1) as? LoginSignUpTextField, let pf = emailPhoneField.viewWithTag(2) as? LoginSignUpphoneField{
            tf.isHidden = true
            pf.isHidden = false
            willSignUpWithEmail = false // so this is false
            handleTextInputChange()
            toggleEmailPhoneNumber.addTarget(self, action: #selector(handleToggleEmail), for: .touchUpInside)
            toggleEmailPhoneNumber.setTitle("Or use your email", for: .normal)
            toggleEmailPhoneNumber.setTitleColor(UIColor.mainRed().withAlphaComponent(0.6), for: .normal)
        }
    }
    @objc func handleToggleEmail(){
        if let tf = emailPhoneField.viewWithTag(1) as? LoginSignUpTextField, let pf = emailPhoneField.viewWithTag(2){
            tf.isHidden = false
            pf.isHidden = true
            willSignUpWithEmail = true // so this is true
            handleTextInputChange()
            toggleEmailPhoneNumber.addTarget(self, action: #selector(handleTogglePhone), for: .touchUpInside)
            toggleEmailPhoneNumber.setTitle("Or use your mobile number", for: .normal)
            toggleEmailPhoneNumber.setTitleColor(UIColor.mainRed().withAlphaComponent(0.6), for: .normal)
        }
    }
    
    let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        return button
    }()
    
    @objc func handlePlusPhoto() {
        checkPhotoAuthStatus { (result) in
            DispatchQueue.main.async {
                if result {
                    
                    let layout = UICollectionViewFlowLayout()
                    let photoSelectionController = PhotoSelectionController(collectionViewLayout: layout)
                    photoSelectionController.delegate = self
                    self.delegate?.showPhotoSelector(photoSelector: photoSelectionController)
                    
                } else {
                    self.delegate?.presentPhotoPermissionController()
                }
            }
        }
    }

    fileprivate func checkPhotoAuthStatus(completion: @escaping(Bool) -> ()) {
        var result = false
        switch PHPhotoLibrary.authorizationStatus(){
        case .authorized:
            result = true
            completion(result)
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == PHAuthorizationStatus.authorized {
                    result = true
                } else {
                    result = false
                }
                completion(result)
            }
        case .denied:
            result = false
            completion(result)
        case .restricted:
            result = false
            completion(result)
        }
    }
    
    let nameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-èéêëēėęÿûüùúūîïíīįìôöòóœøōõàáâäæãåāßśšłžźżçćčñń ")
    let usernameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-èéêëēėęÿûüùúūîïíīįìôöòóœøōõàáâäæãåāßśšłžźżçćčñń")
    
    @objc fileprivate func handleEmailTextInputChange() {
        // changed here.
        if let ef = emailPhoneField.viewWithTag(1) as? LoginSignUpTextField, let text = ef.text{
            if text.count > 100 { ef.deleteBackward() }
            ef.validButton.isHidden = false
            if !isValidEmail(testStr: text) {
                isEmailValid = false
                ef.validButton.setImage(UIImage(named: "badform"), for: .normal)
            } else {
                isEmailValid = true
                ef.validButton.setImage(UIImage(named: "check"), for: .normal)
            }
        }
        handleTextInputChange()
    }
    
    let fullNameTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleNameTextInputChange), for: .editingChanged)
        tf.textContentType = UITextContentType.name
        tf.autocapitalizationType = .words
        return tf
    }()
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("string", string, "range", range.upperBound)
        if string == " " && textField.text!.count > 0 {
            if textField.text?[range.upperBound - 1] == " " {
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }
    
    @objc fileprivate func handleNameTextInputChange() {
        guard let text = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        if text.count > 30 { fullNameTextField.deleteBackward() }
        fullNameTextField.validButton.isHidden = false
        
        if text.rangeOfCharacter(from: nameCharacterSet.inverted) != nil || text.count < 1 || text.containsSwearWord(text: text) {
            isNameValid = false
            
            fullNameTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else {
            isNameValid = true
            
            fullNameTextField.validButton.setImage(UIImage(named: "check"), for: .normal)
            
        }
        handleTextInputChange()

    }
    
    let usernameTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Username", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.autocapitalizationType = .none
        tf.textContentType = .username
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleUsernameTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    @objc fileprivate func handleUsernameTextInputChange() {
        guard let text = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        if text.count > 30 { usernameTextField.deleteBackward() }
        
        usernameTextField.validButton.isHidden = false
        
        if text.rangeOfCharacter(from: usernameCharacterSet.inverted) != nil || text.count < 5 || text.containsSwearWord(text: text) {
            isUsernameValid = false
            
            usernameTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else {
            isUsernameValid = true
            usernameTextField.validButton.setImage(UIImage(named: "check"), for: .normal)
            
        }
        handleTextInputChange()
    }
    
    let passwordTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14)])
        tf.isSecureTextEntry = true
        tf.textContentType = .newPassword
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        tf.addTarget(self, action: #selector(handlePasswordInputChange), for: .editingChanged)
        return tf
    }()
    
    @objc fileprivate func handlePasswordInputChange() {
        guard let text = passwordTextField.text else { return }
        if text.count > 100 {passwordTextField.deleteBackward()}
        passwordTextField.validButton.isHidden = false
    
        if text.count < 6 {
            isPasswordValid = false
            passwordTextField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else {
            isPasswordValid = true
            
            passwordTextField.validButton.setImage(UIImage(named: "check"), for: .normal)
            
        }
        handleTextInputChange()
    }
    
    @objc func handleTextInputChange() {
        
        if let pf = emailPhoneField.viewWithTag(2) as? LoginSignUpphoneField, (((isEmailValid && willSignUpWithEmail) || (!willSignUpWithEmail && pf.isPhoneValid)) && isNameValid && isUsernameValid && isPasswordValid) {
            //        let isFormValid = ((isEmailValid && willSignUpWithEmail) || ()) && isNameValid && isUsernameValid && isPasswordValid
            //        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = .mainRed()
            signUpButton.setShadow(offset: CGSize(width: 0, height: 3), opacity: 0.3, radius: 3, color: UIColor.black)
        } else {
            
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
            signUpButton.setShadow(offset: .zero, opacity: 0, radius: 0, color: UIColor.clear)
            
        }
        
    }
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.mainRed().withAlphaComponent(0.5)
        button.layer.cornerRadius = 2
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.isEnabled = false
        
        return button
    }()
    
    @objc func handleSignUp() {
        signUpButton.isEnabled = false
        var credential : String?
        if willSignUpWithEmail {
            if let emailview = emailPhoneField.viewWithTag(1) as? LoginSignUpTextField, let txt = emailview.text?.trimmingCharacters(in: .whitespacesAndNewlines), !(txt.isEmpty) {
                credential = txt
            }
        }else{
            if let pf = emailPhoneField.viewWithTag(2) as? LoginSignUpphoneField, let phone = pf.phoneField.text, let countrycode = pf.countryCode, pf.isPhoneValid {
                guard let regex = try? NSRegularExpression(pattern: "[\\s-\\(\\)]", options: .caseInsensitive) else { return }
                let r = NSString(string: phone).range(of: phone)
                let number = regex.stringByReplacingMatches(in: phone, options: .init(rawValue: 0), range: r, withTemplate: "")
                // also have to get the country code, which can just be a var in the thing, pretty easy to do.
                credential = String(countrycode) + number
            }
        }
        guard let phoneoremail = credential else {return}
        guard let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !fullName.isEmpty else { return }
        guard let username = usernameTextField.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !username.isEmpty else { return }
        guard let password = passwordTextField.text, !password.isEmpty else { return }
        
        self.delegate?.signUp(email: phoneoremail, password: password, name: fullName, username: username, willSignUpWithEmail: willSignUpWithEmail)
        
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func checkIfEmailIsUnique(email: String, completion: @escaping(Bool) -> ()) {
        
        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/checkIfEmailUnique") else { return }
        let params = ["email": email]
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil).responseJSON { (data) in
            if let json = data.result.value as? [String: Any], let unique = json["unique"] as? Bool, let isValid = json["isValid"] as? Bool {
                completion(unique && isValid)
            } else {
                print("Failed to check if email unique")
            }
        }
    }
    
    let containerView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        fullNameTextField.delegate = self
        addSubview(containerView)
        containerView.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: containerView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        plusPhotoButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
  
        let stackView = UIStackView(arrangedSubviews: [toggleEmailPhoneNumber, emailPhoneField, fullNameTextField, usernameTextField, passwordTextField])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.setCustomSpacing(0, after: toggleEmailPhoneNumber)
        containerView.addSubview(stackView)
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 248)
        
        containerView.addSubview(signUpButton)
        signUpButton.anchor(top: stackView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        containerView.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        containerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if let pf = emailPhoneField.viewWithTag(2) as? LoginSignUpphoneField {
            pf.phoneDelegate = self
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension SignUpInputView: PhotoSelectionControllerDelegate {
    func didSelectPhoto(image: UIImage) {
        plusPhotoButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        plusPhotoButton.imageView?.layer.cornerRadius = plusPhotoButton.frame.width / 2
        plusPhotoButton.imageView?.clipsToBounds = true
        plusPhotoButton.setShadow(offset: CGSize(width: 0, height: 3), opacity: 0.3, radius: 3, color: UIColor.black)
        self.didSelectPhoto = true
    }
}

extension SignUpInputView: CountryCodeControllerDelegate {
    func didSelectCountry(country: [String : String]) {
        if let pf = emailPhoneField.viewWithTag(2) as? LoginSignUpphoneField, let code = country["code"], let number = country["dial_code"] {
            pf.phoneCodeButon.setTitle(code + " " + number, for: .normal)
            pf.countryCode = number.replacingOccurrences(of: "+", with: "")
        }
    }
}

