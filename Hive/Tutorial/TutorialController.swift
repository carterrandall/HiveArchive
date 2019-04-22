//
//  TutorialController.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-22.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol TutorialControllerDelegate: class {
    func completedTutorial()
}

class TutorialController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: TutorialControllerDelegate?
    
    let images = ["HiveJoinCreate","ProfileAndSearch","camerapin","FeedLike","Congrats"]
    
    fileprivate let tutorialCellId = "tutorialCellId"
    
    
    let pageIndicator: UIPageControl = {
        let pc = UIPageControl()
        pc.pageIndicatorTintColor = .lightGray
        pc.currentPageIndicatorTintColor = .mainRed()
        pc.currentPage = 0
        pc.numberOfPages = 5
        return pc
    }()
    
    let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Okay, I got it", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .right
        button.tintColor = .mainRed()
        button.addTarget(self, action: #selector(endTutorial), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func endTutorial() {
        delegate?.completedTutorial()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        blurView.frame = view.bounds
        view.insertSubview(blurView, at: 0)
        
        setupCollectionView()
        
    }
    
    fileprivate func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(TutorialCell.self, forCellWithReuseIdentifier: tutorialCellId)
        
        view.addSubview(pageIndicator)
        pageIndicator.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 30)
        let h = (view.frame.width - 40) * (4/3)
        let padding = (view.frame.height - h) / 2 - 15
        pageIndicator.topAnchor.constraint(equalTo: view.topAnchor, constant: padding / 2).isActive = true
        
        view.addSubview(doneButton)
        doneButton.anchor(top: nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 20, width: 100, height: 40)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width - 40
        return CGSize(width: view.frame.width - 40, height: width * (4/3))
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tutorialCellId, for: indexPath) as! TutorialCell
        cell.imageView.image = UIImage(named: images[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 40
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageIndicator.currentPage = Int(scrollView.contentOffset.x / view.frame.width)
    }
    
}
