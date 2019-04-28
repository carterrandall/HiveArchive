//
//  HiveCameraButton.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol HiveCameraButtonDelegate {
    func didTapButton()
    func didBeginLongButtonPress()
    func didPanFromButton(pan: UIPanGestureRecognizer)
    func didEndLongButtonPress()
    func longPressDidReachMaximumDuration()
}

class HiveCameraButton: UIButton, UIGestureRecognizerDelegate {
    
    var isOnPhone: Bool = false
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UILongPressGestureRecognizer) && (otherGestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UILongPressGestureRecognizer) {
            return true
        } else {
            return false
        }
    }
    
    var delegate: HiveCameraButtonDelegate?
    
    fileprivate var timer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupAppearance()
        setupGestureRecognizers()
        
        NotificationCenter.default.addObserver(self, selector: #selector(volumePress(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_AudioVolumeChangeReasonNotificationParameter"), object: nil)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func volumePress(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let volumeChangeType = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
                print(volumeChangeType, "volume Change type")
            } else {
                print("gay")
            }
        } else {
            print("homo")
        }
    }
    
    fileprivate func setupAppearance() {
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        
    }
    
    fileprivate func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraButtonTap))
        self.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.delegate = self
        self.addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(pan:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
    
    @objc fileprivate func panGesture(pan: UIPanGestureRecognizer) {
        delegate?.didPanFromButton(pan: pan)
    }
    
    
    @objc fileprivate func cameraButtonTap() {
        delegate?.didTapButton()
    }
    
    @objc fileprivate func longPress(_ sender: UILongPressGestureRecognizer!) {
        
        if !isOnPhone {
            switch sender.state {
            case .began:
                DispatchQueue.main.async {
                    self.delegate?.didBeginLongButtonPress()
                    self.startTimer()
                }
                
            case .ended:
                DispatchQueue.main.async {
                    self.delegate?.didEndLongButtonPress()
                    self.invalidateTimer()
                }
            default:
                break
            }
        }
        
    }
    
    
    fileprivate func startTimer() {
        let duration = 10.0
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector:  #selector(timerFinished), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func timerFinished() {
        invalidateTimer()
        delegate?.longPressDidReachMaximumDuration()
    }
    
    fileprivate func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
