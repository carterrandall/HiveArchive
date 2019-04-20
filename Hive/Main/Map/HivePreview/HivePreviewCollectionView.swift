//
//  HivePreviewController.swift
//  Hive
//
//  Created by Carter Randall on 2019-01-31.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit

protocol HivePreviewCollectionViewDelegate: class {
    func closePreview()
    func scrollToItem(withHID: Int)
    func showProfile(user: User)
}

class HivePreviewCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var previewDelegate: HivePreviewCollectionViewDelegate?
    
    var currentMinHIDItem: Int = 0
    var currentMaxHIDItem: Int = 0
    
    var hives = [HiveData]() {
        didSet {
            for hive in hives {
                hids.append(hive.id)
            }
        }
    }
    
    var startingItem: Int? {
        didSet {
            guard let item = startingItem else { return }
            DispatchQueue.main.async {
                self.reloadData()
                self.performBatchUpdates(nil, completion: { (_) in
                    DispatchQueue.main.async {
                        print("ITEMMEMMM", item)
                        self.scrollToItem(at: IndexPath(item: 0, section: item), at: .centeredHorizontally, animated: false)
                        self.currentSection = item
                    }
                })
            }
        }
    }
    
    var hids = [Int]()
    var fetchedHids = [Int]()
    fileprivate let hivePreviewCellId = "hivePreviewCellId"
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        isPagingEnabled = true
        dataSource = self
        delegate = self
        
        register(HivePreviewCell.self, forCellWithReuseIdentifier: hivePreviewCellId)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var posts = [[Post]]()
    fileprivate func fetchPreview(hids: [Int], after: Bool, completion: @escaping() -> () = {}) {
        if hids.count == 0 { return }
        
        if after {
            self.fetchedHids = fetchedHids + hids
        } else {
            self.fetchedHids = hids + fetchedHids
        }
        print("fetching", hids, "after", after)
        let params = ["HIDS": hids] as [String: [Int]]
        RequestManager().makeJsonRequest(urlString: "/Hive/api/fetchHivePreviews", params: params) { (json, _) in
            print(json, "JSON")
            
            guard let json = json as? [String: Any] else {print("bad!"); return }
            var tempNewPosts = [[Post]]()
            if json.count > 0 {
                var postArray = [Post]()
                hids.forEach({ (hid) in
                    postArray = []
                    if let postJson = json[String(hid)] as? [[String: Any]], postJson.count > 0 {
                        postJson.forEach({ (snapshot) in
                            var post = Post(dictionary: snapshot)
                            let user = User(postdictionary: snapshot)
                            post.user = user
                            postArray.append(post)
                        })
                        
                        if after {
                            self.posts.append(postArray)
                        } else {
                            tempNewPosts.insert(postArray, at: 0)
                        }
                    } else {
                        print("appending empty post")
                        let post = Post(dictionary: ["id": -1])
                        self.posts.append([post])
                    }
                })
                
                if after {
                    self.reloadData()
                    self.performBatchUpdates(nil, completion: { (_) in
                        completion()
                    })
                } else {
                    self.reloadForNewPosts(postArray: tempNewPosts)
                }
                
               
            } else {
                
                print("json was empty, end animation")
                
            }

        }
        
    }
    

    fileprivate func reloadForNewPosts(postArray: [[Post]]) {
        print("reloading for new")
        let contentWidth = self.contentSize.width
        let offsetX = self.contentOffset.x
        let rightOffset = contentWidth - offsetX

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.performBatchUpdates({
            for array in postArray {
                var indexPaths = [IndexPath]()
                for i in 0..<array.count {
                    indexPaths.append(IndexPath(item: i, section: 0))
                }
                
                self.posts.insert(array, at: 0)
                self.currentSection += 1
                self.insertSections([0])
                self.insertItems(at: indexPaths)
            }
            
        }) { (complete) in
            DispatchQueue.main.async {
                self.contentOffset = CGPoint(x: self.contentSize.width - rightOffset, y: 0)
                print("done reloading for new")
                CATransaction.commit()
                
            }
        }
    }
    
    func attemptToScrollToSectionWithHID(hid: Int) { //this will crash if section is larger than number we have in preview
        
        guard let section = self.fetchedHids.firstIndex(of: hid) else {print("GAY", self.fetchedHids); return }
        self.scrollToItem(at: IndexPath(item: 0, section: section), at: .centeredHorizontally, animated: true)

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: hivePreviewCellId, for: indexPath) as! HivePreviewCell
        
        if indexPath.section == posts.count - 1 && indexPath.item == posts[indexPath.section].count - 1 && self.posts.count > 0 {
            if self.currentMaxHIDItem != hives.count - 1 {
                let hids = getNextHIDS()
                self.fetchPreview(hids: hids, after: true)
                self.currentMaxHIDItem += hids.count
            }
        }

        if indexPath.section == 0 && indexPath.item == 0 && currentMinHIDItem != 0 {
            let hids = getPrevHIDS()
            self.fetchPreview(hids: hids, after: false)
            self.currentMinHIDItem -= hids.count
        }
    
        cell.post = posts[indexPath.section][indexPath.item]
        cell.delegate = self
        return cell
    }
    
    fileprivate func getNextHIDS() -> [Int] {
        var nextHids = [Int]()
        var i = currentMaxHIDItem + 1
        while i < hids.count && nextHids.count < 4 {
            nextHids.append(hids[i])
            i += 1
        }
        print("next ids", nextHids)
        return nextHids
    }
    
    fileprivate func getPrevHIDS() -> [Int] {
        var prevHIDS = [Int]()
        var i = currentMinHIDItem - 1
        while i >= 0 && prevHIDS.count < 4 {
            prevHIDS.insert(hids[i], at: 0)
            i -= 1
        }
        return prevHIDS
    }
    
    var currentSection: Int = 0
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard let indexPath = indexPathForItem(at: CGPoint(x: targetContentOffset.pointee.x + (frame.width / 2), y: frame.height / 2)) else { return }
        let id = self.fetchedHids[indexPath.section]
        self.previewDelegate?.scrollToItem(withHID: id)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? HivePreviewCell {
            if cell.post?.videoUrl != nil {
                cell.handlePlay()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? HivePreviewCell {
            if cell.post?.videoUrl != nil {
                cell.player?.pause()
                cell.player = nil
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = frame.width
        return CGSize(width: width, height: (width - 20) * (4/3))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func endPlayingVideos() {
        let cells = visibleCells
        for visibleCell in cells {
            if let cell = visibleCell as? HivePreviewCell {
                cell.player?.pause()
                cell.player = nil
            }
        }
    }
    
}

extension HivePreviewCollectionView: HivePreviewCellDelegate {
    
    func closePreview() {
        DispatchQueue.main.async {
            self.endPlayingVideos()
            self.previewDelegate?.closePreview()
        }
    }
    
    func showProfileCell(user: User) {
        previewDelegate?.showProfile(user: user)
    }
    
}
