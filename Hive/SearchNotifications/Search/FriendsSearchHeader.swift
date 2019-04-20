//
//  FriendsSearchHeader.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-03.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class FriendsSearchHeader: UICollectionViewCell {
    
    var title: String? {
        didSet {
            guard let title = title else { return }
            sectionLabel.text = title
        }
    }
    
    let sectionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    override func prepareForReuse() {
        sectionLabel.text = nil
        title = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        
        addSubview(sectionLabel)
        sectionLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        sectionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
