//
//  PostBaseCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-08-04.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import AVFoundation

protocol PostCellDelegate: class {
    func didTapComments(cell: PostCell)
    func didTapShare(post: Post)
    func didTapLike(cell: PostCell)
    func didTapProfile(user: User)
}

class PostCell: UICollectionViewCell, UIScrollViewDelegate {
    
    weak var delegate: PostCellDelegate?
    
    var post: Post? {
        didSet {
            
            guard let post = post else { return }
   
            post.getPostCache { (post) in
                DispatchQueue.main.async {
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
                    
                    self.postView.postImageCache(url: post.imageUrl, postId: post.id)
                    
                    self.timeOfPostLabel.text = post.creationDate.timeAgoDisplay()
                    self.usernameLabel.text = post.user?.username
                    
                    self.drawTimeLine(secondsSinceNow: Double((Date().timeIntervalSince(post.creationDate))))
                    
                    if let profileImageUrl = post.user?.profileImageUrl, let id = post.user?.uid {
                        self.profileImageView.profileImageCache(url: profileImageUrl, userId: id)
                    }
                    
                    if let hiveName = post.hiveName, hiveName != "" {
                        self.hiveNameLabel.text = hiveName
                        self.hiveNameLabel.isHidden = false
                    } else {
                        self.hiveNameLabel.isHidden = true
                    }
                }
                
                if post.expired != nil {
                    self.shareButton.isEnabled = false
                }
            }
            
        }
    }
    
