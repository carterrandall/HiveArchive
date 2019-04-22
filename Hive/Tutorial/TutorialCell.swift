//
//  TutorialCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-22.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class TutorialCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear //UIColor(white: 1, alpha: 0.9)
        layer.cornerRadius = 5
        
        addSubview(imageView)
        imageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.height)
        
//        setShadow(offset: CGSize(width: 0, height: 3), opacity: 0.3, radius: 3, color: UIColor.black)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
