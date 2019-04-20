//
//  HiveCameraController.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

//
//  HiveCameraController.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation
import CallKit

class HiveCameraController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate, CXCallObserverDelegate {
    
    enum CameraSelection {
        case rear, front
    }
    
    enum CurrentFlashMode {
        case off, on, auto
    }
    
    enum RecordingState {
        case recording, notRecording
    }
    
    let session = AVCaptureSession()
    
    fileprivate var previewLayer: PreviewView!
    
    fileprivate var videoDevice: AVCaptureDevice?
    
    fileprivate var photoOutput = AVCapturePhotoOutput()
    
    fileprivate var movieOutput = AVCaptureMovieFileOutput()
    
    fileprivate var movieOutputURL: URL!
    
    fileprivate var videoInput: AVCaptureDeviceInput!
    
    fileprivate var currentCameraPosition = CameraSelection.rear
    
    fileprivate var recordingState = RecordingState.notRecording
    
    fileprivate let minimumZoom: CGFloat = 1.0
    
    fileprivate let maximumZoom: CGFloat = 6.0
    
    fileprivate var lastZoomFactor: CGFloat = 1.0
    
    fileprivate var previousPanTranslation = 0.0
    
    fileprivate var isTorchAndFlashReadyForCapture: Bool = false
    
    fileprivate var wasOnPhoneDuringSetup: Bool = false
    
    fileprivate let callObserver = CXCallObserver()
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        
        if call.hasConnected && !(call.hasEnded) {
            print("dismissing controller")
            self.dismiss(animated: false, completion: nil) //connected. dismiss so if opens again we configure with no audio
        }
        
        if !(call.isOutgoing && call.hasConnected && call.hasEnded) {
            print("incoming") //works fine dont need todo anything here
        }
        
        if call.isOutgoing && !(call.hasConnected) {
            print("Dialing") //need to test
        }
        
        if call.hasEnded {
            
            print("disconnected")
            
            DispatchQueue.main.async {
                
                self.navigationItem.title = nil
                
                self.hiveCameraButton.isOnPhone = false
                
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .duckOthers)
                } catch {
                    print("error settings audio")
                    self.dismiss(animated: true, completion: nil)
                }
                
