//
//  ChatBarCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-09.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class ChatBarCell: UICollectionViewCell {
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            
            profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        layer.cornerRadius = frame.width / 2
        
        profileImageView.layer.cornerRadius = frame.width / 2
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.width)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