    var timeShape: CAShapeLayer!
    fileprivate func drawTimeLine(secondsSinceNow: Double) {
        let hoursSinceNow = secondsSinceNow / 3600

        let endPoint = Float((frame.width)) - ((Float(hoursSinceNow / 24) * (Float(frame.width))))
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 1))
        
        timeShape = CAShapeLayer()
        if let isPinned = post?.isPinned, !isPinned && hoursSinceNow > 24 {
            path.addLine(to: CGPoint(x: frame.width, y: 1))
            timeShape.strokeColor = UIColor.mainBlue().cgColor

        } else if hoursSinceNow > 24  {
            path.addLine(to: CGPoint(x: frame.width, y: 1))
            timeShape.strokeColor = UIColor.mainRed().cgColor
            
        } else {
            path.addLine(to: CGPoint(x: CGFloat(endPoint), y: 1))
            timeShape.strokeColor = UIColor.mainRed().cgColor
        }
        
        timeShape.lineWidth = 2
        timeShape.path = path.cgPath
        timeShape.fillColor = UIColor.clear.cgColor
        containerView.layer.addSublayer(timeShape)
        
    }
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    func handlePlay() {
        DispatchQueue.main.async {
            if let videoUrl = self.post?.videoUrl {
                
                self.activityIndicatorView.startAnimating()
                print("starting animating")
                self.player = AVPlayer(url: videoUrl)
                
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.videoGravity = .resizeAspect
                self.playerLayer?.frame = self.containerView.bounds
                
                if self.timeShape != nil {
                    self.containerView.layer.insertSublayer(self.playerLayer!, below: self.timeShape)
                } else {
                    self.containerView.layer.addSublayer(self.playerLayer!)
                }
                print("ending animating")
                self.playerLayer?.name = "playerLayer"
                self.player?.play()
                
            }
        }
        
    }
    
   
    override func prepareForReuse() {
        activityIndicatorView.stopAnimating()
        post = nil
        commentLabel.text = nil
        postView.image = nil
        profileImageView.image = nil
        usernameLabel.text = nil
        timeOfPostLabel.text = nil
        likeButton.setImage(nil, for: .normal)
        likeButton.setImage(nil, for: .disabled)
        hiveNameLabel.text = nil
        if timeShape != nil {
            timeShape.removeFromSuperlayer()
            timeShape = nil
        }
        playCount = 0
        if let sublayers = containerView.layer.sublayers {
            for layer in sublayers {
                if layer.name == "playerLayer" {
                    layer.removeFromSuperlayer()
                    return
                }
            }
        }
        
    }
    let containerView = UIView()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        return aiv
    }()
    
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 6.0
        sv.delegate = self
        return sv
    }()
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return postView
    }
    
    let postView: CustomImageView = {
        let pv = CustomImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        pv.isUserInteractionEnabled = true
        return pv
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    let timeOfPostLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    let hiveNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    @objc func handleLike() {
        
        if post?.expired != nil { return }
        
        DispatchQueue.main.async {
            self.delegate?.didTapLike(cell: self)
            self.likeButton.isEnabled = false
            
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
        button.tintColor = UIColor.black
        button.addTarget(self, action: #selector(handleComments), for: .touchUpInside)
        return button
    }()
    
    @objc func handleComments() {
        delegate?.didTapComments(cell: self)
    }
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "share"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleShare() {
        guard let post = post else { return }
        delegate?.didTapShare(post: post)
    }
    
    lazy var profileButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleProfile), for: .touchUpInside)
        return button
    }()
    
    var playCount = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.player?.seek(to: CMTime.zero)
            if self.playCount < 3 {
                self.playCount += 1
                
                self.player?.play()
            }
            
        }
        
        backgroundColor = .white
        setupCellViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupCellViews() {
        
        let profileImageDim: CGFloat = 50
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: profileImageDim, height: profileImageDim)
        profileImageView.layer.cornerRadius = profileImageDim / 2
        
        let buttonStackView = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        buttonStackView.distribution = .fillProportionally
        addSubview(buttonStackView)
        buttonStackView.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: frame.width / 3, height: 0)
        buttonStackView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        commentButton.addSubview(commentLabel)
        commentLabel.anchor(top: commentButton.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        commentLabel.centerXAnchor.constraint(equalTo: commentButton.centerXAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, hiveNameLabel, timeOfPostLabel])
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: buttonStackView.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        
        addSubview(profileButton)
        profileButton.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 54)
        
        addSubview(containerView)
        containerView.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.width * (4/3))
        
        containerView.addSubview(scrollView)
        scrollView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.width * (4/3))
    
        scrollView.addSubview(postView)
        postView.anchor(top: scrollView.topAnchor, left: scrollView.leftAnchor, bottom: nil, right: scrollView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: frame.width, height: frame.width * (4/3))
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapOnPost))
        doubleTapGesture.numberOfTapsRequired = 2
        postView.addGestureRecognizer(doubleTapGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(pausePlayVideo))
        singleTapGesture.numberOfTapsRequired = 1
        postView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        
        containerView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
        activityIndicatorView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        activityIndicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

    }
    
    @objc fileprivate func pausePlayVideo() {
        DispatchQueue.main.async {
            if self.player != nil, let isPlaying = self.player?.isPlaying {
                if isPlaying {
                    self.player?.pause()
                } else {
                    self.player?.play()
                }
            }
        }
    }
    
    @objc fileprivate func handleProfile() {
        guard let user = post?.user else { return }
        delegate?.didTapProfile(user: user)
    }
    
    @objc fileprivate func handleDoubleTapOnPost() {
        if let hasLiked = post?.hasLiked, !hasLiked {
           handleLike()
        }
    }
    
    func animateLike() {

        print("ANIMATING")
        let dim = postView.frame.width - 40
        let sunImageView = UIImageView(frame: CGRect(x: postView.center.x - (dim / 2), y: 58 + postView.center.y - (dim / 2), width: dim, height: dim))
        sunImageView.image = UIImage(named: "likeSelectedLarge")
        sunImageView.contentMode = .scaleAspectFit
        sunImageView.alpha = 0.5
        self.addSubview(sunImageView)
        sunImageView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            sunImageView.layer.transform = CATransform3DMakeScale(1, 1, 1)
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.3, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                
                sunImageView.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                sunImageView.alpha = 0
                
            }, completion: { (_) in
                sunImageView.removeFromSuperview()
                self.likeButton.isEnabled = true
            })
            
        }
    }
    
}
