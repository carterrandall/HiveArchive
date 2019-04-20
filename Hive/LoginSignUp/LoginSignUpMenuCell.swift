//
//  LoginSignUpMenuCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-27.
//  Copyright © 2018 Carter Randall. All rights reserved.
//


import UIKit

class LoginSignUpMenuCell: UICollectionViewCell {
    
    let screenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .lightGray
        return label
    }()
    
    override var isHighlighted: Bool {
        didSet {
            screenLabel.textColor = isHighlighted ? UIColor.mainRed() : .lightGray
        }
    }
    
    override var isSelected: Bool {
        didSet {
            screenLabel.textColor = isSelected ? UIColor.mainRed() : .lightGray
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        addSubview(screenLabel)
        screenLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

