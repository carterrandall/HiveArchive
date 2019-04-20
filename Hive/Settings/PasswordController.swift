

import UIKit

class PasswordController: UIViewController {
    
    var alertView: LoginSignUpAlertView!
    var tintView: UIView!
    
    let oldPasswordField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.isSecureTextEntry = true
        tf.placeholder = "Old Password"
        tf.textContentType = .password
        tf.addTarget(self, action: #selector(handleTextInputChanged), for: .editingChanged)
        return tf
    }()
    
    let newPasswordField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.isSecureTextEntry = true
        tf.placeholder = "New Password"
        tf.textContentType = .newPassword
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        tf.addTarget(self, action: #selector(handleTextInputChanged), for: .editingChanged)
        return tf
    }()
    
    let confirmNewPasswordField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.isSecureTextEntry = true
        tf.placeholder = "Confirm New Password"
        tf.textContentType = .newPassword
        tf.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        tf.addTarget(self, action: #selector(handleTextInputChanged), for: .editingChanged)
        return tf
    }()
    
    @objc fileprivate func handleTextInputChanged() {
        print("editing changed")
        guard let text = newPasswordField.text, let confirmText = confirmNewPasswordField.text, let oldpass = oldPasswordField.text else { return }
        
        if text.count > 100 { newPasswordField.deleteBackward() }
        if confirmText.count > 100 {confirmNewPasswordField.deleteBackward() }
        if oldpass.count > 100 { oldPasswordField.deleteBackward() }
        
        if text.count < 6 && text.count > 0 {
            doneButton.isEnabled = false
            newPasswordField.validButton.isHidden = false
            newPasswordField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else {
            newPasswordField.validButton.setImage(UIImage(named: "check"), for: .normal)
        }
        
        if confirmText.count < 6 && confirmText.count > 0 {
            doneButton.isEnabled = false
            confirmNewPasswordField.validButton.isHidden = false
            confirmNewPasswordField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        } else if confirmText == text && text.count > 5 {
            confirmNewPasswordField.validButton.setImage(UIImage(named: "check"), for: .normal)
        } else {
            confirmNewPasswordField.validButton.setImage(UIImage(named: "badform"), for: .normal)
        }
        
        if text.count > 5 && confirmText == text && oldpass.count > 5 {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
        
    }
    
    let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDone))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleBack))
        view.addGestureRecognizer(swipeGesture)
        view.isUserInteractionEnabled = true
        
        view.backgroundColor = .white
        
        setupNavBar()
        setupViews()
    }
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.tintColor = .black
        navigationItem.hidesBackButton = true
        navigationItem.title = "Edit Password"
        doneButton.isEnabled = false
        navigationItem.rightBarButtonItem = doneButton
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(handleBack))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc fileprivate func handleDone() {
        self.view.endEditing(true)
        doneButton.isEnabled = false
        
        guard let newPass = newPasswordField.text, let oldPass = oldPasswordField.text, let confirmPass = confirmNewPasswordField.text,  newPass.count > 5 && oldPass.count > 5 && confirmPass == newPass, let email = UserDefaults.standard.getEmail() else { return }
        
        let params = ["oldPass": oldPass, "newPass":newPass]
        RequestManager().makeJsonRequest(urlString: "/Hive/api/resetPasswordInSettings", params: params) { (json, statusCode) in
            if let json = json as? [String :Any], let error = json["error"] as? Int{
                if error == 1 {
                    self.showAlertViewWithTitle(title: "Verify that the fields are filled out correctly.")
                }else if error == 2{
                    self.showAlertViewWithTitle(title: "Password is incorrect, please try again.")
                }else if error == 3 {
                    self.showAlertViewWithTitle(title: "Too many attempts, try again in 24 hours.")
                }else{
                    print("Unknown error sent back from server, see what is going on.")
                }
            }else{
                if let statuscode = statusCode {
                    if statuscode == 500 {
                        print("internal server error")
                        self.showAlertViewWithTitle(title: "There was an issue, please try again.")
                    } else if statuscode == 401 {
                        print("header is invalid, not containing an id.")
                        self.showAlertViewWithTitle(title: "Generate a new token, then try again.")
                    } else if statuscode == 200 {
                        self.success = true
                        do {
                            let passwordItem = KeychainPasswordItem(service: KeyChainConfig.serviceName,account: email,accessGroup: KeyChainConfig.accessGroup)
                            try passwordItem.savePassword(newPass)
                        } catch {
                            print("wasn't able to save to keychain - fucked brah")
                        }
                        self.showAlertViewWithTitle(title: "Password successfully changed")
                    }
                }else{
                    print("no status code, something strange, see connectivity")
                }
            }
        
        }
    }
    
    var success: Bool?
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
    
    fileprivate func setupViews() {
        
        let stackView = UIStackView(arrangedSubviews: [oldPasswordField, newPasswordField, confirmNewPasswordField])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 16
        view.addSubview(stackView)
        stackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 152)
    }
    
}

extension PasswordController: LoginSignUpAlertViewDelegate {
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
                self.oldPasswordField.text = nil
                self.newPasswordField.text = nil
                self.confirmNewPasswordField.text = nil
            }
        }
    }
}
