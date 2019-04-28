//
//  CreateHiveMenuCell.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-03.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol CreateHiveMenuCellDelegate: class {
    func cancelBack(cell: CreateHiveMenuCell)
    func nextCreate(cell: CreateHiveMenuCell)
    func handleSliderValuedChanged(value: Float)
}

class CreateHiveMenuCell: UICollectionViewCell {
    
    var stage: Int = 0 {
        didSet {
            if stage == 0 {
                self.createHiveSlider.isHidden = false
                self.nameTextField.isHidden = true
                self.nextCreateButton.isEnabled = true
            } else {
                self.createHiveSlider.isHidden = true
                self.nameTextField.isHidden = false
                self.nextCreateButton.isEnabled = false
            }
        }
    }
    
    weak var delegate: CreateHiveMenuCellDelegate?
    
    lazy var nameTextField : UITextField = {
        let tf = UITextField()
        tf.font = UIFont.boldSystemFont(ofSize: 16)
        tf.placeholder = "Name"
        tf.backgroundColor = UIColor.white
        tf.textAlignment = .center
        tf.autocapitalizationType = .words
        tf.isHidden = true
        tf.addTarget(self, action: #selector(handleNameTextField), for: .editingChanged)
        return tf
    }()
    
    @objc func handleNameTextField() {
        guard let text = self.nameTextField.text?.trimmingCharacters(in: .whitespaces) else { return }
        if text.count > 0 {
            self.nextCreateButton.isEnabled = true
        } else {
            self.nextCreateButton.isEnabled = false
        }
        if text.count > 30 {
            nameTextField.deleteBackward()
        }
    }
    
    lazy var createHiveSlider : UISlider = {
        let slider = UISlider()
        slider.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        slider.minimumTrackTintColor = UIColor.mainRed()
        slider.maximumTrackTintColor = UIColor.lightGray
        slider.thumbTintColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        slider.maximumValue = 200
        slider.minimumValue = 1 //km
        slider.setValue(50, animated: false)
        slider.addTarget(self, action: #selector(handleCreateHiveSlider), for: .valueChanged)
        return slider
    }()
    
    @objc fileprivate func handleCreateHiveSlider() {
        delegate?.handleSliderValuedChanged(value: createHiveSlider.value)
    }
    
    lazy var cancelBackButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleCancelBack), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleCancelBack() {
        delegate?.cancelBack(cell: self)
    }
    
    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hold and drag to move the center."
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    lazy var nextCreateButton: UIButton = {
        let button = UIButton()
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.mainRed(), for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.addTarget(self, action: #selector(handleNextCreate), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleNextCreate() {
        delegate?.nextCreate(cell: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
       
        addSubview(cancelBackButton)
        cancelBackButton.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 80, height: 50)
        
        addSubview(nextCreateButton)
        nextCreateButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 80, height: 50)
        
        addSubview(instructionLabel)
        instructionLabel.anchor(top: topAnchor, left: cancelBackButton.rightAnchor, bottom: nil, right: nextCreateButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        addSubview(nameTextField)
        nameTextField.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 40)
        
        addSubview(createHiveSlider)
        createHiveSlider.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 40)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
