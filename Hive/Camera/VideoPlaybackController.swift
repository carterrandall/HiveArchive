//
//  VideoPlayback.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Alamofire

protocol VideoPlaybackControllerDelegate {
    func endSessionAfterShare()
}

class VideoPlaybackController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var delegate: VideoPlaybackControllerDelegate?

    fileprivate var didAddCaption: Bool = false
    
    fileprivate var avPlayerLayer: AVPlayerLayer!
    fileprivate var avPlayer: AVPlayer?
    
    fileprivate let videoView = UIView()
    
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    var url: URL!

    var captionView: CaptionView!
    
    let previewHUD = CameraPreviewHUD()
    
    @objc fileprivate func handleDismiss() {
        
        self.avPlayer?.pause()
        self.dismiss(animated: false) {
            self.avPlayer = nil
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        self.hideKeyboardWhenTappedOutside()
        setupViews()
    
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.avPlayer?.seek(to: CMTime.zero)
            self.avPlayer?.play()
        }
    }
    
    var bottomAlphaView: UIView!
    var centerView: UIView!
    fileprivate func setupViews() {
        view.addSubview(videoView)
        videoView.frame = view.bounds
        
        let topAlphaView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(topAlphaView)
        topAlphaView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        centerView = UIView()
        view.addSubview(centerView)
        centerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.width * (4/3))
        centerView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCaption))
        centerView.addGestureRecognizer(tap)
        
        bottomAlphaView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(bottomAlphaView)
        bottomAlphaView.anchor(top: centerView.bottomAnchor, left: view.leftAnchor, bottom : view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -10, paddingRight: 0, width: 0, height: 0)
        
        previewHUD.delegate = self
        view.addSubview(previewHUD)
        previewHUD.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        previewHUD.centerYAnchor.constraint(equalTo: bottomAlphaView.centerYAnchor, constant: -10).isActive = true
        
        navigationController?.makeTransparent()
        navigationController?.navigationBar.tintColor = .white
        let dismissButtonView: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(named: "badform"), for: .normal)
            button.tintColor = .white
            button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
            button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
            return button
        }()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButtonView)
        
    }
    

    override func viewDidAppear(_ animated: Bool) {
        avPlayer = AVPlayer(url: url!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = .resizeAspectFill
        avPlayerLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        videoView.layer.addSublayer(avPlayerLayer)
        avPlayer?.play()
    }
    
    let activityIndicator = UIActivityIndicatorView()
    
    fileprivate func saveVideoWith(url: URL) {
        self.previewHUD.saveButton.isEnabled = true
        let library = PHPhotoLibrary.shared()
        
        library.performChanges({
            
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
            
        }) { (success, err) in
            
            if let err = err {
                print("failed to save image to photo library:", err)
                return
            }
            
            print("Successfully saved image to library")
            DispatchQueue.main.async {
                self.waitingLabel.removeFromSuperview()
                self.animatePopup(title: "Successfully Saved")
            }
        }
    }

    
    var waitingLabel: UILabel!
    fileprivate func animateWaiting() {
        waitingLabel = UILabel()
        waitingLabel.text = "Saving"
        waitingLabel.font = UIFont.boldSystemFont(ofSize: 18)
        waitingLabel.textColor = .black
        waitingLabel.textAlignment = .center
        waitingLabel.backgroundColor = UIColor(white: 1, alpha: 0.5)
        waitingLabel.numberOfLines = 0
        waitingLabel.frame = CGRect(x: 0, y: 0, width: 160, height: 80)
        waitingLabel.center = self.view.center
        waitingLabel.layer.cornerRadius = 5
        
        self.view.addSubview(waitingLabel)
        
        waitingLabel.layer.transform = CATransform3DMakeScale(0, 0, 0)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.waitingLabel.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }) { (completed) in
            
            let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.animateDots), userInfo: nil, repeats: true)
            timer.fire()
            
        }
    }
    
    @objc fileprivate func animateDots() {
        switch (waitingLabel.text!) {
        case "Saving...":
            waitingLabel.text = "Saving"
        case "Saving":
            waitingLabel.text = "Saving."
        case "Saving.":
            waitingLabel.text = "Saving.."
        case "Saving..":
            waitingLabel.text = "Saving..."
        default:
            waitingLabel.text = "Saving"
        }
    }
}

