//
//  LoginSignUpAlertView.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-16.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol LoginSignUpAlertViewDelegate: class {
    func dismissAlert()
}

class LoginSignUpAlertView: UIView {
    
    weak var delegate: LoginSignUpAlertViewDelegate?
    
    var title: String? {
        didSet {
            guard let title = title else { return }
            
            titleLabel.text = title
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var okayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Okay", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleOkay), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleOkay() {
       delegate?.dismissAlert()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layer.cornerRadius = 2
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: centerYAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        addSubview(okayButton)
        okayButton.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
