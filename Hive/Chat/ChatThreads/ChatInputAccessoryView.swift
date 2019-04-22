//
//  ChatInputAccessoryView.swift
//  Hive
//
//  Created by Carter Randall on 2018-12-30.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol ChatInputAccessoryViewDelegate {
    func didSubmit(for text: String)
    func updateTableViewForText(additionalTextViewHeight: CGFloat)
}

class ChatInputAccessoryView: UIView, UITextViewDelegate {
    
    var delegate: ChatInputAccessoryViewDelegate?
    
    var shouldSendTypingStatus: Bool = true
    
    var chatPartnerId: Int?
    
    var placeHolderText: String! {
        didSet {
            textView.text = placeHolderText
        }
    }
    
    var additionalTextViewHeight: CGFloat = 0.0
    var currentTextViewHeight: CGFloat = 0.0
    var previousTextViewHeight: CGFloat = 0.0
    
    func clearTextField() {
        self.textView.text = nil
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)
        if let cheight = self.contentHeight {
            textView.contentSize.height = cheight
        }
        if self.textViewHeightAnchor != nil {
            self.textViewHeightAnchor.constant = textView.contentSize.height
        }
        self.textView.sizeToFit()
        self.reloadInputViews()
    }
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.textColor = .lightGray
        tv.isScrollEnabled = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    
    var textViewHeightAnchor: NSLayoutConstraint!
    var contentHeight: CGFloat?
    func textViewDidChange(_ textView: UITextView) {
        
        if self.contentHeight == nil {
            self.contentHeight = textView.contentSize.height
        }
        
        if let fid = self.chatPartnerId {
            sendTypingStatus(fid: fid)
        }
        
        if textView.text.count > 420 {
            textView.deleteBackward()
        }
        
        let height = textView.contentSize.height
        if currentTextViewHeight == 0.0 {
            currentTextViewHeight = height
        }
        
        if height > (200) {
            
            
            if self.textViewHeightAnchor == nil {
                self.textView.isScrollEnabled = true
                self.textViewHeightAnchor = self.textView.heightAnchor.constraint(equalToConstant: 200)
                self.textViewHeightAnchor.isActive = true
            }
            
        } else {
            
            let contentSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            self.frame.size.height = contentSize.height + 16
            
            self.textView.reloadInputViews()
            
            if self.textViewHeightAnchor != nil {
                
                self.textViewHeightAnchor.constant = contentSize.height
                
            }
            
            
            if height != currentTextViewHeight {
                previousTextViewHeight = currentTextViewHeight
                currentTextViewHeight = height
                if currentTextViewHeight != previousTextViewHeight {
                    delegate?.updateTableViewForText(additionalTextViewHeight: currentTextViewHeight - previousTextViewHeight)
                }
            }
        }
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("did end eidint")
        if textView.text.isEmpty {
            textView.text = placeHolderText
            textView.textColor = .lightGray
            
        }
    }
    
    override func didMoveToWindow() {
        self.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 12).isActive = true
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        autoresizingMask = .flexibleHeight
        
        backgroundColor = .clear
        
        textView.delegate = self
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        addSubview(backgroundView)
        
        backgroundView.clipsToBounds = true
        backgroundView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.cornerRadius = (frame.height - 16) / 2
        
        addSubview(textView)
        textView.anchor(top: nil, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 12, paddingBottom: 8, paddingRight: 62, width: 0, height: 0)
        
        addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: textView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 12, width: 50, height: 50)
        
        backgroundView.anchor(top: textView.topAnchor, left: leftAnchor, bottom: textView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        textView.addGestureRecognizer(swipeGesture)
        
    }
    
    fileprivate func sendTypingStatus(fid: Int) {
        if shouldSendTypingStatus {
            shouldSendTypingStatus = false
            let params = ["conversationPartner": fid, "startTime": Date().timeIntervalSince1970] as [String : Any]
            RequestManager().makeResponseRequest(urlString: "/Hive/api/startTypingMessageToUser", params: params) { (response) in
                if response.response?.statusCode == 200 {
                    print("sent typing to user")
                } else {
                    print("failed to send typing to user")
                }
            }
            
        }
    }
    
    @objc fileprivate func handleSend() {
        
        shouldSendTypingStatus = true
        
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text == placeHolderText || text == "" {
            return
        }
        
        
        delegate?.didSubmit(for: text)
        
    }
    
    @objc fileprivate func handleSwipe() {
        self.textView.endEditing(true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

