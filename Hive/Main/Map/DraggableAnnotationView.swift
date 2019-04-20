//
//  DraggableAnnotationView.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-02.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import Mapbox
import Alamofire

class DraggableAnnotationView: MGLAnnotationView {
    
    init(reuseIdentifier: String, size: CGFloat) {
        super.init(reuseIdentifier: reuseIdentifier)
        isExclusiveTouch = true  // hopefully this works, so we can't cancel while dragging.
        isDraggable = true
        scalesWithViewingDistance = false // Test out this property, might be kind of cool.
        let iv = UIImageView(image: UIImage(named: "icons8-bee-filled-50"))
        iv.layer.borderColor = UIColor.yellow.cgColor
        iv.frame = CGRect(x: 0, y: 0, width: size, height: size)
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        backgroundColor = UIColor.clear
        layer.cornerRadius = size / 2
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        addSubview(iv)
        iv.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 15, paddingRight: 15, width: 0, height: 0)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)
        switch dragState {
        case .starting:
            print("Starting", terminator: "")
            startDragging()
        case .dragging:
            print(".", terminator: "")
        case .ending, .canceling:
            print("Ending")
            endDragging()
        case .none:
            return
        }
    }
    func startDragging() {
        MapRender.mapView.style?.layer(withIdentifier: "newhivecirclelayer")?.isVisible = false
        MapRender.mapView.style?.removeLayer((MapRender.mapView.style?.layer(withIdentifier: "newhivecirclelayer"))!)
        MapRender.mapView.style?.removeSource( (MapRender.mapView.style?.source(withIdentifier: "newhivecirclesource"))!)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            
            
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            
        }, completion: nil)
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }
    }
    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }
        
        let circlesource = MGLShapeSource(identifier: "newhivecirclesource", shape: MapRender.newHiveAnnotation, options: nil)
        let circlelayer = MGLCircleStyleLayer(identifier: "newhivecirclelayer", source: circlesource)
        circlelayer.circleColor = NSExpression(forConstantValue: UIColor.mainRed())
        circlelayer.circleOpacity = NSExpression(forConstantValue: 0.6)
        circlelayer.circleRadius = NSExpression(forConstantValue: MapRender.createHiveSliderValue)
        MapRender.mapView.style?.addSource(circlesource)
        MapRender.mapView.style?.addLayer(circlelayer)
        
    }
}
