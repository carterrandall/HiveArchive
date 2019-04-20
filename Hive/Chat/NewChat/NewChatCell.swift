//
//  NewChatCell.swift
//  Highve
//
//  Created by Carter Randall on 2018-09-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol NewChatCellDelegate {
    func didSelectCell(cell: NewChatCell)
}

class NewChatCell: UICollectionViewCell {
    
    var delegate: NewChatCellDelegate?
    
    var hasBeenSelected: Bool? {
        didSet {
            if let hasBeenSelected = hasBeenSelected, hasBeenSelected {
                selectedButton.isHidden = false
            } else {
                selectedButton.isHidden = true
            }
        }
        
    }
    
    var friend: User? {
        didSet {
            guard let friend = friend else { return }
            
            profileImageView.profileImageCache(url: friend.profileImageUrl, userId: friend.uid)
        
            usernameLabel.text = friend.username
            nameLabel.text = friend.fullName
        }
    }

    override func prepareForReuse() {
        friend = nil
        profileImageView.image = nil
        usernameLabel.text = nil
        nameLabel.text = nil
        usernameLabel.textColor = .black
        nameLabel.textColor = .gray
        isUserInteractionEnabled = true
    
    }
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 30
        return iv
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    let seperatorView: UIView = {
        let sv = UIView()
        sv.backgroundColor = UIColor(white: 0, alpha: 0.1)
        return sv
    }()
    
    let selectedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "minus"), for: .normal)
        button.tintColor = .mainBlue()
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
       
        addSubview(profileImageView)
        profileImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 0, paddingRight: 0, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(selectedButton)
        selectedButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 16, width: 40, height: 40)
        selectedButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        let stackView = UIStackView(arrangedSubviews: [usernameLabel, nameLabel])
        stackView.axis = .vertical
        
        addSubview(stackView)
        stackView.anchor(top: nil, left: profileImageView.rightAnchor, bottom: nil, right: selectedButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
    }
    
    @objc fileprivate func handleTap() {
        DispatchQueue.main.async {
            self.delegate?.didSelectCell(cell: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
