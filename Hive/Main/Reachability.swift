//
//  Reachability.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-10.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

struct Connectivity {
    static let sharedInstance = NetworkReachabilityManager()!
    static var isConnectedToInternet:Bool {
        return self.sharedInstance.isReachable
    }
}

protocol ConnectivityPageDelegate {
    func retryInternet()
}

class ConnectivityPage: UIViewController {
    
    var delegate: ConnectivityPageDelegate?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text  = "Please connect to the internet."
        label.textAlignment = .center
        return label
    }()
    
    let connectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Connect To the Internet", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.mainRed(), for: .normal)
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                
            }
        }
        
    }
    
    let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.mainRed(), for: .normal)
        button.addTarget(self, action: #selector(retry), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func retry() {
        if Connectivity.isConnectedToInternet {
            delegate?.retryInternet()
        } else {
            let generator = UIImpactFeedbackGenerator()
            generator.impactOccurred()
            self.stackView.shake()
        }

    }
    
    let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "loginbackground"))
        return iv
    }()
    
    var stackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(backgroundImageView)
        backgroundImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = view.bounds
        view.addSubview(blurView)
        
        stackView = UIStackView(arrangedSubviews: [titleLabel, connectButton, retryButton])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 20
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}

