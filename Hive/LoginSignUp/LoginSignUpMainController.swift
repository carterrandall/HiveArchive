//
//  LoginSignUpMainController.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-27.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class LoginSignUpMainController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate let loginControllerCellId = "loginControllerCellId"
    fileprivate let signUpControllerCellId = "signUpControllerCellId"
    fileprivate let pwdRecoveryCellId = "pwdRecoveryCellId"
    fileprivate let pwdVerificationCellId = "pwdVerificationCellId"
    fileprivate let pwdResetCellId = "pwdResetCellId"
    
    var alertView: LoginSignUpAlertView!
    var tintView: UIView!
    
    enum LoginState {
        case normal, password
    }
    
    fileprivate var currentLoginState: LoginState = .normal
    
    fileprivate let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "loginbackground"))
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    lazy var menuBar: LoginSignUpMenuBar = {
        let mb = LoginSignUpMenuBar()
        mb.loginSignUpMainController = self
        return mb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupCollectionView()
        
        
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        self.showTutorial()
//    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    fileprivate func setupCollectionView() {
        collectionView.bounces = false
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(LoginControllerCell.self, forCellWithReuseIdentifier: loginControllerCellId)
        collectionView.register(SignUpControllerCell.self, forCellWithReuseIdentifier: signUpControllerCellId)
        collectionView.register(PasswordRecoveryCell.self, forCellWithReuseIdentifier: pwdRecoveryCellId)
        collectionView.register(PasswordVerificationCell.self, forCellWithReuseIdentifier: pwdVerificationCellId)
        collectionView.register(PasswordResetCell.self, forCellWithReuseIdentifier: pwdResetCellId)
    }
    
    fileprivate func setupViews() {
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.height)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.insertSubview(blurView, aboveSubview: backgroundImageView)
        blurView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.height)
        
        view.addSubview(menuBar)
        menuBar.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
    }
    
    func scrollToMenuIndex(menuIndex: Int) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            let indexPath = IndexPath(item: menuIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let item = targetContentOffset.pointee.x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuBar.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentLoginState == .normal ? 2 : 5
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: signUpControllerCellId, for: indexPath) as! SignUpControllerCell
            cell.delegate = self
            return cell
            
        } else if indexPath.item == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: loginControllerCellId, for: indexPath) as! LoginControllerCell
            cell.delegate = self
            return cell
        } else if indexPath.item == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pwdRecoveryCellId, for: indexPath) as! PasswordRecoveryCell
            cell.delegate = self
            return cell
        } else if indexPath.item == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pwdVerificationCellId, for: indexPath) as! PasswordVerificationCell
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pwdResetCellId, for: indexPath) as! PasswordResetCell
            cell.delegate = self
            return cell
        }
    }
    
    var id: Int?
    var verificationMethod: String?
    var header: [String: String]?
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if currentLoginState == .password {
            if indexPath.item == 3, let cell = cell as? PasswordVerificationCell {
                cell.id = self.id
                cell.verificationMethod = self.verificationMethod
            } else if indexPath.item == 4, let cell = cell as? PasswordResetCell {
                cell.header = header
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
}

extension LoginSignUpMainController: SignUpControllerCellDelegate, LoginControllerCellDelegate {
    
    func showTutorial() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let tutorialController = TutorialController(collectionViewLayout: layout)
        tutorialController.modalTransitionStyle = .crossDissolve
        tutorialController.modalPresentationStyle = .overFullScreen
        tutorialController.delegate = self
        self.present(tutorialController, animated: true, completion: nil)
        
    }
 
    func showCountryCode(controller: CountryCodeController) {
        let countryCodeNavController = UINavigationController(rootViewController: controller)
        countryCodeNavController.modalPresentationStyle = .overFullScreen
        present(countryCodeNavController, animated: true, completion: nil)
    }
    
    func loggedInSuccessfully() {
        let mtbc = MainTabBarController()
        UIApplication.shared.keyWindow?.rootViewController = mtbc
        self.dismiss(animated: true) {
            print("Enjoy Hive!")
        }
    }
    
    func openPasswordRecovery() {
        DispatchQueue.main.async {
            self.currentLoginState = .password
            self.collectionView.reloadData()
            self.collectionView.performBatchUpdates(nil, completion: { (_) in
                DispatchQueue.main.async {
                    self.collectionView.scrollToItem(at: IndexPath(item: 2, section: 0), at: .centeredHorizontally, animated: true)
                    self.collectionView.isScrollEnabled = false
                    
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                        self.menuBar.alpha = 0.0
                    }, completion: { (_) in
                        self.menuBar.isHidden = true
                    })
                }
            })
        }
    }
  
    func showPhotoSelector(photoSelector: PhotoSelectionController) {
        let photoSelectorNavController = UINavigationController(rootViewController: photoSelector)
        self.present(photoSelectorNavController, animated: true, completion: nil)
    }
    
    func presentPhotoPermissionController() {
        let permissionsViewController = PhotoLocationPermissionsViewController()
        permissionsViewController.isPhotos = true
        let permissionsNavController = UINavigationController(rootViewController: permissionsViewController)
        self.present(permissionsNavController, animated: true, completion: nil)
    }
    
    func showAlertViewWithTitle(title: String) {
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
    
    func showTOS() {
        let tosController = TermsOfServiceController()
        tosController.wasPushed = false
        let tosNavController = UINavigationController(rootViewController: tosController)
        tosNavController.modalPresentationStyle = .overFullScreen
        self.present(tosNavController, animated: true, completion: nil)
    }

    
}

