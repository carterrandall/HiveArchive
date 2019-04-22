import UIKit

protocol CaptionViewDelegate {
    func didAddCaption(isText: Bool)
}

class CaptionView: UIView, UITextViewDelegate {
    
    var delegate: CaptionViewDelegate?
    
    fileprivate var isKeyboardUp: Bool = false
    
    var isTagging: Bool = false
    
    var tagCollectionView: TagCollectionView!
    
    var taggedIds = [Int]()
    
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    
    var previousTextFieldRect: CGRect?
    
    let textView: UITextView = {
        let tf = UITextView(frame: .zero)
        tf.backgroundColor = .clear
        tf.isUserInteractionEnabled = true
        tf.autoresizingMask = .flexibleHeight
        tf.isScrollEnabled = false
        tf.autocorrectionType = .no
        tf.tintColor = .white
        tf.autocapitalizationType = .none
        tf.textContainerInset = .zero
        tf.textContainer.lineFragmentPadding = 0
        
        tf.setShadow(offset: CGSize(width: 10, height: 0), opacity: 1, radius: 0, color: UIColor.black)
        
        var style = NSMutableParagraphStyle()
        style.minimumLineHeight = 35
        style.lineBreakMode = NSLineBreakMode.byWordWrapping
        style.tailIndent = -20
        style.headIndent = 20
        style.firstLineHeadIndent = 20
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .backgroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 20), .baselineOffset: 7, .paragraphStyle: style]
        tf.typingAttributes = attributes
        
        return tf
    }()
    
    var toolBar: UIToolbar!
    let whiteOnBlackButtonView: UIButton = {
        let button = UIButton()
        button.setTitle("white on black", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.black
        button.addTarget(self, action: #selector(handleWOB), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 17
        return button
    }()
    
    let blackOnWhiteButtonView: UIButton = {
        let button = UIButton()
        button.setTitle("black on white", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 17
        button.addTarget(self, action: #selector(handleBOW), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    let tagButtonView: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("@", for: .normal)
        button.setTitleColor(UIColor.mainRed(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.layer.borderColor = UIColor.mainRed().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 17
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(handleTag), for: .touchUpInside)
    
        button.layer.borderWidth = 1
        return button
    }()
    
    @objc fileprivate func handleTag() {
        print("handling tag")
        
        if self.isTagging { return }
        
        guard let text = textView.text else { return }
        if text.count == 0 {
            textView.text = "@"
        } else {
            textView.text = text + (text.last == " " ? "@" : " @")
        }
        
        
        self.sizeInEditingMode()
        
        self.startTagging()
        
    }
    
    
    @objc func handleWOB() {
        blackView.backgroundColor = .black
        textView.tintColor = .white
        self.changeAttributes(attributes: [.foregroundColor: UIColor.white, .backgroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 20), .baselineOffset: 7, .paragraphStyle: self.paraStyle])
        textView.setShadow(offset: CGSize(width: 10, height: 0), opacity: 1, radius: 0, color: UIColor.black)
        
        blackOnWhiteButtonView.layer.borderColor = UIColor.clear.cgColor
        blackOnWhiteButtonView.layer.borderWidth = 1
        
        whiteOnBlackButtonView.layer.borderColor = UIColor.mainRed().cgColor
        whiteOnBlackButtonView.layer.borderWidth = 1
        
    }
    
    @objc func handleBOW() {
        textView.tintColor = .black
        blackView.backgroundColor = .white
        self.changeAttributes(attributes: [.foregroundColor: UIColor.black, .backgroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20), .baselineOffset: 7, .paragraphStyle: self.paraStyle])
        textView.setShadow(offset: CGSize(width: 10, height: 0), opacity: 1, radius: 0, color: UIColor.white)
        
        whiteOnBlackButtonView.layer.borderColor = UIColor.clear.cgColor
        whiteOnBlackButtonView.layer.borderWidth = 1
        
        blackOnWhiteButtonView.layer.borderColor = UIColor.mainRed().cgColor
        blackOnWhiteButtonView.layer.borderWidth = 1
    }
    
    var currentAttributes: [NSAttributedString.Key: Any]?
    fileprivate func changeAttributes(attributes: [NSAttributedString.Key: Any]) {
        let currentString = textView.attributedText.string
        
        let arr = currentString.components(separatedBy: "\n")
        
        let newString = NSMutableAttributedString()
        let blankString = NSAttributedString(string: "\n", attributes: [.backgroundColor: UIColor.clear, .foregroundColor: UIColor.clear])
        
        var numberOfBlanks = arr.count - 1
        for string in arr {
            newString.append(NSAttributedString(string: string, attributes: attributes))
            if numberOfBlanks > 0 {
                newString.append(blankString)
                numberOfBlanks -= 1
            }
            
        }
        self.textView.attributedText = newString
        self.textView.typingAttributes = attributes
        self.currentAttributes = attributes
    }
    
    let paraStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 35
        style.lineBreakMode = NSLineBreakMode.byWordWrapping
        style.headIndent = 20
        style.firstLineHeadIndent = 20
        style.tailIndent = -20
        return style
    }()
    
    var previousEditingHeight: CGFloat = 0.0
    func textViewDidChange(_ textView: UITextView) {
        
        self.sizeInEditingMode()
        
        checkDidAddCaption()
    }
    
    func checkDidAddCaption() {
        let text = textView.text
        if text == "" || text == nil {
            delegate?.didAddCaption(isText: false)
        } else {
            delegate?.didAddCaption(isText: true)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.endTagging()
        print("did end eiditng")
        if textView.text == "" { self.blackView.isHidden = true }
        if let prevRect = previousTextFieldRect, let editingRect = self.editingFrame {
            self.textView.frame.size.height = editingRect.height//prevRect.height
            self.textView.frame.size.width = prevRect.width
            
            UIView.animate(withDuration: 0.3) {
                let prevRectCenter = CGPoint(x: prevRect.origin.x + (prevRect.width / 2), y: prevRect.origin.y + (prevRect.height / 2))
                if !(self.frame.contains(prevRectCenter)) {
                    
                    self.textView.frame.origin = textView.frame.origin
                    self.previousTextFieldRect = textView.frame //if user moves it off screen
                    
                } else {
                    self.textView.frame.origin = prevRect.origin
                }
                self.blackView.frame = CGRect(x: 0, y: self.textView.frame.minY, width: 40, height: editingRect.height)
            }
            
        } else if let editingRect = self.editingFrame {
            
            self.textView.frame = editingRect
            print("NO PREV FRAME")
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        setupToolBar()
        self.blackView.isHidden = false
        return true
    }
    
    var didAddNewLine: Bool = false
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            
            self.textView.typingAttributes = [.backgroundColor: UIColor.clear, .foregroundColor: UIColor.clear]
            self.didAddNewLine = true
        } else if didAddNewLine {
            if let att = self.currentAttributes {
                self.textView.typingAttributes = att
            } else {
                self.textView.typingAttributes = [.foregroundColor: UIColor.white, .backgroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 20), .baselineOffset: 7, .paragraphStyle: self.paraStyle]
            }
            
            self.didAddNewLine = false
        }
        
        return true
    }
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        return sv
    }()
    
    func setupToolBar() {
        
        guard textView.inputAccessoryView == nil else {
            return
        }
        
      //  let w = (UIScreen.main.bounds.width - 100 / 2)
        toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        toolBar.barStyle = UIBarStyle.default
  
        let whiteOnBlackButton = UIBarButtonItem(customView: whiteOnBlackButtonView)

        let blackOnWhiteButton = UIBarButtonItem(customView: blackOnWhiteButtonView)

        let tagButton = UIBarButtonItem(customView: tagButtonView)
        tagButton.customView?.translatesAutoresizingMaskIntoConstraints = false
        tagButton.customView?.widthAnchor.constraint(equalToConstant: 36).isActive = true
        
        let positiveSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.items = [positiveSpace,tagButton,positiveSpace, whiteOnBlackButton, positiveSpace,blackOnWhiteButton, positiveSpace]
        
        
        textView.inputAccessoryView = toolBar
        
    }
    
    
    var blackView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        textView.addGestureRecognizer(panGesture)
        
        
        blackView.backgroundColor = .black
        
        addSubview(blackView)
        
        addSubview(textView)
        textView.becomeFirstResponder()
        
        blackView.frame = CGRect(x: 0, y: textView.frame.minY, width: 40, height: 0)
        
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        
        textView.resignFirstResponder()
        
        if textView.text == "" {
            textView.isHidden = true
            return
        }
        
        let translation = pan.translation(in: self)
        if let view = pan.view {
            
            view.center = CGPoint(x:view.center.x ,
                                  y:view.center.y + translation.y)
            
            blackView.frame = CGRect(x: 0, y: self.textView.frame.minY, width: 40, height: self.textView.frame.height)
            
            if let prevRect = previousTextFieldRect {
                previousTextFieldRect?.origin = CGPoint(x: prevRect.origin.x , y: prevRect.origin.y + translation.y)
            } else {
                previousTextFieldRect = textView.frame
            }
        }
        pan.setTranslation(CGPoint.zero, in: self)
    }
    
    var keyboardHeight: CGFloat!
    @objc fileprivate func keyboardWillAppear(notification: NSNotification) {
        isKeyboardUp = true
        var info = notification.userInfo!
        guard let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        keyboardHeight = keyboardSize.height
        
        let endPosition = textView.endOfDocument
        textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
            
            self.sizeInEditingMode()
        }
    }
    
    var editingFrame: CGRect?
    fileprivate func sizeInEditingMode() {
        let fixedWidth = self.textView.frame.size.width
        let newSize = self.textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        let rect = CGRect(x: 0, y: self.frame.height - self.keyboardHeight - size.height, width: self.screenWidth, height: size.height)
        self.textView.frame = rect
        self.blackView.frame = CGRect(x: 0, y: rect.minY, width: 40, height: rect.height)
        self.editingFrame = rect
    }
    
    @objc fileprivate func keyboardWillHide(notification: NSNotification) {
        isKeyboardUp = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startTagging() {
        if self.isTagging { return }
        self.isTagging = true
        if tagCollectionView == nil {
            DispatchQueue.main.async {
                self.insertTag(insert: true)
            }
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            
            tagCollectionView = TagCollectionView(frame: .zero, collectionViewLayout: layout)
            tagCollectionView.tagDelegate = self
            
            addSubview(tagCollectionView)
            tagCollectionView.anchor(top: nil, left: leftAnchor, bottom: textView.topAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
           
            
        } else {
            
            self.tagCollectionView.isHidden = false
            DispatchQueue.main.async {
                self.insertTag(insert: true)
            }
        }
    }
    
    func insertTag(insert: Bool) {
        print("insert", insert)
    }
    
    
    func endTagging() {
        guard tagCollectionView != nil && self.isTagging else { return }
        DispatchQueue.main.async {
            self.isTagging = false
            self.insertTag(insert: false)
            self.tagCollectionView.isHidden = true
            self.tagCollectionView.shouldShowSearchedUsers = false
            self.tagCollectionView.reloadData()
            UIView.animate(withDuration: 0.0, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
}

extension CaptionView: TagCollectionViewDelegate {
   
    func didSelectName(username: String) {
        print("did select name")
        endTagging()
        
        guard let index = textView.text.lastIndex(of: "@") else { return }
        let substring = String(textView.text[...index])
        let newText = substring + "\(username) "
        self.textView.text = newText
        
        sizeInEditingMode()
        
    }
    
    func didDeselectName(username: String) {
        var text = textView.text.replacingOccurrences(of: "@\(username)", with: "")
        text = text.replacingOccurrences(of: "  @", with: " @")
        textView.text = text
        self.sizeInEditingMode()
    }
    
    func updateText(text: String) {
         self.textView.text = text
        self.sizeInEditingMode()
    }
    
    func updateTags(ids: [Int]) {
        self.taggedIds = ids
        let text = textView.text
        if text == "" || text == nil {
            delegate?.didAddCaption(isText: false)
        } else {
            delegate?.didAddCaption(isText: true)
        }
    }
    
}