extension VideoPlaybackController: CaptionViewDelegate {
    
    func didAddCaption(isText: Bool) {
        self.didAddCaption = isText
    }

}

extension VideoPlaybackController {
    //VIDEO PROCESSING
    func overlayImageOntoVideo(image: UIImage, videoURL: URL, completion: @escaping(URL) -> ())  {
        self.previewHUD.hideHUD()
        print("overlaying" )
        guard let ciimage = CIImage(image: image) else { return }
        
        let asset = AVAsset(url: videoURL)

        let filter = CIFilter(name: "CISourceOverCompositing")!
        

        let composition = AVVideoComposition(asset: asset) { (request) in
            
            let source = request.sourceImage.clampedToExtent()
        
            filter.setValue(source, forKey: kCIInputBackgroundImageKey)
            
            let scale = (request.sourceImage.extent.width / ciimage.extent.width)
           
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            filter.setValue(ciimage.transformed(by: transform), forKey: kCIInputImageKey)
            
            let output = filter.outputImage
            request.finish(with: output!, context: nil)
        }
        
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mov")
            let tempFileUrl = URL(fileURLWithPath: path)

            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset960x540)
            exportSession?.videoComposition = composition
            exportSession?.outputFileType = AVFileType.mov
            exportSession?.shouldOptimizeForNetworkUse = true
            exportSession?.outputURL = tempFileUrl
            print("exporting")
            exportSession?.exportAsynchronously(completionHandler: {
                
                if exportSession?.status == .completed {
                    print("completed export")
                    guard let outputUrl = exportSession?.outputURL else { return }
                    completion(outputUrl)
                }
                
            })
            
        }
        
    }
    
    func cropAndCompressVideo(inputURL: URL, outputURL: URL, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        //crop video
        let videoAsset: AVAsset = AVAsset(url: inputURL)
        let clipVideoTrack = videoAsset.tracks(withMediaType: .video).first! as AVAssetTrack
        
        let h = clipVideoTrack.naturalSize.height * (4/3)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: clipVideoTrack.naturalSize.height, height: h)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let miny = self.centerView.frame.minY
        let y = (clipVideoTrack.naturalSize.width / view.frame.height) * miny
        let ratio: CGFloat = view.frame.height/view.frame.width > 16/9 ? CGFloat(19.5/16) : 1.0
        let x = ((1/(2*ratio)) + 0.5)*clipVideoTrack.naturalSize.height
        
        var transformTwo: CGAffineTransform!
        if ratio != 1.0 {
            let transformZero = CGAffineTransform(scaleX: ratio, y: ratio)
            let transformOne = transformZero.translatedBy(x: CGFloat(x), y: -y)
            transformTwo = transformOne.rotated(by: CGFloat.pi / 2)
        } else {
            let transformOne = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height, y: -y)
            transformTwo = transformOne.rotated(by: CGFloat.pi / 2)
        }
        
        transformer.setTransform(transformTwo, at: CMTime.zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        print("prferred timescale", videoAsset.duration.timescale)
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: CMTime(seconds: videoAsset.duration.seconds, preferredTimescale: videoAsset.duration.timescale))
      //  instruction.timeRange =
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset960x540) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
        
    }
    
    fileprivate func viewToImage(view: UIView) -> UIImage {
        self.previewHUD.hideHUD()
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0)
        print(view.frame, "VIEW BOUNDS", self.centerView.bounds.size, "CENTER VIEW BOUNDS")
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)

        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let image1 = image.crop(rect: self.centerView.frame, withCaption: true)
        return image1
    }
    
}

