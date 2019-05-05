//
//  CameraPreviewHUD.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-17.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol CameraPreviewHUDDelegate {
    func handleSave()
    func handleCaption()
    func handleShare()
}

class CameraPreviewHUD: UIView {
    
    var delegate: CameraPreviewHUDDelegate?
    
    
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
      //  button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        button.setTitle("SAVE", for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleSave() {
        delegate?.handleSave()
    }
    
    let captionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
       // button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        button.setTitle("CAPTION", for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleCaption), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleCaption() {
        delegate?.handleCaption()
    }
    
    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("SHARE", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
       // button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShare() {
        delegate?.handleShare()
        shareButton.isEnabled = false
    }

    var toolBarStackView: UIStackView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        toolBarStackView = UIStackView(arrangedSubviews: [saveButton, captionButton, shareButton])
        toolBarStackView.axis = .horizontal
        toolBarStackView.distribution = .fillEqually
        addSubview(toolBarStackView)
        toolBarStackView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
    }
    
    func unhideHUD() {
        
        saveButton.isHidden = false
        saveButton.isEnabled = true
        shareButton.isHidden = false
        shareButton.isEnabled = true
        captionButton.isHidden = false
        captionButton.isEnabled = true
    }
    
    func hideHUD() {
        
        saveButton.isHidden = true
        saveButton.isEnabled = false
        shareButton.isHidden = true
        shareButton.isEnabled = false
        captionButton.isHidden = true
        captionButton.isEnabled = false
      
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
