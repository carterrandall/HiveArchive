//
//  FeedPostCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-18.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

protocol PostViewerCellDelegate {
    func didTapComments(cell: PostViewerCell)
    func didTapLike(for cell: PostViewerCell)
    func didTapShare(post: Post)
    func leftTap(cell: PostViewerCell)
    func rightTap(cell: PostViewerCell)
    func swipeDown()
}

class PostViewerCell: UICollectionViewCell {
    
    var delegate: PostViewerCellDelegate?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        return aiv
    }()
    
    var post: Post? {
        didSet {
            
            guard let post = post else { return }
            post.getPostCache { (post) in
                DispatchQueue.main.async {
                    self.postImageView.postImageCache(url: post.imageUrl, postId: post.id)
                    
                    if post.hasLiked {
                        self.likeButton.setImage(UIImage(named: "likeSelected")?.withRenderingMode(.alwaysOriginal), for: .normal)
                        self.likeButton.isEnabled = true
                    } else {
                        
                        self.likeButton.setImage(UIImage(named: "blank"), for: .disabled)
                        self.likeButton.isEnabled = false
                    }
                    
                    if let commentCount = post.comments {
                        if commentCount > 999 {
                            self.commentLabel.text = "999"
                        } else {
                            let commentButtonString = String(post.comments ?? 0)
                            self.commentLabel.text = commentButtonString
                        }
                    } else {
                        self.commentLabel.text = "0"
                    }
                    
                    self.timeOfPostLabel.text = post.creationDate.timeAgoDisplay()
                    self.drawTimeLine(secondsSinceNow: Double((Date().timeIntervalSince(post.creationDate))))
                    
                    if let hiveName = post.hiveName, hiveName != "" {
                        self.hiveNameLabel.text = hiveName
                    } else {
                        self.hiveNameLabel.text = nil
                    }
                }
            }
        }
    }
    
    var timeShape: CAShapeLayer!
    fileprivate func drawTimeLine(secondsSinceNow: Double) {
        
        let hoursSinceNow = secondsSinceNow / 3600
        if hoursSinceNow >= 24 { return }
        let endPoint = Float((frame.width)) - ((Float(hoursSinceNow / 24) * (Float(frame.width))))
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        
        path.addLine(to: CGPoint(x: CGFloat(endPoint), y: 0))
        timeShape = CAShapeLayer()
        timeShape.lineWidth = 4
        timeShape.path = path.cgPath
        timeShape.strokeColor = UIColor.mainRed().cgColor
        timeShape.fillColor = UIColor.clear.cgColor
        
        self.containerView.layer.addSublayer(timeShape)
        
    }
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    func handlePlay() {
        DispatchQueue.main.async {
            if let videoUrl = self.post?.videoUrl {
                
                self.activityIndicatorView.isHidden = false
                self.activityIndicatorView.startAnimating()
                
                self.player = AVPlayer(url: videoUrl)
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.videoGravity = .resizeAspectFill
                self.playerLayer?.frame = self.containerView.bounds
                self.containerView.layer.insertSublayer(self.playerLayer!, below: self.timeShape)
                
                self.player?.play()
                self.playerLayer?.name = "playerLayer"
                
            }
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        post = nil
        postImageView.image = nil
        hiveNameLabel.text = nil
        timeOfPostLabel.text = nil
        commentLabel.text = nil
        activityIndicatorView.isHidden = true
        activityIndicatorView.stopAnimating()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        
        if timeShape != nil {
            timeShape.removeFromSuperlayer()
        }
        
        if let sublayers = containerView.layer.sublayers {
            for layer in sublayers {
                if layer.name == "playerLayer" {
                    layer.removeFromSuperlayer()
                    return
                }
            }
        }
    }
    
    //container view so we can insert player playerLayer sublayer later
    let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let timeOfPostLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let hiveNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    @objc func handleLike() {
        DispatchQueue.main.async {
            self.likeButton.isEnabled = false
            self.delegate?.didTapLike(for: self)
            if let hasLiked = self.post?.hasLiked, !hasLiked {
                self.likeButton.setImage(UIImage(named: "likeSelected")?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                self.likeButton.setImage(UIImage(named: "blank"), for: .normal)
                self.likeButton.isEnabled = true
            }
        }
        
    }
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "comments"), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleComments), for: .touchUpInside)
        return button
    }()
    
    @objc func handleComments() {//change name of this button later
        delegate?.didTapComments(cell: self)
    }
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        return label
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "share"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShare() {
        print("Handling share....")
        guard let post = post else { return }
        delegate?.didTapShare(post: post)
    }
    
    let gestureView = PostViewerGestureView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
        }
        
        backgroundColor = .clear
        
        setupViews()
        gestureView.delegate = self
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        
        let width = UIScreen.main.bounds.width
        let height = width * (4/3)
        addSubview(containerView)
        containerView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: height)
        
        containerView.addSubview(postImageView)
        postImageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: height)
        
        addSubview(gestureView)
        gestureView.anchor(top: postImageView.topAnchor, left: postImageView.leftAnchor, bottom: postImageView.bottomAnchor, right: postImageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        let buttonStackView = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        buttonStackView.distribution = .fillEqually
        addSubview(buttonStackView)
        buttonStackView.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: width / 3, height: 40)
        
        commentButton.addSubview(commentLabel)
        commentLabel.anchor(top: commentButton.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentLabel.centerXAnchor.constraint(equalTo: commentButton.centerXAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [hiveNameLabel, timeOfPostLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        addSubview(stackView)
        stackView.anchor(top: topAnchor, left: leftAnchor, bottom: containerView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: frame.width * (2/3), height: 40)
        
        containerView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
        activityIndicatorView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        activityIndicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
    }
    
    func animateLike() {
        
        let dim = postImageView.frame.width - 40
        let sunImageView = UIImageView(frame: CGRect(x: postImageView.center.x - (dim / 2), y: postImageView.center.y - (dim / 2), width: dim, height: dim))
        sunImageView.image = UIImage(named: "likeSelectedLarge")
        sunImageView.contentMode = .scaleAspectFit
        sunImageView.alpha = 0.5
        self.postImageView.addSubview(sunImageView)
        sunImageView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            sunImageView.layer.transform = CATransform3DMakeScale(1, 1, 1)
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                
                sunImageView.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                sunImageView.alpha = 0
                
            }, completion: { (_) in
                self.likeButton.isEnabled = true
                
            })
            
        }
        
        
    }
    
}

extension PostViewerCell: PostViewerGestureViewDelegate {
    
    func leftTap() {
        delegate?.leftTap(cell: self)
    }
    
    func rightTap() {
        delegate?.rightTap(cell: self)
    }
    
    func swipeDown() {
        delegate?.swipeDown()
    }
    
    func doubleTap() {
        self.handleLike()
    }
}

