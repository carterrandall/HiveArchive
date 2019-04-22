//
//  InputAccessoryView.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-26.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit

protocol InputAccessoryViewDelegate: class {
    func didSubmit(for text: String, taggedUids: [Int])
    func updateTableViewForText(additionalTextViewHeight: CGFloat)
    func tag(add: Bool)
}

class InputAccessoryView: UIView, UITextViewDelegate {
    
    weak var delegate: InputAccessoryViewDelegate?
    
    var tagCollectionView: TagCollectionView!
    
    var isTagging: Bool = false
    
    var placeHolderText: String! {
        didSet {
            textView.text = placeHolderText
        }
    }
    
    var additionalTextViewHeight: CGFloat = 0.0
    var currentTextViewHeight: CGFloat = 0.0
    var previousTextViewHeight: CGFloat = 0.0
    
    func clearTextField() {
        textView.text = nil
        
        if let cheight = self.contentHeight {
            textView.contentSize.height = cheight
        }
        
        if self.textViewHeightAnchor != nil {
            self.textViewHeightAnchor.constant = textView.contentSize.height
            
        }
        
        self.reloadInputViews()
        
        self.currentTextViewHeight = 0.0
        self.previousTextViewHeight = 0.0
        self.additionalTextViewHeight = 0.0
       
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
    
    let tagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("@", for: .normal)
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 17
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(handleTag), for: .touchUpInside)
        return button
    }()
    
    var tagCollectionViewHeight: NSLayoutConstraint!
    @objc fileprivate func handleTag() {
        
        if self.isTagging { return }
        
        guard let text = textView.text else { return }
        if text.count == 0 || text == placeHolderText {
             textView.text = "@"
        } else {
             textView.text = text + (text.last == " " ? "@" : " @")
        }
        
        editingLook()
        
        self.updateOnTextViewChange()
        
        self.startTagging()
       
    }
    
    var textViewHeightAnchor: NSLayoutConstraint!
    var contentHeight: CGFloat?
    func textViewDidChange(_ textView: UITextView) {
      
        if self.tagCollectionView != nil {
            self.tagCollectionView.textDidChange(searchText: textView.text, tagging: self.isTagging)
        }
        
        updateOnTextViewChange()
        
        if isTagging && textView.text.last == " " {
            self.endTagging()
        } else if isTagging && textView.text.count == 0 {
            self.endTagging()
        }
        
    }
    
    func updateOnTextViewChange() {
        if self.contentHeight == nil {
            self.contentHeight = textView.contentSize.height
        }
        
        if textView.text.count > 420 {
            textView.deleteBackward()
        }
        
        let height = textView.contentSize.height
        if currentTextViewHeight == 0.0 {
            currentTextViewHeight = height
        }
        
        if height > 200 {
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
                
                delegate?.updateTableViewForText(additionalTextViewHeight: currentTextViewHeight - previousTextViewHeight)
                
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
       editingLook()
    }
    
    func editingLook() {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text.isEmpty {
            textView.text = placeHolderText
            textView.textColor = .lightGray
            self.textView.reloadInputViews()
        }
    }
    
    override func didMoveToWindow() {
        self.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 12).isActive = true
    }
    
    override var intrinsicContentSize: CGSize { return .zero }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        autoresizingMask = .flexibleHeight

        backgroundColor = .clear
        
        textView.delegate = self
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        addSubview(backgroundView)
        
        backgroundView.clipsToBounds = true
        backgroundView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.cornerRadius = (frame.height - 16) / 2
    
        addSubview(textView)
        textView.anchor(top: nil, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 56, paddingBottom: 8, paddingRight: 50, width: 0, height: 0)
        
        addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: textView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 12, width: 50, height: 50)
        
        backgroundView.anchor(top: textView.topAnchor, left: textView.leftAnchor, bottom: textView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: -4, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        addSubview(tagButton)
        tagButton.anchor(top: nil, left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: 34, height: 34)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        textView.addGestureRecognizer(swipeGesture)
        
    }
    

    @objc fileprivate func handleSwipe() {
        self.textView.endEditing(true)
    }
    
    @objc func handleSend() {
        
        self.endTagging()
        
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (text == placeHolderText ?? "") || text == "" {
            return
        }
        
        if let tagCollectionView = self.tagCollectionView {
            if tagCollectionView.selectedIdToUserDict.values.count > 0 {
                let taggedUids = Array(Set(tagCollectionView.selectedIdToUserDict.values))
                delegate?.didSubmit(for: text, taggedUids: taggedUids)
                self.tagCollectionView.selectedIdToUserDict.removeAll()
                self.tagCollectionView.reloadData()
            } else {
                delegate?.didSubmit(for: text, taggedUids: [])
            }
        } else {
            delegate?.didSubmit(for: text, taggedUids: [])
        }
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InputAccessoryView: TagCollectionViewDelegate {
    
    func didSelectName(username: String) {
       
        endTagging()
        
        guard let index = textView.text.lastIndex(of: "@") else { return }
        let substring = String(textView.text[...index])
        let newText = substring + "\(username) "
        self.textView.text = newText
        
        updateOnTextViewChange()
        
    }
    
    func didDeselectName(username: String) {
        var text = textView.text.replacingOccurrences(of: "@\(username)", with: "")
        text = text.replacingOccurrences(of: "  @", with: " @")
        textView.text = text
    }
    
    func updateText(text: String) {
        self.textView.text = text
    }
    
    func endTagging() {
        guard tagCollectionView != nil && self.isTagging else { return }
        DispatchQueue.main.async {
            self.isTagging = false
            self.delegate?.tag(add: false)
            self.tagCollectionView.isHidden = true
            self.tagCollectionView.shouldShowSearchedUsers = false
            self.tagCollectionView.reloadData()
            UIView.animate(withDuration: 0.0, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    func startTagging() {
        if self.isTagging { return }
        self.isTagging = true
        if tagCollectionView == nil {
            DispatchQueue.main.async {
                self.delegate?.tag(add: true)
            }
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            
            tagCollectionView = TagCollectionView(frame: .zero, collectionViewLayout: layout)
            tagCollectionView.tagDelegate = self
            addSubview(tagCollectionView)
            tagCollectionView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            tagCollectionViewHeight = tagCollectionView.heightAnchor.constraint(equalToConstant: 40)
            tagCollectionViewHeight.isActive = true
            
        } else {
            
            self.tagCollectionView.isHidden = false
            DispatchQueue.main.async {
                self.delegate?.tag(add: true)
            }
        }
    }
}
