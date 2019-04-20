//
//  LocationSettingsCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-25.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class LocationSettingsCell: UICollectionViewCell {
    
    var ghost: Bool? {
        didSet {
            if let ghost = ghost, ghost {
                self.switchControl.isOn = true
                detailLabel.text = "Your location is not visible to anyone."
            } else {
                self.switchControl.isOn = false
                detailLabel.text = "Your location is visible to friends."
            }
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Location Privacy"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    let seperatorView: UIView = {
        
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
        
    }()
    
    let showMyLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "Ghost Mode"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    lazy var switchControl: UISwitch = {
        let sc = UISwitch()
        sc.onTintColor = .mainRed()
        sc.addTarget(self, action: #selector(handleSwitch), for: .valueChanged)
        return sc
    }()
    
    @objc func handleSwitch() {
        var ghost: Bool!
        if switchControl.isOn {
            ghost = true
            detailLabel.text = "Your location is not visible to anyone."
        } else {
            ghost = false
            detailLabel.text = "Your location is visible to friends."
        }
        
        let params = ["ghost": ghost] as [String: Bool]
        RequestManager().makeResponseRequest(urlString: "/Hive/api/toggleGhostMode", params: params) { (response) in
            if response.response?.statusCode == 200 {
                print("all good")
            } 
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 8, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(showMyLocationLabel)
        showMyLocationLabel.anchor(top: titleLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        
        addSubview(switchControl)
        switchControl.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 0, height: 0)
        switchControl.centerYAnchor.constraint(equalTo: showMyLocationLabel.centerYAnchor).isActive = true
        
        addSubview(detailLabel)
        detailLabel.anchor(top: nil, left: showMyLocationLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 8, paddingRight: 20, width: 0, height: 0)
        
        addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: titleLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 1)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
