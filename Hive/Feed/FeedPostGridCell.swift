//
//  FeedPostGridCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-30.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class FeedPostGridCell: UICollectionViewCell{
    
    var post: Post? {
        didSet {
            
            guard let post = post else { return }
            
            postView.postImageCache(url: post.imageUrl, postId: post.id)
            
            if post.videoUrl != nil {
                videoImageView.image = UIImage(named: "video")

            } else {
                videoImageView.image = nil
            }
            
        }
    }
    
    let videoImageView: UIImageView = {
        let iv = UIImageView()
        iv.setShadow(offset: .zero, opacity: 0.3, radius: 2, color: UIColor.black)
        return iv
    }()
    
    let postContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let postView: CustomImageView = {
        let pv = CustomImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        return pv
    }()
    
    override func prepareForReuse() {
        post = nil
        postView.image = nil
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
        
        addSubview(postContainerView)
        postContainerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        postContainerView.addSubview(postView)
        postView.anchor(top: postContainerView.topAnchor, left: postContainerView.leftAnchor, bottom: postContainerView.bottomAnchor, right: postContainerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.width * (4/3))
        
        addSubview(videoImageView)
        videoImageView.anchor(top: nil, left: postView.leftAnchor, bottom: postView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 4, paddingBottom: 8, paddingRight: 0, width: 20, height: 20)
        
    }
    
   
}