extension VideoPlaybackController: CameraPreviewHUDDelegate {
    
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

    
    func handleShare() {
        
        self.registerBackgroundTask()
        
        self.avPlayer?.pause()
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
            self.delegate?.endSessionAfterShare()
            self.avPlayer = nil
            StoreReviewHelper.checkAndAskForReview()
        })
        
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
        
        self.cropAndCompressVideo(inputURL: url, outputURL: compressedURL) { (session) in
            guard let session = session else { return }
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                DispatchQueue.main.async {
                    if self.didAddCaption {
                        let image = self.viewToImage(view: self.captionView)
                        self.overlayImageOntoVideo(image: image, videoURL: compressedURL, completion: { (outUrl) in
                            DispatchQueue.main.async {
                                self.shareVideo(videoURL: outUrl)
                            }
                        })
                    } else {
                        
                        self.shareVideo(videoURL: compressedURL)
                    }
                    
                }
            case .failed:
                print(session.error as Any, "ERROR")
                print("EXPORT FAILED")
                break
            case .cancelled:
                break
            }
            
        }
        
    }
    
    func exportDidFinish(url: URL) {
        DispatchQueue.main.async {
            self.shareVideo(videoURL: url)
        }
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
    
    func shareVideo(videoURL: URL) {
        
        DispatchQueue.main.async {
            
            let filename = NSUUID().uuidString
            guard let thumbnail = videoURL.getThumnail() else { print("BAD TRHUMB"); return }
            if let videoData = try? Data(contentsOf: videoURL), let imageData = thumbnail.jpegData(compressionQuality: 0.5), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/newVideoPostForUser"), let header = UserDefaults.standard.getAuthorizationHeader() {
                
                Alamofire.upload(multipartFormData: { (multipart) in
                    multipart.append(videoData, withName: "file", fileName: "\(filename).mov", mimeType: "video/quicktime")
                    multipart.append(imageData, withName: "file", fileName: "\(filename).jpg", mimeType: "image/jpeg")
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
                        print("err uploading video")
                    }
                }
                
            }else{
                print("issue with video or photo data - Videoplaybackcontroller/sharevideo")
            }
        }

    }

    func printFileSize(url: URL) {
        let filePath = url.path
        var fileSize: UInt64
    
        do {
            
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = attr[FileAttributeKey.size] as! UInt64
            
            let dict = attr as NSDictionary
            fileSize = dict.fileSize()
            print("fileSize after:", fileSize)
            
        } catch {
            print("Error w/ filesize: \(error)")
        }
        
    }
    

    @objc func handleSave() {
        checkPhotoAuthStatus { (result) in
            DispatchQueue.main.async {
                if result {
                    self.previewHUD.saveButton.isEnabled = false
                    self.animateWaiting()
                    let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
                    
                    self.cropAndCompressVideo(inputURL: self.url, outputURL: compressedURL) { (session) in
                        guard let session = session else { return }
                        switch session.status {
                        case .unknown:
                            break
                        case .waiting:
                            break
                        case .exporting:
                            break
                        case .completed:
                            DispatchQueue.main.async {
                                if self.didAddCaption {
                                    let image = self.viewToImage(view: self.captionView)
                                    self.overlayImageOntoVideo(image: image, videoURL: compressedURL, completion: { (outUrl) in
                                        self.saveVideoWith(url: outUrl)
                                    })
                                } else {
                                    self.saveVideoWith(url: compressedURL)
                                }
                            }
                        case .failed:
                            self.previewHUD.saveButton.isEnabled = true
                            self.waitingLabel.removeFromSuperview()
                            self.animatePopup(title: "Oops! Something went wrong.")
                            print("EXPORT FAILED")
                            break
                        case .cancelled:
                            break
                        }
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
        }
    }
    
}



