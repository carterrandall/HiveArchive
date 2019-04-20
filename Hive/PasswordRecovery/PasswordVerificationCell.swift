//
//  PasswordVerificationCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-03-06.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import Alamofire

protocol PasswordVerificationCellDelegate: class {
    func backVerification()
    func showResetPassword(header: [String:String])
    func showAlertViewWithTitle(title: String)
    func verificationFailed(cellIndex: Int)
}

class PasswordVerificationCell: UICollectionViewCell {
    
    weak var delegate: PasswordVerificationCellDelegate?
    
    var verificationMethod: String? {
        didSet {
            guard let method = verificationMethod else { return }
            titleLabel.text = "We've sent a code to " + method + ". Enter this code below."
        }
    }
    
    var id: Int?
    
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
        delegate?.backVerification()
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "We've sent a code to your email and/or phone number. Enter this code below."
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    lazy var codeTextField: LoginSignUpTextField = {
        let tf = LoginSignUpTextField()
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.textAlignment = .center
        tf.textContentType = UITextContentType.oneTimeCode
        tf.addTarget(self, action: #selector(handleCodeChanged), for: .editingChanged)
        tf.keyboardType = .numberPad
        return tf
    }()
    
    @objc fileprivate func handleCodeChanged() {
        guard let code = codeTextField.text else { return }
        if code.count > 6 { codeTextField.deleteBackward(); return }
        if code.count == 6 {
            self.animateLoading()
            self.codeTextField.backgroundColor = UIColor(white: 0, alpha: 0.1)
            self.codeTextField.isUserInteractionEnabled = false
            self.endEditing(true)
            if let intCode = Int(code), let id = self.id {
                self.handleSecurityCode(id: id, code: intCode)
            } else {
                print("invalid code, could not cast as int or no id")
            }
        }
    }

    func handleSecurityCode(id: Int, code: Int){ // id is the uid, code is the 6 digit input.

        guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/verifyPassWordRecoveryCode") else {return}
        let params = ["id": id, "code": code]
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil).responseJSON { (data) in
            self.loadingBar.removeFromSuperview()
            if let json = data.result.value as? [String: Any] {
                print(json, "JSON")
                if let error = json["error"] as? Int {

                    if (error == 2) {
                        self.resetRecovery(cellIndex: 1)
                        self.delegate?.showAlertViewWithTitle(title: "Too many attempts. Try again in 24 hours.")
                        // too many attempts, try again in 24 hours.

                    }else if error == 3 {
                        self.delegate?.showAlertViewWithTitle(title: "Wrong code, please try again.")
                        self.codeTextField.isUserInteractionEnabled = true
                        self.codeTextField.backgroundColor = .clear
                        self.codeTextField.text = nil
                        // codes do not match.
                    } else if error == 1 {
                        self.dismissKeyboard()
                        self.resetRecovery(cellIndex: 2)
                        self.delegate?.showAlertViewWithTitle(title: "Code has expired, please try again.")
                        
                        // code has expired, restart the entire reset process.
                    }

                } else if let token = json["token"] as? String {
                    let JWT = "JWT " + token
                    let header = ["Authorization": JWT]
                    self.delegate?.showResetPassword(header: header)
                    self.codeTextField.isUserInteractionEnabled = true
                    self.codeTextField.backgroundColor = .clear
                    self.codeTextField.text = nil
                    // save the token and move onto the set password thing, where you confirm and continue.
                }

            }else{
                if let status = data.response?.statusCode {
                    if (status == 500){
                        print("internal server error, try again.")
                        // Try again, something is fucked.
                    }else if status == 401 {
                        // check params and send in again
                        print("401- parameters are missing.")
                    }

                }
                // handle the status codes
                // use the connectivity functions.
            }
        }
    }
    
    fileprivate func resetRecovery(cellIndex: Int) {
        self.codeTextField.isUserInteractionEnabled = true
        self.codeTextField.backgroundColor = .clear
        self.codeTextField.text = nil
        delegate?.verificationFailed(cellIndex: cellIndex)
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
        
        addSubview(titleLabel)
        titleLabel.anchor(top: backButton.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        addSubview(codeTextField)
        codeTextField.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 16, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 40)
        
        
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
