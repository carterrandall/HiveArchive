//
//  ProfileEditAddButton.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-17.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

enum FriendState {
    case friends, currentRequested, otherRequested, noRelation, currentUser //0,1,2,3,n/a
}

protocol ProfileEditAddButtonDelegate: class {
    func editProfile()
    func changeFriendStatus()
}

class ProfileEditAddButton: UIButton {
    
    weak var delegate: ProfileEditAddButtonDelegate?
    
    var friendState: FriendState = .currentUser {
        didSet {
            switch friendState {
            case .friends:
                setImage(UIImage(named: "minus"), for: .normal)
            case .currentRequested:
                setImage(UIImage(named: "pending"), for: .normal)
            case .otherRequested:
                print("show indicator view")
            case .noRelation:
                setImage(UIImage(named: "add"), for: .normal)
            default:
                setImage(UIImage(named: "edit"), for: .normal)
           
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(handleTouch), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func handleTouch() {
        DispatchQueue.main.async {
            if self.friendState == .currentUser {
                self.delegate?.editProfile()
            } else {
                self.delegate?.changeFriendStatus()
            }
        }
        
    }
   
}
