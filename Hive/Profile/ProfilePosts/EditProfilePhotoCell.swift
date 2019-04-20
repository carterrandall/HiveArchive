//
//  EditProfilePhotoCell.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-25.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol EditProfilePhotoCellDelegate {
    func didTapDeletePost(cell: EditProfilePhotoCell)
    func didTapPinPost(cell: EditProfilePhotoCell)
}

class EditProfilePhotoCell: UICollectionViewCell {
    
    var delegate: EditProfilePhotoCellDelegate?
    
    var post: Post? {
        didSet {
            
            guard let post = post else { return }
            
            postImageView.postImageCache(url: post.imageUrl, postId: post.id)
            
            if post.isPinned {
                pinButton.setImage(UIImage(named: "pinned")?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                pinButton.setImage(UIImage(named: "pin")?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
            
            if post.videoUrl != nil {
                videoImageView.image = UIImage(named: "video")
            } else {
                videoImageView.image = nil
            }
            
        }
    }
    
    override func prepareForReuse() {
        postImageView.image = nil
        post = nil
    }
    
    let videoImageView: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleDeletePost), for: .touchUpInside)
        button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return button
    }()
    
    @objc fileprivate func handleDeletePost() {

        delegate?.didTapDeletePost(cell: self)
    }

    lazy var pinButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handlePinPost), for: .touchUpInside)
        button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return button
    }()

    @objc func handlePinPost() {
        delegate?.didTapPinPost(cell: self)
    }
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(postImageView)
        postImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.height)
        
        addSubview(videoImageView)
        videoImageView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 8, paddingRight: 0, width: 20, height: 20)
        
        addSubview(deleteButton)
        deleteButton.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
        addSubview(pinButton)
        pinButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
