//
//  CommentCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-20.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol CommentCellDelegate: class {
    func showProfile(user: User)
    func showMore(cell: CommentCell)
}

class CommentCell: UITableViewCell {

    weak var delegate: CommentCellDelegate?
 
    var comment: Comment? {
        didSet {
            
            guard let comment = comment else { return }
            
            let attributedText = NSMutableAttributedString(string: comment.user.username, attributes: [.font: UIFont.boldSystemFont(ofSize: 14) ])
            
            attributedText.append(NSAttributedString(string: " " + comment.text, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
            attributedText.append(NSAttributedString(string: "\n\(comment.creationDate.timeAgoDisplay())", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.gray]))
            commentLabel.attributedText = attributedText
    
            profileImageView.profileImageCache(url: comment.user.profileImageUrl, userId: comment.user.uid)
            
            
        }
    }
    
    var showMore: Bool? {
        didSet {
            if let showMore = showMore, showMore {
                moreButton.setImage(UIImage(named: "moreComment"), for: .normal)
                moreButton.isHidden = false
            } else {
                moreButton.isHidden = true
            }
        }
    }
    
    override func prepareForReuse() {
        comment = nil
        profileImageView.image = nil
        commentLabel.attributedText = nil
        moreButton.setImage(nil, for: .normal)
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 25
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(handleMore), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleMore() {
        delegate?.showMore(cell: self)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
   
        backgroundColor = .white
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)

        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(commentLabel)
        
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(moreButton)
    
        let constraints = [
            
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            moreButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 30),
            moreButton.heightAnchor.constraint(equalToConstant: 50),

            commentLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: CGFloat(8)),
            commentLabel.topAnchor.constraint(equalTo: topAnchor, constant: CGFloat(8)),
            commentLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: CGFloat(-8)),
            commentLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: CGFloat(-8)),
            commentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(50))

        ]
        
        NSLayoutConstraint.activate(constraints)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfile))
        profileImageView.addGestureRecognizer(tapGesture)
 
    }
    
    @objc fileprivate func handleProfile() {
        guard let user = comment?.user else { return }
        delegate?.showProfile(user: user)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
