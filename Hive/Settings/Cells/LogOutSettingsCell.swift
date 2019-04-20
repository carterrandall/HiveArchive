//
//  LogOutSettingsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-26.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol LogOutSettingsCellDelegate {
    func didTapLogout()
}

class LogOutSettingsCell: UICollectionViewCell {
    
    var delegate: LogOutSettingsCellDelegate?
    
    lazy var logoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log Out", for: .normal)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.addTarget(self, action: #selector(handleLogOut), for: .touchUpInside)
        button.layer.cornerRadius = 5 
        return button
    }()
    
    @objc func handleLogOut() {
        
        delegate?.didTapLogout()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(logoutButton)
        logoutButton.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 60, paddingBottom: 0, paddingRight: 60, width: 0, height: 40)
        logoutButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
