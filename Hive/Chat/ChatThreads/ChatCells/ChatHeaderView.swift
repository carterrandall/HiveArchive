//
//  ChatHeaderView.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-31.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class HeaderContainerView: UITableViewHeaderFooterView {
    
    let label = ChatHeaderView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        let backgroundView = UIView(frame: self.bounds)
        backgroundView.backgroundColor = .clear
        self.backgroundView = backgroundView
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
}

class ChatHeaderView: UILabel {
    
    override var intrinsicContentSize: CGSize {
        font = UIFont.boldSystemFont(ofSize: 14)

        let originalContentSize = super.intrinsicContentSize
        layer.cornerRadius = (originalContentSize.height + 12) / 2
        clipsToBounds = true
        return CGSize(width: originalContentSize.width + 20, height: originalContentSize.height + 12)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        textColor = .lightGray
        textAlignment = .center
        transform = CGAffineTransform(scaleX: 1, y: -1)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
