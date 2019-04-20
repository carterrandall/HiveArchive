//
//  CreateHiveMenuBar.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-03.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol CreateHiveMenuBarDelegate: class {
    func cancelCreateHive()
    func handleNextCreateHive(sliderValue: Float)
    func createCreateHive(sliderValue: Float, name: String)
    func handleCreateHiveSliderValueChanged(value: Float)
    func invalidName()
}

class CreateHiveMenuBar: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let createHiveMenuCellId = "createHiveCellId"
    
    weak var menuBarDelegate: CreateHiveMenuBarDelegate?
    
    fileprivate var sliderValue: Float = 50
   
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        isScrollEnabled = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        backgroundColor = .white
        dataSource = self
        delegate = self
        register(CreateHiveMenuCell.self, forCellWithReuseIdentifier: createHiveMenuCellId)
        setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: createHiveMenuCellId, for: indexPath) as! CreateHiveMenuCell
        if indexPath.item == 0 {
            cell.cancelBackButton.setTitle("Cancel", for: .normal)
            cell.nextCreateButton.setTitle("Next", for: .normal)
            cell.instructionLabel.text = "Adjust the location and size"
            cell.stage = 0
        } else {
            cell.cancelBackButton.setTitle("Back", for: .normal)
            cell.nextCreateButton.setTitle("Create", for: .normal)
            cell.instructionLabel.text = "Name your Hive"
            cell.stage = 1
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: frame.width, height: frame.height - UIApplication.shared.statusBarFrame.height)
    
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == 1 {
            if let cell = cell as? CreateHiveMenuCell {
  
                cell.nameTextField.becomeFirstResponder() 
          
            }
        }
    }
    
}

extension CreateHiveMenuBar: CreateHiveMenuCellDelegate {
    
    func handleSliderValuedChanged(value: Float) {
        self.sliderValue = value
        menuBarDelegate?.handleCreateHiveSliderValueChanged(value: value)
    }
    
    
    func cancelBack(cell: CreateHiveMenuCell) {
        guard let indexPath = indexPath(for: cell) else { return }
        
        if indexPath.item == 1 {
            DispatchQueue.main.async {
                self.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
                cell.nameTextField.resignFirstResponder()
            }
        } else {
            menuBarDelegate?.cancelCreateHive()
        }
    }

    func nextCreate(cell: CreateHiveMenuCell) {
        print("nextcreate")
        guard let indexPath = indexPath(for: cell) else { return }
        if indexPath.item == 0 {
            menuBarDelegate?.handleNextCreateHive(sliderValue: self.sliderValue)
        } else {
            guard let name = cell.nameTextField.text else { return }
            let nameCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-'èéêëēėęÿûüùúūîïíīįìôöòóœøōõàáâäæãåāßśšłžźżçćčñń ")
            if name.rangeOfCharacter(from: nameCharacterSet.inverted) != nil || name.containsSwearWord(text: name) {
                menuBarDelegate?.invalidName()
                self.endEditing(true)
            } else {
                menuBarDelegate?.createCreateHive(sliderValue: self.sliderValue, name: name)
            }
            
        }
    }
    
    func validHive() {
        print("Scrolling")
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: 1, section: 0)
            self.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
        }
    }
    
    

}