extension LoginSignUpMainController: PasswordRecoveryCellDelegate, PasswordVerificationCellDelegate, PasswordResetCellDelegate {
    
    
    func lockScreen() {
        self.collectionView.isScrollEnabled = false
        self.menuBar.isUserInteractionEnabled = false
    }
    
    func unlockScreen() {
        self.collectionView.isScrollEnabled = true
        self.menuBar.isUserInteractionEnabled = true
    }

    
    //RESET PASSWORD
    func donePasswordReset() {
        self.currentLoginState = .normal
        UIView.animate(withDuration: 0.3, animations: {
            self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
        }) { (_) in
            self.collectionView.reloadData()

        }
    }
    
    func showResetPassword(header: [String : String]) {
        let indexPath = IndexPath(item: 4, section: 0)
        self.header = header
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    

    //VERIFICATION SCREEN
    func displayVerificationScreen(id: Int?, verificationMethod: String?) {
        
        if id != nil {
            self.id = id
        }
        if verificationMethod != nil {
            self.verificationMethod = verificationMethod
        }
       
        let indexPath = IndexPath(item: 3, section: 0)
        DispatchQueue.main.async {
            print("displaying verification")
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func backVerification() {
        endPasswordRecovery()
    }
    
    func backReset() {
        endPasswordRecovery()
    }
    
    func verificationFailed(cellIndex: Int) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.scrollToItem(at: IndexPath(item: cellIndex, section: 0), at: .centeredHorizontally, animated: true)
                if cellIndex == 1 {
                    self.menuBar.isHidden = false
                    self.menuBar.alpha = 1.0
                }
            }, completion: { (_) in
                if cellIndex == 1 {
                    self.currentLoginState = .normal
                    self.collectionView.reloadData()
                }
            })
            
        }
    }
    
    //INITIAL RECOVERY SCREEN
    func endPasswordRecovery() {
        DispatchQueue.main.async {
            self.menuBar.isHidden = false
            self.currentLoginState = .normal
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
                
                self.menuBar.alpha = 1.0
            }, completion: { (_) in
                self.collectionView.reloadData()
                self.collectionView.isScrollEnabled = true
            })
            
        }
    }
    
    
}

extension LoginSignUpMainController: LoginSignUpAlertViewDelegate {

    func dismissAlert() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.tintView.alpha = 0.0
            self.alertView.frame = CGRect(x: 40, y: self.view.frame.height, width: self.view.frame.width - 80, height: 80)
        }) { (_) in
            self.tintView.removeFromSuperview()
            self.alertView.removeFromSuperview()
        }
    }

}

extension LoginSignUpMainController: TutorialControllerDelegate {
    func completedTutorial() {
        self.loggedInSuccessfully()
    }
}
