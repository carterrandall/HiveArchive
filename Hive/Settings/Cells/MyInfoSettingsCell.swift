//
//  MyInfoSettingsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-25.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol MyInfoSettingsCellDelegate {
    func didClickEdit(editing: String)
    func didClickEditPassword()
}

class MyInfoSettingsCell: UICollectionViewCell {
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            usernameLabel.text = "Username: " + user.username
            nameLabel.text = "Name: " + user.fullName
        }
    }
    
    var delegate: MyInfoSettingsCellDelegate?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "My Info"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
       
        label.font = UIFont.systemFont(ofSize: 14)
        return label
        
    }()
    
    lazy var editUsernameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleEditUsername), for: .touchUpInside)
        return button
    }()
    
    @objc func handleEditUsername() {
        print("Editing username")
        delegate?.didClickEdit(editing: "username")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var editNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleEditName), for: .touchUpInside)
        return button
    }()
    
    @objc func handleEditName() {
        delegate?.didClickEdit(editing: "fullName")
    }
    
    let passwordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Password"
        return label
    }()
    
    lazy var passwordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleEditPassword), for: .touchUpInside)
        return button
    }()
    
    @objc func handleEditPassword() {
        delegate?.didClickEditPassword()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(editUsernameButton)
        editUsernameButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 50, height: 40)
        editUsernameButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
        
        addSubview(editNameButton)
        editNameButton.anchor(top: editUsernameButton.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 50, height: 40)
        
        addSubview(nameLabel)
        nameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        nameLabel.centerYAnchor.constraint(equalTo: editNameButton.centerYAnchor).isActive = true
        
        addSubview(passwordButton)
        passwordButton.anchor(top: editNameButton.bottomAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 50, height: 40)
        
        addSubview(passwordLabel)
        passwordLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        passwordLabel.centerYAnchor.constraint(equalTo: passwordButton.centerYAnchor).isActive = true
        
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: titleLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
