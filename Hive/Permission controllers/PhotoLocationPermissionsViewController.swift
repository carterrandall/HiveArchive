//
//  PhotoPermissionsViewController.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-26.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import Photos

class PhotoLocationPermissionsViewController: UIViewController {
    
    var isPhotos: Bool? {
        didSet {
            if let isPhotos = isPhotos, isPhotos {
                label.text = "Allow Hive to access your photo library so you can customize your profile."
                settingsButton.setTitle("Allow photo access", for: .normal)
            } else {
                label.text = "Allow access to your location to begin using Hive. Only friends can see your location and you can turn off sharing in settings."
                settingsButton.setTitle("Allow location access", for: .normal)
            }
        }
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleShowSettings), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShowSettings() {
        
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
        
        let stackView = UIStackView(arrangedSubviews: [label, settingsButton])
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
