//
//  PreviewPhotoContainerView.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-06.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Photos
import Alamofire

protocol PreviewPhotoControllerDelegate {
    func endSessionAfterShare()
}

class PreviewPhotoController: UIViewController, UITextFieldDelegate {
    
    var delegate: PreviewPhotoControllerDelegate?
    var isFromCameraRoll: Bool = false
    var cropRect: CGRect?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var captionView: CaptionView!
    
    fileprivate var didAddCaption: Bool = false
    
    var image: UIImage! {
        didSet {
            self.previewImageView.image = image
        }
    }
    
    let previewImageView: UIImageView = {
        let iv = UIImageView(frame: .zero)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    let previewHUD = CameraPreviewHUD()
    
    override var prefersStatusBarHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupNavBar()
    }
    
    var bottomAlphaView: UIView!
    var centerView: UIView!
    func setupViews() {
        
        view.addSubview(previewImageView)
        
        centerView = UIView()
        view.addSubview(centerView)
        centerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.width * (4/3))
        centerView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCaption))
        centerView.addGestureRecognizer(tap)
        
        if self.isFromCameraRoll {
            previewImageView.anchor(top: centerView.topAnchor, left: centerView.leftAnchor, bottom: centerView.bottomAnchor, right: centerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.width * (4/3))
            if let image = self.image {
                let backgroundImageView = UIImageView(image: image)
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.clipsToBounds = true
                view.insertSubview(backgroundImageView, at: 0)
                backgroundImageView.frame = view.bounds
            }
        } else {
            previewImageView.frame = view.bounds
        }
        
        bottomAlphaView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(bottomAlphaView)
        bottomAlphaView.anchor(top: centerView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -10, paddingRight: 0, width: 0, height: 0)

        let topAlphaView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(topAlphaView)
        topAlphaView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(previewHUD)
        previewHUD.delegate = self
       
        previewHUD.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        previewHUD.centerYAnchor.constraint(equalTo: bottomAlphaView.centerYAnchor, constant: -10).isActive = true
        
       
        
        self.hideKeyboardWhenTappedOutside()
    }
    
    fileprivate func setupNavBar() {
        
        let dismissButtonView: UIButton = {
            let button = UIButton(type: .system)
            button.tintColor = .white
            button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
            button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
            return button
        }()
        
        if self.isFromCameraRoll {
            dismissButtonView.setImage(UIImage(named: "back"), for: .normal)
        } else {
            dismissButtonView.setImage(UIImage(named: "badform"), for: .normal)
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButtonView)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.makeTransparent()
        

    }

    
    @objc fileprivate func handleDismiss() {
        if self.isFromCameraRoll {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
  
    fileprivate func overlayImage(imageView: UIImageView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, 0.0)
        imageView.superview!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
        
    }
    
    fileprivate func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskIdentifier.invalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }
    
    //UPLOAD PHOTO TO FIREBASE
    static let updateForNewPostNotificationName = NSNotification.Name("updateForNewPost")
    func sharePhoto(image: UIImage) {
        
        
        
        var croppedImage: UIImage?
        if didAddCaption {
            croppedImage = image.crop(rect: self.centerView.frame, withCaption: true)
        } else if isFromCameraRoll {
            croppedImage = image
        } else {
            croppedImage = image.crop(rect: self.cropRect!, withCaption: false)
        }
       
        guard let uploadData = croppedImage?.jpegData(compressionQuality: 0.5) else { return }
        
        let filename = NSUUID().uuidString
        
        if let header = UserDefaults.standard.getAuthorizationHeader() {
            guard let url = URL(string: MainTabBarController.serverurl + "/Hive/api/newImagePostForUser") else { return }
            
            Alamofire.upload(multipartFormData: { (multipart) in
                multipart.append(uploadData, withName: "file", fileName: "\(filename).jpg", mimeType: "image/jpeg")
                if let captionView = self.captionView {
                    if captionView.taggedIds.count > 0 {
                        let tags = self.captionView.taggedIds
                        let arrData = try! JSONSerialization.data(withJSONObject: tags, options: .prettyPrinted)
                        multipart.append(arrData, withName: "taggedUsers")
                    }
                }
               
            }, usingThreshold: UInt64.init(), to: url, method: .post, headers: header) { (encodingResult) in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.response(completionHandler: { (response) in
                        
                        NotificationCenter.default.post(name: PreviewPhotoController.updateForNewPostNotificationName, object: nil)
                        
                        if MapRender.profileCache.object(forKey: "CachedProfile")  == nil {
                            if let postCount = MainTabBarController.currentUser?.postcount {
                                MainTabBarController.currentUser?.postcount = postCount + 1
                            }
                        }
                        
                        self.endBackgroundTask()
                    })
                    
                case .failure:
                    print("Something went wrong here sharing the photo")
                }
                
            }
        }else{
        }
    }
    
}

