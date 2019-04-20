//
//  CountryCodeCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-03-27.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class CountryCodeCell: UITableViewCell {

    var country: [String: String]! {
        didSet {
      
            countryNameLabel.text = country["name"]
            countryCodeLabel.text = country["dial_code"]
        }
    }
    
    override func prepareForReuse() {
        countryCodeLabel.text = nil
        countryNameLabel.text = nil
    }
    
    
    let countryNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()
    
    let countryCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(countryCodeLabel)
        countryCodeLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        addSubview(countryNameLabel)
        countryNameLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: countryCodeLabel.leftAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor.lightGray
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: countryNameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
