//
//  ProfilePhotoCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-15.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class ProfilePhotoCell: UICollectionViewCell {
    
    var post: Post? {
        didSet {
            guard let post = post else { return }
            post.getPostCache { (post) in
                DispatchQueue.main.async {
                    self.postImageView.postImageCache(url: post.imageUrl, postId: post.id)
                    
                    if post.videoUrl != nil {
                        self.videoImageView.image = UIImage(named: "video")
                        self.videoImageView.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
                    } else {
                        self.videoImageView.image = nil
                    }
                  
                    
                }
            }
            
        }
    }
    
    var isPinned: Bool? {
        didSet {
            if let isPinned = isPinned, isPinned {
                self.pinnedButton.setImage(UIImage(named: "pinned")?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                self.pinnedButton.setImage(nil, for: .normal)

            }
        }
    }
    
    override func prepareForReuse() {
        post = nil
        postImageView.image = nil
        pinnedButton.setImage(nil, for: .normal)
    }
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let videoImageView = UIImageView()
    lazy var pinnedButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        layer.borderColor = UIColor(white: 0, alpha: 0.01).cgColor
        layer.borderWidth = 1
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        addSubview(postImageView)
        postImageView.frame = self.bounds
        
        addSubview(videoImageView)
        videoImageView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 8, paddingRight: 0, width: 20, height: 20)
    
        addSubview(pinnedButton)
        pinnedButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 2, width: 20, height: 20)

        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
