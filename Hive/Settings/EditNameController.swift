//
//  EditNameController .swift
//  Highve
//
//  Created by Carter Randall on 2018-11-05.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol EditNameControllerDelegate {
    func didMakeChanges(editingProperty: String, editedString: String)
}

class EditNameController: UIViewController {
    
    var delegate: EditNameControllerDelegate?
    
    var alertView: LoginSignUpAlertView!
    var tintView: UIView!
    
    
    let nameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-èéêëēėęÿûüùúūîïíīįìôöòóœøōõàáâäæãåāßśšłžźżçćčñń ")
    let usernameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-èéêëēėęÿûüùúūîïíīįìôöòóœøōõàáâäæãåāßśšłžźżçćčñń")
//
//    let nameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- ")
//    let usernameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-")
//
    var editingProperty: String! {
        didSet {
            if editingProperty == "username" {
                navigationItem.title = "Edit username"
                textField.autocapitalizationType = .none
            } else {
                navigationItem.title = "Edit name"
                textField.autocapitalizationType = .words
            }
        }
    }
    
    var placeholderText: String?
    var uid: Int?

    let textField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.addTarget(self, action: #selector(handleTextInputChanged), for: .editingChanged)
        return tf
    }()
    
    @objc fileprivate func handleTextInputChanged() {
        
        guard let text = textField.text else { return }
        let count = text.count
        if count > 30 {
            textField.deleteBackward()
            return
        }
        

        var minLength: Bool!
        var validChars: Bool!
        if editingProperty == "username" {
            validChars = (text.rangeOfCharacter(from: usernameCharacterSet.inverted) == nil)
            minLength = 5 <= count
        } else {
            validChars = (text.rangeOfCharacter(from: nameCharacterSet.inverted) == nil)
            minLength = 1 <= count
        }
        
        let isFormGood = minLength && validChars
        
        textField.validButton.isHidden = false
        
        if isFormGood && !text.containsSwearWord(text: text) {
            textField.validButton.setImage(UIImage(named: "check"), for: .normal)
            doneButton.isEnabled = true
        } else {
            textField.validButton.setImage(UIImage(named: "badform"), for: .normal)
            doneButton.isEnabled = false
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDone))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        view.addGestureRecognizer(swipeGesture)
        view.isUserInteractionEnabled = true
        
        setupViews()
        setupNavBar()
        
        
        
    }
    
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.tintColor = .black
        navigationItem.hidesBackButton = true
        
        doneButton.isEnabled = false
        navigationItem.rightBarButtonItem = doneButton
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
    }
    
    fileprivate func setupViews() {
        view.backgroundColor = .white
        view.addSubview(textField)
        textField.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        textField.placeholder = placeholderText
        textField.becomeFirstResponder()

    }
    
    @objc func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    var success: Bool?
    @objc func handleDone() {
        self.view.endEditing(true)

        doneButton.isEnabled = false
        
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        if editingProperty == "username" {
            
            text.checkIfUsernameIsUnique { (isUnique) in
                if isUnique {
                    
                    self.delegate?.didMakeChanges(editingProperty: self.editingProperty, editedString: text.lowercased())
                   
                    let params = ["username": text.lowercased().trimmingCharacters(in: .whitespaces)]
                    RequestManager().makeResponseRequest(urlString: "/Hive/api/updateUserusername", params: params, completion: { (response) in
                        self.view.endEditing(true)
                        if response.response?.statusCode == 200 {
                            print("Success editing username")
                            self.success = true
                            self.showAlertViewWithTitle(title: "Username successfully changed.")
                            
                        } else {
                            self.showAlertViewWithTitle(title: "Something went wrong. Please try again later.")
                            print("Error changing username", response)
                        }
                    })
                   
                } else {
                    self.showAlertViewWithTitle(title: "That username is already taken.")
                    
                }
            }
        
        } else {
            
            self.delegate?.didMakeChanges(editingProperty: self.editingProperty, editedString: text)
            
            let params = ["fullName": text]
            RequestManager().makeResponseRequest(urlString: "/Hive/api/updateUserfullName", params: params) { (response) in
                if response.response?.statusCode == 200 {
                    self.success = true
                    self.showAlertViewWithTitle(title: "Name successfully changed.")
                    print("Sucess editing name")
                } else {
                    self.showAlertViewWithTitle(title: "Something went wrong. Please try again later.")
                    print("error editing name", response)
                }
            }
        }
    }
    
    func showAlertViewWithTitle(title: String) {
        print("SHOWING ALERT VIEW")
        alertView = LoginSignUpAlertView()
        alertView.delegate = self
        alertView.title = title
        tintView = UIView(frame: view.frame)
        view.addSubview(tintView)
        tintView.alpha = 0.0
        tintView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        alertView.frame = CGRect(x: 40, y: view.frame.height, width: view.frame.width - 80, height: 80)
        view.addSubview(alertView)
        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.alertView.frame = CGRect(x: 40, y: (self.view.frame.height - 100) / 2, width: self.view.frame.width - 80, height: 100)
            self.tintView.alpha = 1.0
        }) { (_) in
            
        }
    }
}

extension EditNameController: LoginSignUpAlertViewDelegate {
    func dismissAlert() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.tintView.alpha = 0.0
            self.alertView.frame = CGRect(x: 40, y: self.view.frame.height, width: self.view.frame.width - 80, height: 80)
        }) { (_) in
            self.tintView.removeFromSuperview()
            self.alertView.removeFromSuperview()
            if let suc = self.success, suc {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.doneButton.isEnabled = true
            }
        }
    }
}
