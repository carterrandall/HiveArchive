//
//  PermissionsViewController.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-29.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

class PermissionsViewController: UIViewController {
    
    var isMicrophoneEnabled: Bool = false {
        didSet {
            microphoneButton.isEnabled = !isMicrophoneEnabled
        }
    }
    
    var isCameraEnabled: Bool = false {
        didSet {
            cameraButton.isEnabled = !isCameraEnabled
        }
    }

    let shareLabel: UILabel = {
        let label = UILabel()
        label.text = "Share On Hive"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.text = "Allow Hive to access the camera and microphone so you can share on hive."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Allow camera access", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.setTitleColor(.darkGray, for: .disabled)
        button.setImage(UIImage(named: "minus")?.withRenderingMode(.alwaysOriginal), for: .disabled)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleShowSettings), for: .touchUpInside)
        return button
    }()
    
    let microphoneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Allow microphone access", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.setTitleColor(.darkGray, for: .disabled)
        button.setImage(UIImage(named: "minus")?.withRenderingMode(.alwaysOriginal), for: .disabled)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleShowSettings), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShowSettings() {
        print("handling microphone")
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { (success) in
                print("settings opened")
            }
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationController?.makeTransparent()
        let cancelButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem = cancelButton
        navigationController?.navigationBar.tintColor = .black
        
        let stackView = UIStackView(arrangedSubviews: [shareLabel, detailLabel, cameraButton, microphoneButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillProportionally
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
    }
    
    @objc fileprivate func handleCancel() {
        self.dismiss(animated: true, completion: nil)
    }
   
}
