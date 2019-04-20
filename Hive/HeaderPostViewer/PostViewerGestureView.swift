//
//  PostViewerGestureView.swift
//  Highve
//
//  Created by Carter Randall on 2018-11-13.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol PostViewerGestureViewDelegate {
    func leftTap()
    func rightTap()
    func swipeDown()
    func doubleTap()
}

class PostViewerGestureView: UIView {
    
    var delegate: PostViewerGestureViewDelegate?
    
    let leftSideView = UIView()
    let rightSideView = UIView()
    let topLeft = UIView()
    let topRight = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let topViewHeight: CGFloat = UIScreen.main.bounds.width * (4/6)
        addSubview(topLeft)
        topLeft.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: centerXAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: topViewHeight)
        topLeft.isUserInteractionEnabled = true
        
        let doubleTapLeft = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapLeft.numberOfTapsRequired = 2
        topLeft.addGestureRecognizer(doubleTapLeft)

        let leftSingle = UITapGestureRecognizer(target: self, action: #selector(handleLeftTap))
        leftSingle.numberOfTapsRequired = 1
        topLeft.addGestureRecognizer(leftSingle)
        leftSingle.require(toFail: doubleTapLeft)
        
        addSubview(topRight)
        topRight.anchor(top: topAnchor, left: centerXAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: topViewHeight)
        topRight.isUserInteractionEnabled = true
        
        let doubleTapRight = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapRight.numberOfTapsRequired = 2
        topRight.addGestureRecognizer(doubleTapRight)
        
        let rightSingle = UITapGestureRecognizer(target: self, action: #selector(handleRightTap))
        rightSingle.numberOfTapsRequired = 1
        topRight.addGestureRecognizer(rightSingle)
        rightSingle.require(toFail: doubleTapRight)
        
        addSubview(leftSideView)
        leftSideView.anchor(top: topLeft.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: centerXAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let leftTap = UITapGestureRecognizer(target: self, action: #selector(handleLeftTap))
        leftSideView.isUserInteractionEnabled = true
        leftSideView.addGestureRecognizer(leftTap)
        
        addSubview(rightSideView)
        rightSideView.anchor(top: topRight.bottomAnchor, left: centerXAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let rightTap = UITapGestureRecognizer(target: self, action: #selector(handleRightTap))
        rightSideView.isUserInteractionEnabled = true
        rightSideView.addGestureRecognizer(rightTap)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .down
        addGestureRecognizer(swipeGesture)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleDoubleTap() {
        DispatchQueue.main.async {
            self.delegate?.doubleTap()
        }
    }
    
    @objc func handleLeftTap() {
        DispatchQueue.main.async {
            self.delegate?.leftTap()
        }
    }
    
    @objc func handleRightTap() {
        DispatchQueue.main.async {
            self.delegate?.rightTap()
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        DispatchQueue.main.async {
            self.delegate?.swipeDown()
        }
    }
    
}