                let audioDevice = AVCaptureDevice.default(for: .audio)
                guard let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!), self.session.canAddInput(audioDeviceInput) else { return }
                self.session.addInput(audioDeviceInput)
            }
            
        }
        
    }
    
    let hiveCameraButton: HiveCameraButton = {
        let button = HiveCameraButton()
        button.tintColor = .white
        return button
    }()
    
    let torchButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleToggleTorch), for: .touchUpInside)
        button.setImage(UIImage(named:"flashOff"), for: .normal)
        button.tintColor = .white
        button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return button
    }()
    
    let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleSwitchCamera), for: .touchUpInside)
        button.setImage(UIImage(named:"switchCamera"), for: .normal)
        button.tintColor = .white
        button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callObserver.setDelegate(self, queue: nil)
        
        view.backgroundColor = .black
        
        setupPreviewLayer()
        
        setupGestureRecognizers()
        
        self.setupCaptureSession()
        
        setupHUD()
        
        
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        session.startRunning()
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var centerView: UIView!
    fileprivate func setupHUD() {
        
        //        let imageView = UIImageView(image: UIImage(named: "indian"))
        //        imageView.contentMode = .scaleAspectFill
        //        imageView.frame = view.bounds
        //        view.addSubview(imageView)
        
        self.navigationController?.makeTransparent()
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        let dismissButtonView: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(named: "cancel"), for: .normal)
            button.tintColor = .white
            button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
            button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
            return button
        }()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButtonView)
        navigationController?.navigationBar.tintColor = .white
        
        let topView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(topView)
        topView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        centerView = UIView()
        view.addSubview(centerView)
        centerView.isUserInteractionEnabled = false
        centerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.width * (4/3))
        
        let bottomView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(bottomView)
        bottomView.anchor(top: centerView.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -10, paddingRight: 0, width: 0, height: 0)
        
        hiveCameraButton.delegate = self
        view.addSubview(hiveCameraButton)
        let buttonDim = view.frame.width * 0.1449275362
        hiveCameraButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: buttonDim, height: buttonDim)
        hiveCameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hiveCameraButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).isActive = true
        hiveCameraButton.layer.cornerRadius = buttonDim / 2
        
        view.addSubview(torchButton)
        torchButton.anchor(top: nil, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 40, width: 40, height: 40)
        torchButton.centerYAnchor.constraint(equalTo: hiveCameraButton.centerYAnchor).isActive = true
        
        view.addSubview(switchCameraButton)
        switchCameraButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 40, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        switchCameraButton.centerYAnchor.constraint(equalTo: hiveCameraButton.centerYAnchor).isActive = true
        
        
    }
    
    @objc fileprivate func handleToggleTorch() {
        toggleTorchStatus()
    }
    
    fileprivate func toggleTorchStatus() {
        
        if isTorchAndFlashReadyForCapture {
            
            isTorchAndFlashReadyForCapture = false
            torchButton.setImage(UIImage(named: "flashOff"), for: .normal)
            
        } else {
            
            isTorchAndFlashReadyForCapture = true
            torchButton.setImage(UIImage(named: "flashOn"), for: .normal)
            
        }
        
    }
    
    @objc fileprivate func handleSwitchCamera() {
        switchCamera()
    }
    
    @objc fileprivate func handleDismiss() {
        
        self.dismiss(animated: true) {
            self.endSession()
        }
    }
    
    fileprivate func setupPreviewLayer() {
        
        previewLayer = PreviewView()
        previewLayer.contentMode = .scaleAspectFill
        previewLayer.center = view.center
        
        view.addSubview(previewLayer)
        previewLayer.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        view.sendSubviewToBack(previewLayer)
        
        previewLayer.session = session
        
    }
    
    fileprivate func setupGestureRecognizers() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(pinch:)))
        pinchGesture.delegate = self
        previewLayer.addGestureRecognizer(pinchGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        previewLayer.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        previewLayer.addGestureRecognizer(doubleTapGesture)
        
    }
    
    @objc fileprivate func pinchGesture(pinch: UIPinchGestureRecognizer) {
        
        var input: AVCaptureDeviceInput!
        
        if wasOnPhoneDuringSetup {
            input = session.inputs[0] as? AVCaptureDeviceInput
        } else {
            input = session.inputs[1] as? AVCaptureDeviceInput
        }
        
        guard let captureDevice = input?.device else { return }
        
        //return zoom factor
        func minMaxZoom(_ zoomFactor: CGFloat) -> CGFloat {
            return min(min(max(zoomFactor, minimumZoom), maximumZoom), captureDevice.activeFormat.videoMaxZoomFactor)
        }
        
        func updateZoom(zoom factor: CGFloat) {
            
            do {
                
                try captureDevice.lockForConfiguration()
                defer { captureDevice.unlockForConfiguration() }
                captureDevice.videoZoomFactor = factor
                
            } catch {
                print("error locking configuration")
            }
            
        }
        
        let newZoomFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        
        switch pinch.state {
        case .began: fallthrough
        case .changed: updateZoom(zoom: newZoomFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newZoomFactor)
            updateZoom(zoom: lastZoomFactor)
        default:
            break
        }
        
    }
    
    @objc func singleTapGesture(tap: UITapGestureRecognizer) {
        
        
        
        let screenSize = previewLayer!.bounds.size
        let tapPoint = tap.location(in: previewLayer)
        let x = tapPoint.y / screenSize.height
        let y = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x: x, y: y)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try captureDevice.lockForConfiguration()
            
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = focusPoint
                captureDevice.focusMode = .autoFocus
            }
            
            captureDevice.exposurePointOfInterest = focusPoint
            captureDevice.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            
            captureDevice.unlockForConfiguration()
        } catch {
            print("error locking for configuration")
        }
    }
    
    @objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
        
        switchCamera()
        
    }
    
    fileprivate func switchCamera() {
        var currentCameraInput: AVCaptureDeviceInput!
        if wasOnPhoneDuringSetup {
            currentCameraInput = session.inputs[0] as? AVCaptureDeviceInput
        } else {
            currentCameraInput = session.inputs[1] as? AVCaptureDeviceInput
        }
        
        self.session.removeInput(currentCameraInput)
        
        var newCamera = AVCaptureDevice.default(for: .video)
        
        if currentCameraInput.device.position == .back {
            
            newCamera = self.cameraWithPosition(.front)
            self.currentCameraPosition = .front
            switchCameraButton.setImage(UIImage(named: "switchCamera1"), for: .normal)
            
        } else {
            
            newCamera = self.cameraWithPosition(.back)
            self.currentCameraPosition = .rear
            self.switchCameraButton.setImage(UIImage(named: "switchCamera"), for: .normal)
            
        }
        
        do {
            
            try self.session.addInput(AVCaptureDeviceInput(device: newCamera!))
            
        } catch {
            print("error adding input to session")
        }
        
    }
    
    func cameraWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        for device in deviceDescoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    
    fileprivate func setupCaptureSession() {
        session.automaticallyConfiguresApplicationAudioSession = false
        session.beginConfiguration()
        addAudioInput() //video is configured after audio so that is placed in second index in session inputs (useful for swtching camera)
        configureVideoOutput()
        configurePhotoOutput()
        
        session.commitConfiguration()
        
    }
    
    fileprivate func configureVideoPresetAndInput() {
        
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try videoDevice.lockForConfiguration()
            
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
                
                if videoDevice.isSmoothAutoFocusSupported {
                    videoDevice.isSmoothAutoFocusEnabled = true
                }
                
            }
            
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            if videoDevice.isLowLightBoostSupported {
                videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
        } catch {
            print("could not lock configuration")
        }
        
        
        //add inputs
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice), session.canAddInput(videoDeviceInput) else { return }
        session.addInput(videoDeviceInput)
        videoInput = videoDeviceInput
        
    }
    
    fileprivate func addAudioInput() {
        
        if isOnPhone() {
            
            navigationItem.title = "VIDEO DISABLED"
            hiveCameraButton.isOnPhone = true
            wasOnPhoneDuringSetup = true
            setupNoAudioButton()
            configureVideoPresetAndInput()
            
        } else {
            navigationItem.title = nil
            
            do {
                _ = try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .mixWithOthers)
            }
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            guard let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!), session.canAddInput(audioDeviceInput) else { return }
            session.addInput(audioDeviceInput)
            print("Added audio")
            configureVideoPresetAndInput()
        }
        
    }
    
    fileprivate func isOnPhone() -> Bool {
        for call in CXCallObserver().calls {
            if call.hasEnded == false {
                return true
            }
        }
        return false
    }
    
    fileprivate func setupNoAudioButton() {
        print("Showing no audio button")
    }
    
    fileprivate func configureVideoOutput() {
        
        guard session.canAddOutput(movieOutput) else { return }
        session.addOutput(movieOutput)
        
    }
    
    fileprivate func configurePhotoOutput() {
        
        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)
        
    }
    
    //MARK: button delegate methods
    
    //PHOTOS
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("DID FINISH PROCESSING PHOTO")
        
        if recordingState == .recording {print("return 1"); return }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        guard let previewImage = UIImage(data: imageData) else { return }
        self.showPreviewPhotoController(previewImage: previewImage)
        
    }
    
    fileprivate func showPreviewPhotoController(previewImage: UIImage) {
        
        let previewPhotoController = PreviewPhotoController()
        previewPhotoController.delegate = self
        
        if currentCameraPosition == .front {
            
            let flippedPreviewImage = UIImage(cgImage: (previewImage.cgImage)!, scale: 1.0, orientation: UIImage.Orientation.leftMirrored)
            
            previewPhotoController.image = flippedPreviewImage
            
        } else {
            previewPhotoController.image = previewImage
        }
        print("PreviewPhotoController")
        let previewNavController = UINavigationController(rootViewController: previewPhotoController)
        present(previewNavController, animated: false) {
            let r = self.previewLayer.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: self.centerView.frame)
            let cgImage = previewImage.cgImage!
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)
            let cropRect = CGRect(x: r.origin.x * width, y: r.origin.y * height, width: r.size.width * width, height: r.size.height * height)
            previewPhotoController.cropRect = cropRect
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }
    
    fileprivate func endSession() {
        let inputs = self.session.inputs
        
        for input in inputs {
            self.session.removeInput(input)
        }
    }
    
    //VIDEOS
    
    fileprivate func toggleTorch() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        if captureDevice.hasTorch {
            self.session.beginConfiguration()
            
            if !(captureDevice.isTorchActive) {
                self.torchOn(device: captureDevice)
            } else {
                self.torchOff(device: captureDevice)
            }
            
            self.session.commitConfiguration()
        }
    }
    
    fileprivate func torchOn(device: AVCaptureDevice) {
        do {
            if device.hasTorch {
                
                try device.lockForConfiguration()
                device.torchMode = .on
                device.unlockForConfiguration()
            }
            
        } catch {
            print("error locking configuration")
        }
    }
    
    fileprivate func torchOff(device: AVCaptureDevice) {
        
        do {
            if device.hasTorch {
                
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            
        } catch {
            print("error locking configuration")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            print("Error recording movie: ", error ?? "")
        }
        
        let asset = AVAsset(url: outputFileURL)
        if asset.duration.seconds < 1.5 {
            
            guard let photo = movieOutputURL.getThumnail() else {print("return 2"); return }
            
            self.showPreviewPhotoController(previewImage: photo)
            
        } else {
            
            let videoRecordedURL = movieOutputURL! as URL
            let videoPlaybackController = VideoPlaybackController()
            videoPlaybackController.delegate = self
            videoPlaybackController.url = videoRecordedURL
            let videoNavController = UINavigationController(rootViewController: videoPlaybackController)
            videoNavController.modalPresentationStyle = .overFullScreen
            present(videoNavController, animated: false, completion: nil)
            
        }
        
        self.movieOutputURL = nil
        recordingState = .notRecording
        
    }
}

