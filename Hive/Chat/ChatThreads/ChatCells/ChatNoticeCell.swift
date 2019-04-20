//
//  ChatNoticeCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-07.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class ChatNoticeCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            guard let message = message else { return }
            var string: String!
            if let fromUsername = message.fromUser?.username {
                string = fromUsername
            }
            if message.isNotice == 0 {
                string = string + " left the group"
            } else {
                string = string + " was added to the group"
            }
            
            label.text = string
            
        }
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(label)
        label.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
