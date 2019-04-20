//
//  MFBaseCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-08-04.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class MFCell: UICollectionViewCell {
    
    var story: Story? {
        didSet {
            guard let story = story else { return }
            
            profileImageView.profileImageCache(url: story.user.profileImageUrl, userId: story.user.uid)
            
            if story.hasSeenAllPosts {
                profileImageContainerView.layer.borderColor = UIColor.lightGray.cgColor
                profileImageContainerView.layer.borderWidth = 1
            } else {
                profileImageContainerView.layer.borderColor = UIColor.mainRed().cgColor
                profileImageContainerView.layer.borderWidth = 2
            }
        }
    }
    
   
    
    override func prepareForReuse() {
        self.story = nil
        self.profileImageView.image = nil
        overlayButton.removeFromSuperview()
        
    }
  
    let profileImageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    let profileImageView: CustomImageView = {
        let pv = CustomImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        return pv
    }()
    
    let overlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "camerasmall"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.rgb(red: 30, green: 30, blue: 30).withAlphaComponent(0.2)
        button.clipsToBounds = true
        return button
    }()
    
    func addOverlayButton() {
        profileImageView.addSubview(overlayButton)
        overlayButton.anchor(top: profileImageView.topAnchor, left: profileImageView.leftAnchor, bottom: profileImageView.bottomAnchor, right: profileImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupCellViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupCellViews() {
        
        let dim: CGFloat = frame.width
        print(frame.width, "WIDHT")
        addSubview(profileImageContainerView)
        profileImageContainerView.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: dim, height: dim)
        profileImageContainerView.layer.cornerRadius = dim / 2
        profileImageContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        profileImageContainerView.addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: dim - 8, height: dim - 8)
        profileImageView.layer.cornerRadius = (dim - 8) / 2
        profileImageView.centerXAnchor.constraint(equalTo: profileImageContainerView.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: profileImageContainerView.centerYAnchor).isActive = true
    
        
    }
}






