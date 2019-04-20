//
//  InviteCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-11.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class InviteCell: UICollectionViewCell {
    
    let inviteButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 65 / 2
        button.layer.borderColor = UIColor.mainBlue().cgColor
        button.layer.borderWidth = 1
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.tintColor = .mainBlue()
        button.isUserInteractionEnabled = false 
        return button
    }()
    
    let inviteLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Friends"
        label.textColor = UIColor.mainBlue()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(inviteButton)
        inviteButton.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 65, height: 65)
        inviteButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(inviteLabel)
        inviteLabel.anchor(top: nil, left: inviteButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        inviteLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
