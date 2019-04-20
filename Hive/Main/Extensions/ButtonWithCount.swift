//
//  ButtonWithCount.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-03.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

class ButtonWithCount: UIButton {
    
    var count: Int? {
        didSet {
            if let count = count, count > 0 {
                countLabel.text = String(count)
                countView.isHidden = false
                countLabel.isHidden = false
                if count > 99 {
                    countLabel.font = UIFont.boldSystemFont(ofSize: 10)
                } else {
                    countLabel.font = UIFont.boldSystemFont(ofSize: 12)
                }
            } else if count == -1 {
                countView.isHidden = false
                countLabel.isHidden = false
                countLabel.text = " "
            } else {
                countView.isHidden = true
                countLabel.isHidden = true
            }
        }
    }
    
    var paddingTop: CGFloat? {
        didSet {
            guard let padding = paddingTop else { return }
            topConstraint.constant = padding
            self.layoutIfNeeded()
        }
    }
    
    var paddingRight: CGFloat? {
        didSet {
            guard let padding = paddingRight else { return }
            rightConstraint.constant = padding
            self.layoutIfNeeded()
        }
    }
    
    let countView: UIView = {
        let view = UIView()
        view.backgroundColor = .mainRed()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.isHidden = true
        label.textAlignment = .center
        label.textColor = .white
        label.isUserInteractionEnabled = false
        return label
    }()
    
    var topConstraint: NSLayoutConstraint!
    var rightConstraint: NSLayoutConstraint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let imageView = imageView {
            insertSubview(countView, aboveSubview: imageView)
        } else {
            addSubview(countView)
        }
        
        insertSubview(countLabel, aboveSubview: countLabel)
        countLabel.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
        rightConstraint = countLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: paddingRight ?? 10)
        rightConstraint.isActive = true
        topConstraint = countLabel.topAnchor.constraint(equalTo: topAnchor, constant: paddingTop ?? 0)
        topConstraint.isActive = true
        
        countView.anchor(top: countLabel.topAnchor, left: countLabel.leftAnchor, bottom: countLabel.bottomAnchor, right: countLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        countView.layer.cornerRadius = 10
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
