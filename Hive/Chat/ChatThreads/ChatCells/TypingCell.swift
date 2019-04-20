//
//  TypingCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-31.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class TypingCell: UITableViewCell, CAAnimationDelegate {
    
    var user: User? {
        didSet {
            guard let user = user else { return }
            profileImageView.profileImageCache(url: user.profileImageUrl, userId: user.uid)
        }
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: frame.height, height: frame.height)
        profileImageView.layer.cornerRadius = frame.height / 2
 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animateScale() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSNumber(floatLiteral: 1.2)
        scaleAnimation.toValue = NSNumber(floatLiteral: 0.8)
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleAnimation.duration = 0.5
        scaleAnimation.repeatCount = HUGE
        scaleAnimation.autoreverses = true
        profileImageView.layer.add(scaleAnimation, forKey: "scale")
    }
    

}
