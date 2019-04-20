//
//  BlockedCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-11-28.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol BlockedCellDelegate {
    func openBlocked()
}

class BlockedCell: UICollectionViewCell {
    
    var delegate: BlockedCellDelegate?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Blocked Users"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var openButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "backleft"), for: .normal)
        button.tintColor = .mainRed()
        button.addTarget(self, action: #selector(handleOpen), for: .touchUpInside)
        return button
    }()
    
    @objc func handleOpen() {
        print("handleOpen")
        delegate?.openBlocked()
    }
    
    let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(openButton)
        openButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 40, height: 40)
        openButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: titleLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
