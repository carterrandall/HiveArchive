//
//  PhotoSelectionHeader.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

class PhotoSelectionHeader: UICollectionViewCell, UIScrollViewDelegate {
    
    var image: UIImage? {
        didSet {
            guard let image = image else { return }
            photoImageView.widthAnchor.constraint(equalToConstant: (image.size.width))
            photoImageView.heightAnchor.constraint(equalToConstant: (image.size.height))
            photoImageView.updateConstraints()
            let scaleWidth = scrollView.frame.size.width / (image.size.width)
            let scaleHeight = scrollView.frame.size.height / (image.size.height)
            
            let maxScale = max(scaleWidth, scaleHeight)
            scrollView.minimumZoomScale = maxScale
            scrollView.zoomScale = maxScale
            
            photoImageView.image = image
            
        }
    }
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.maximumZoomScale = 6.0
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false 
        return sv
    }()
    
    let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    let fillLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black
        
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.frame = self.bounds
        
        scrollView.addSubview(photoImageView)
        photoImageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        photoImageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        photoImageView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        photoImageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true 
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let radius = frame.size.width / 2
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: 0)
        let circlePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius), cornerRadius: radius)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor(white: 0, alpha: 0.5).cgColor
        layer.addSublayer(fillLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
