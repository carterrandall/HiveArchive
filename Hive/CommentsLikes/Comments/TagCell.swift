//
//  TagCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-21.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class TagCell: UICollectionViewCell {
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
            usernameLabel.text = user.username
        }
    }
    
    override func prepareForReuse() {
        user = nil
        profileImageView.image = nil
        usernameLabel.text = nil
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
       // iv.backgroundColor = .blue
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "username"
        return label
    }()
    
    let container: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        view.backgroundColor = .white
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(container)
        container.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        container.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        
        
        
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
