//
//  MenuBarCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class MenuBarCell: UICollectionViewCell {
    
    let screenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    override var isHighlighted: Bool {
        didSet {
            screenLabel.textColor = isHighlighted ? .mainRed() : .black
        }
    }
    
    override var isSelected: Bool {
        didSet {
            screenLabel.textColor = isSelected ? .mainRed() : .black
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        addSubview(screenLabel)
        screenLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
