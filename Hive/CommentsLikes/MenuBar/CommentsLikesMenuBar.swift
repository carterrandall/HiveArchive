//
//  CommentsLikesMenuBar.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-19.
//  Copyright © 2018 Carter Randall. All rights reserved.


import UIKit

class CommentsLikesMenuBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let menuCellId = "menuCellId"
    
    var commentCount: Int? {
        didSet {
            if showLikes {
                collectionView.reloadItems(at: [IndexPath(item: 1, section: 0)])
            } else {
                collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
            }
        }
    }
    
    var showLikes: Bool = false {
        didSet {
            if !showLikes {
                horizontalBarView.backgroundColor = .clear
            } else {
                horizontalBarView.backgroundColor = .mainRed()
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
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
    
    var commentsLikesController: CommentsLikesController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        collectionView.register(MenuBarCell.self, forCellWithReuseIdentifier: menuCellId)
        
        addSubview(collectionView)
        collectionView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        backgroundColor = .clear
        
        collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        
        setupHorizontalBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var horizontalBarLeftConstraint: NSLayoutConstraint?
    let horizontalBarView = UIView()
    fileprivate func setupHorizontalBar() {
        
        horizontalBarView.backgroundColor = .mainRed()
        
        let width = UIScreen.main.bounds.width / 2
        addSubview(horizontalBarView)
        horizontalBarView.anchor(top: nil, left: nil, bottom: bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: width, height: 1)
        horizontalBarLeftConstraint = horizontalBarView.leftAnchor.constraint(equalTo: leftAnchor)
        horizontalBarLeftConstraint?.isActive = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        commentsLikesController?.scrollToMenuIndex(menuIndex: indexPath.item, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showLikes ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: menuCellId, for: indexPath) as! MenuBarCell
        
        if showLikes {
            if indexPath.item == 0 {
                cell.screenLabel.text = "Likes"
            } else {
                if let commentCount = commentCount {
                    cell.screenLabel.text = "\(commentCount) \(commentCount == 1 ? "Comment" : "Comments")"
                } else {
                    cell.screenLabel.text = "Comments"
                }
            }
            
        } else {
            if let commentCount = commentCount {
                cell.screenLabel.text = "\(commentCount) \(commentCount == 1 ? "Comment" : "Comments")"
            } else {
                cell.screenLabel.text = "Comments"
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return showLikes ? CGSize(width: frame.width / 2, height: frame.height) : CGSize(width: frame.width, height: frame.height)
    }
}
