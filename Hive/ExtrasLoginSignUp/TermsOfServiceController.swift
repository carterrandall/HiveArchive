
//
//  TermsOfServiceController.swift
//  Hive
//
//  Created by Alex Randall on 2019-02-10.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import WebKit

class TermsOfServiceController: UIViewController, WKUIDelegate{
    
    var wasPushed: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.wasPushed {
                    let backButton = UIBarButtonItem(image: UIImage(named:"back"), style: .plain, target: self, action: #selector(self.handleDismiss))
                    self.navigationItem.leftBarButtonItem = backButton
                } else {
                    let dismissButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .plain, target: self, action: #selector(self.handleDismiss))
                    self.navigationItem.leftBarButtonItem = dismissButton
                    self.navigationController?.navigationBar.barTintColor = UIColor.white
                    
                }
            }
        }
    }
    
    var webView : WKWebView?
    
    override func loadView() {
        let webConfig = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfig)
        webView?.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Terms of Service"
        self.navigationController?.navigationBar.tintColor = .black
        
        if let url = URL(string: "http://www.hiveios.com/device/termsanddata") {
            let myrequest = URLRequest(url: url)
            webView?.load(myrequest)
        }
        print(wasPushed, "was pusshed?")
        
        
    }
    
    var whiteView: UIView!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if wasPushed {
            whiteView = UIView()
            whiteView.backgroundColor = .white
            view.addSubview(whiteView)
            whiteView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height)!)
        }
    }
    
    
    @objc fileprivate func handleDismiss() {
        if wasPushed {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
