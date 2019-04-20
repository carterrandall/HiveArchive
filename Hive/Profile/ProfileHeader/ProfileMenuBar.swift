//
//  ProfileMenuBar.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-24.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class ProfileMenuBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let menuCellId = "menuCellId"
    
    var postCount: Int? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
                self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                
            }
        }
    }
    
    var shouldSelectFriends: Bool = false
    
    var friendCount: Int? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
                if self.shouldSelectFriends {
                    self.collectionView.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                    self.shouldSelectFriends = false
                } else {
                    self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)

                }
                
            }
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    var profileMainController: ProfileMainController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        collectionView.register(MenuBarCell.self, forCellWithReuseIdentifier: menuCellId)
        
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        backgroundColor = .clear
        
        setupHorizontalBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var horizontalBarLeftConstraint: NSLayoutConstraint?
    fileprivate func setupHorizontalBar() {
        
        let horizontalBarView = UIView()
        horizontalBarView.backgroundColor = .mainRed()
        
        let width = (UIScreen.main.bounds.width) / 2
        addSubview(horizontalBarView)
        horizontalBarView.anchor(top: nil, left: nil, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: 1)
        horizontalBarLeftConstraint = horizontalBarView.leftAnchor.constraint(equalTo: leftAnchor)
        horizontalBarLeftConstraint?.isActive = true
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        profileMainController?.scrollToMenuIndex(menuIndex: indexPath.item, animated: true)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: menuCellId, for: indexPath) as! MenuBarCell
        
        if indexPath.item == 0 {
            if let postCount = self.postCount {
                cell.screenLabel.text = "\(postCount) Post\(postCount == 1 ? "" : "s")"
            } else {
                cell.screenLabel.text = "0 Posts"
            }
        } else {
            if let friendCount = self.friendCount {
                cell.screenLabel.text = "\(friendCount) Friend\(friendCount == 1 ? "" : "s")"
            } else {
                cell.screenLabel.text = "0 Friends"
            }
        }
        
        cell.screenLabel.font = UIFont.boldSystemFont(ofSize: 16)
        cell.backgroundColor = .clear
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / 2, height: frame.height)
    }
}
