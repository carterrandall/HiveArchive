//
//  NewChatTextView.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-30.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class NewChatTextView: UITextView {
    
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let begining = self.beginningOfDocument
        let end = self.position(from: begining, offset: self.text.count)
        return end
    }
}
