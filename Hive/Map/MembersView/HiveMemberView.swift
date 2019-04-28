//
//  HiveMemberView.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-26.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol HiveMemberViewDelegate: class {
    func showProfile(user: User)
}

class HiveMemberView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var memberDelegate: HiveMemberViewDelegate?
    
    var hid: Int? {
        didSet {
            paginateMembers()
        }
    }
    
    fileprivate let memberCellId = "memberCellId"
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        

        dataSource = self
        delegate = self
        decelerationRate = .fast
        backgroundColor = .clear
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false
        register(HiveMemberCell.self, forCellWithReuseIdentifier: memberCellId)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var lastIndex: Int = 0
    var isFinishedPaging: Bool = false
    var users = [User]()
    var uids = [Int]()
    fileprivate func paginateMembers() {
        print("paginateing")
        guard let hid = self.hid else { return }
        let params = ["HID": hid, "lastIndex": lastIndex]
        self.lastIndex += 1
        RequestManager().makeJsonRequest(urlString: "/Hive/api/paginateHiveMembers", params: params) { (json, _) in
            guard let json = json as? [[String: Any]] else { return }
            self.isFinishedPaging = (json.count < 10 ? true : false)
            if json.count > 0 {
                json.forEach({ (snapshot) in
                    let user = User(dictionary: snapshot)
                    if !self.uids.contains(user.uid) {
                        self.uids.append(user.uid)
                        self.users.append(user)
                    }
                })
                
                self.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        memberDelegate?.showProfile(user: users[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: memberCellId, for: indexPath) as! HiveMemberCell
        
        if indexPath.item == users.count - 1 && !isFinishedPaging {
            self.paginateMembers()
        }
        
        cell.layer.cornerRadius = 30
        cell.user = users[indexPath.item]
        cell.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    
    
}
