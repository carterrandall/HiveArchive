//
//  HiveMemberCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-26.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class HiveMemberCell: UICollectionViewCell {
    
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
        iv.layer.cornerRadius = 30
        return iv
    }()
    
    override func prepareForReuse() {
        user = nil
        profileImageView.image = nil
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 30
        backgroundColor = .clear 
        clipsToBounds = false
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
