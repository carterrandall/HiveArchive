//
//  InvalidHiveView.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-02.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol InvalidHiveViewDelegate: class {
    func closeInvalidHiveView()
}

class InvalidHiveView: UIView {
    
    weak var delegate: InvalidHiveViewDelegate?
    
    var infraction: String? {
        didSet {
            switch infraction {
            case "Both":
                titleLabel.text = "Too far away and too big!"
            case "radius":
                titleLabel.text = "Too big!"
            case "distance":
                titleLabel.text = "Too far away!"
            case "Name":
                titleLabel.text = "Hive names can only contain letters, spaces, numbers and hyphens."
            default:
                titleLabel.text = "Please try a different size/location or name."
            }
        }
    }
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    
    let hiveRestrictionDismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Okay", for: .normal)
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleHiveRestrictionDismissButton), for: .touchUpInside)
        return button
    }()
    
    @objc func handleHiveRestrictionDismissButton() {
        delegate?.closeInvalidHiveView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        layer.cornerRadius = 2
        setShadow(offset: CGSize(width: 0, height: 1.5), opacity: 0.3, radius: 3, color: UIColor.black)
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 60)
        addSubview(hiveRestrictionDismissButton)
        hiveRestrictionDismissButton.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