extension UIImage {
    func crop(rect: CGRect, withCaption: Bool) -> UIImage {

        if !withCaption {
            let imageRef = self.cgImage!.cropping(to: rect)
            let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
            print(image.size, "AFTER IMAGE SIZE")
            return image
        } else {
            var rect = rect

            rect.origin.x *= self.scale
            rect.origin.y *= self.scale
            rect.size.width *= self.scale
            rect.size.height *= self.scale

            let imageRef = self.cgImage!.cropping(to: rect)
            let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
            return image
        }
        
    }
}

extension PreviewPhotoController: CaptionViewDelegate {

    
    func didAddCaption(isText: Bool) {
        self.didAddCaption = isText
    }
    
}

extension PreviewPhotoController: CameraPreviewHUDDelegate {

    func handleShare() {
        
        self.registerBackgroundTask()
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
            StoreReviewHelper.checkAndAskForReview()
        })
        
        delegate?.endSessionAfterShare()
        
        guard let image = previewImageView.image else { return }
        
        if didAddCaption {
            let editedImage = overlayImage(imageView: previewImageView)
            sharePhoto(image: editedImage)
        } else {
            sharePhoto(image: image)
            
        }
    }

    @objc func handleCaption() {
        if let cv = captionView {
            captionView.removeFromSuperview()
            view.insertSubview(captionView, belowSubview: bottomAlphaView)
            cv.textView.becomeFirstResponder()
        } else {
            captionView = CaptionView()
            captionView.delegate = self
            captionView.frame = view.bounds
            captionView.textView.isUserInteractionEnabled = true
            view.insertSubview(captionView, belowSubview: bottomAlphaView)

        }
    }
    
    func handleSave() {
        
        print("Handling save...")
        
        var previewImage: UIImage!
        
        if didAddCaption {
            previewImage = overlayImage(imageView: previewImageView)
        } else {
            previewImage = previewImageView.image
        }
        
        var croppedImage: UIImage?
        if didAddCaption {
            croppedImage = previewImage.crop(rect: self.centerView.frame, withCaption: true)
        } else if isFromCameraRoll {
            croppedImage = previewImage
        } else {
            croppedImage = previewImage.crop(rect: self.cropRect!, withCaption: false)
        }
        guard let image = croppedImage else { return }
        
        checkPhotoAuthStatus { (result) in
            DispatchQueue.main.async {
                if result {
                    let library = PHPhotoLibrary.shared()
                    
                    
                    library.performChanges({
                        
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                        
                    }) { (success, err) in
                        
                        if let err = err {
                            print("failed to save image to photo library:", err)
                            return
                        }
                        
                        print("Successfully saved image to library")
                        
                        self.animatePopup(title: "Successfully Saved")
                        
                    }
                } else {
                    let permissionsViewController = PhotoLocationPermissionsViewController()
                    permissionsViewController.isPhotos = true
                    let permissionsNavController = UINavigationController(rootViewController: permissionsViewController)
                    self.present(permissionsNavController, animated: true, completion: nil)
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
        @unknown default:
            completion(false)
        }
    }


}