extension URL {
    func getThumnail() -> UIImage? {
        let asset: AVAsset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 0, timescale: 60)
        var actualTime = CMTimeMake(value: 0, timescale: 0)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            let image = UIImage(cgImage: thumbnailImage)
            print("GOT THUMBNAIL IMAGE")
            return image
        } catch let err as NSError {
            print("COULDINT GET THUMB", err.localizedDescription)
            return nil
        }
    }
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        let previewLayer = layer as! AVCaptureVideoPreviewLayer
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return previewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        } set {
            videoPreviewLayer.session = newValue
        }
    }
    
    
}

extension HiveCameraController: HiveCameraButtonDelegate {
    
    func didTapButton() {
        takePhoto()
    }
    
    fileprivate func takePhoto() {
        print("taking photo")
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        var photoOutputSettings: AVCapturePhotoSettings!
        
        if isTorchAndFlashReadyForCapture {
            photoOutputSettings = getPhotoSettings(camera: captureDevice, flashMode: .on)
        } else {
            photoOutputSettings = getPhotoSettings(camera: captureDevice, flashMode: .off)
        }
        
        guard let previewFormatType = photoOutputSettings.availablePreviewPhotoPixelFormatTypes.first else { return }
        
        photoOutputSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewFormatType]
        
        photoOutput.capturePhoto(with: photoOutputSettings, delegate: self)
        
    }
    
    func getPhotoSettings(camera: AVCaptureDevice, flashMode: CurrentFlashMode) -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        
        if camera.hasFlash {
            switch flashMode {
            case .off: photoSettings.flashMode = .off
            case .on: photoSettings.flashMode = .on
            default: photoSettings.flashMode = .off
            }
        }
        
        return photoSettings
    }
    
    
    
    
    func didBeginLongButtonPress() {
        
        DispatchQueue.main.async {
            self.recordingState = .recording
            self.beginRecording()
            self.animateRecording()
        }
        
    }
    
    fileprivate func beginRecording() {
        
        if !movieOutput.isRecording {
            
            if let dismissButton = navigationItem.leftBarButtonItem {
                dismissButton.customView?.alpha = 0.0
                dismissButton.isEnabled = false
            }
            
            switchCameraButton.isEnabled = false
            switchCameraButton.tintColor = .clear
            torchButton.isEnabled = false
            torchButton.tintColor = .clear
            
            movieOutputURL = tempURL()
            
            movieOutput.startRecording(to: movieOutputURL, recordingDelegate: self)
            
            if isTorchAndFlashReadyForCapture {
                toggleTorch()
            }
            
        } else {
            stopRecording()
        }
        
    }
    
    fileprivate func animateRecording() {
        
        //pulse
        let pulse = Pulsing(numberOfPulses: 10, radius: 60, position: hiveCameraButton.center)
        pulse.animationDuration = 1
        pulse.backgroundColor = UIColor.mainRed().cgColor
        pulse.name = "pulse"
        
        view.layer.insertSublayer(pulse, below: hiveCameraButton.layer)
        
        //progress bar
        let progressBar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0))
        progressBar.backgroundColor = UIColor.mainRed()
        view.addSubview(progressBar)
        progressBar.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: 0)
        let progressBarBottom = progressBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: view.safeAreaInsets.top)
        progressBarBottom.isActive = true
        
        progressBarBottom.constant = 0
        UIView.animate(withDuration: 10, delay: 0, options: .curveLinear, animations: {
            self.view.layoutIfNeeded()
        }) { (completed) in
            progressBar.removeFromSuperview()
        }
    }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    //    func didPanFromButton(pan: UIPanGestureRecognizer)
    func didPanFromButton(pan: UIPanGestureRecognizer) {
        
        let currentPanTranslation = pan.translation(in: previewLayer).y
        
        let panTranslationDifference = -(currentPanTranslation - CGFloat(previousPanTranslation))
        
        var input: AVCaptureDeviceInput!
        if wasOnPhoneDuringSetup {
            input = session.inputs[0] as? AVCaptureDeviceInput
        } else {
            input = session.inputs[1] as? AVCaptureDeviceInput
        }
        
        guard let captureDevice = input?.device else { return }
        
        //return zoom factor
        func minMaxZoom(_ zoomFactor: CGFloat) -> CGFloat {
            return min(min(max(zoomFactor, lastZoomFactor), maximumZoom), captureDevice.activeFormat.videoMaxZoomFactor)
        }
        
        func updateZoom(zoom factor: CGFloat) {
            
            do {
                
                try captureDevice.lockForConfiguration()
                defer { captureDevice.unlockForConfiguration() }
                captureDevice.videoZoomFactor = factor
                
            } catch {
                print("error locking configuration")
            }
            
        }
        
        let newZoomFactor = minMaxZoom((panTranslationDifference / 75) * lastZoomFactor)
        
        switch pan.state {
        case .began: fallthrough
        case .changed: updateZoom(zoom: newZoomFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newZoomFactor)
            updateZoom(zoom: lastZoomFactor)
        default:
            break
        }
        
    }
    
    func didEndLongButtonPress() {
        print("did end long button press")
        DispatchQueue.main.async {
            self.stopRecording()
        }
    }
    
    fileprivate func removeAnimations() {
        self.view.subviews.forEach({$0.layer.removeAllAnimations()})
        self.view.layer.removeAllAnimations()
        
        self.view.layer.sublayers?.forEach({ (layer) in
            if layer.name == "pulse" {
                layer.removeFromSuperlayer()
            }
        })
    }
    
    func longPressDidReachMaximumDuration() {
        
        stopRecording()
    }
    
    fileprivate func stopRecording() {
        
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            print("no big deal")
        }
        
        self.recordingState = .notRecording
        if let dismissButton = navigationItem.leftBarButtonItem {
            dismissButton.customView?.alpha = 1.0
            dismissButton.isEnabled = true
        }
        
        switchCameraButton.isEnabled = true
        switchCameraButton.tintColor = .white
        torchButton.isEnabled = true
        torchButton.tintColor = .white
        
        if isTorchAndFlashReadyForCapture {
            toggleTorch()
        }
        
        removeAnimations()
        
    }
}

extension HiveCameraController: PreviewPhotoControllerDelegate, VideoPlaybackControllerDelegate {
    
    func endSessionAfterShare() {
        self.endSession()
    }
    
}





