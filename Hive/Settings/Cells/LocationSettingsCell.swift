//
//  LocationSettingsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-25.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol LocationSettingsCellDelegate: class {
    func toggleGhost(ghost: Bool)
    func showChooseFriends()
}

class LocationSettingsCell: UICollectionViewCell {
    
    weak var delegate: LocationSettingsCellDelegate?
    
    var ghost: Bool? {
        didSet {
            guard let ghost = ghost else { return }
            if ghost {
                self.chooseFriendsButton.isHidden = true
                self.ghostSwitchControl.isOn = true
                ghostDetailLabel.text = "Your location is not visible to anyone."
            } else {
                self.chooseFriendsButton.isHidden = false
                self.ghostSwitchControl.isOn = false
                ghostDetailLabel.text = "Your location is visible to friends."
            }
        }
    }
    
    var privateProfile: Bool? {
        didSet {
            if let pp = privateProfile, pp {
                self.privateSwitchControl.isOn = true
                privateDetailLabel.text = "Your profile is only visible to friends."
            } else {
                self.privateSwitchControl.isOn = false
                privateDetailLabel.text = "Everyone can view your profile."
            }
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Privacy"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let privateLabel: UILabel = {
        let label = UILabel()
        label.text = "Private Profile"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let privateDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()
    
    lazy var privateSwitchControl: UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.addTarget(self, action: #selector(handleSwitchPrivate), for: .valueChanged)
        return sc
    }()
    
    @objc fileprivate func handleSwitchPrivate() {
        print("switching private")
        var pp: Bool!
        if privateSwitchControl.isOn {
            pp = true
            privateDetailLabel.text = "Your profile is only visible to friends."
        } else {
            pp = false
            privateDetailLabel.text = "Everyone can view your profile."
        }
        
        let params = ["bool": pp] as [String: Bool]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/togglePrivateProfile", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("all good on making the profi private/not private dude")
            } else {
                print("response", response)
            }
        }
    }
    
    let showMyLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "Ghost Mode"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let ghostDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()
    
    lazy var ghostSwitchControl: UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.addTarget(self, action: #selector(handleSwitchGhost), for: .valueChanged)
        return sc
    }()
    
    @objc func handleSwitchGhost() {
        var ghost: Bool!
        if ghostSwitchControl.isOn {
            ghost = true
            ghostDetailLabel.text = "Your location is not visible to anyone."
        } else {
            ghost = false
            ghostDetailLabel.text = "Your location is visible to friends you choose."
        }
        
        self.delegate?.toggleGhost(ghost: ghost)
        
        let params = ["ghost": ghost] as [String: Bool]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/toggleGhostMode", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("all good")
            } 
        }
    }
    
    let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
    }()
    
    lazy var chooseFriendsButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .mainRed()
        button.setTitle("Choose Friends For Location Sharing", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleChooseFriends), for: .touchUpInside)
        button.titleLabel?.textAlignment = .left
        return button
    }()
    
    @objc fileprivate func handleChooseFriends() {
        delegate?.showChooseFriends()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(privateLabel)
        privateLabel.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(privateSwitchControl)
        privateSwitchControl.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        privateSwitchControl.centerYAnchor.constraint(equalTo: privateLabel.centerYAnchor, constant: 10).isActive = true
        
        addSubview(privateDetailLabel)
        privateDetailLabel.anchor(top: privateLabel.bottomAnchor, left: privateLabel.leftAnchor, bottom: nil, right: privateSwitchControl.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 8, paddingRight: 0, width: 0, height: 0)
        
        addSubview(showMyLocationLabel)
        showMyLocationLabel.anchor(top: privateDetailLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(ghostSwitchControl)
        ghostSwitchControl.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        ghostSwitchControl.centerYAnchor.constraint(equalTo: showMyLocationLabel.centerYAnchor, constant: 10).isActive = true
        
        addSubview(ghostDetailLabel)
        ghostDetailLabel.anchor(top: showMyLocationLabel.bottomAnchor, left: showMyLocationLabel.leftAnchor, bottom: nil, right: ghostSwitchControl.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: titleLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        addSubview(chooseFriendsButton)
        chooseFriendsButton.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 8, paddingRight: 0, width: 0, height: 40)
        chooseFriendsButton.isHidden = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
