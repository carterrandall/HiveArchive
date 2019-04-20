//
//  BlockedUserCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol BlockedUserCellDelegate {
    func unblockUser(cell: BlockedUserCell)
}

class BlockedUserCell: UICollectionViewCell {
    
    var delegate: BlockedUserCellDelegate?
    
    //profile image, username, name, block + unblock button
    
    var user: BlockedUser? {
        didSet {
            guard let user = user else { return }
            usernameLabel.text = user.username
        }
    }
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var unblockButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle("Unblock", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 2
        button.backgroundColor = .mainRed()
        button.addTarget(self, action: #selector(handleUnblock), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleUnblock() {
       
        delegate?.unblockUser(cell: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .lightGray
        
        addSubview(unblockButton)
        unblockButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 80, height: 25)
        unblockButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: unblockButton.leftAnchor, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 8, width: 0, height: 30)
        usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
