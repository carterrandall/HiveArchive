//
//  PhotoSelectionController.swift
//  Highve
//
//  Created by Carter Randall on 2018-10-21.
//  Copyright © 2018 Carter Randall. All rights reserved.
//

import UIKit
import Photos
protocol PhotoSelectionControllerDelegate {
    func didSelectPhoto(image: UIImage)
    func endSessionAfterShare()
}

extension PhotoSelectionControllerDelegate {
    func didSelectPhoto(image: UIImage) {}
    func endSessionAfterShare() {}
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class PhotoSelectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    let targetSize = CGSize(width: 200, height: 200)
    
    let cellId = "cellId"
    let headerId = "headerId"
    
    var delegate: PhotoSelectionControllerDelegate?
    
    var isFromCamera: Bool = false
    
    var backgroundImageView: UIImageView?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isFromCamera {
            backgroundImageView = UIImageView()
            backgroundImageView?.contentMode = .scaleAspectFill
            backgroundImageView?.clipsToBounds = true
            backgroundImageView?.frame = view.frame
            view.insertSubview(backgroundImageView!, at: 0)
            let whiteView = UIView()
            whiteView.backgroundColor = .white
            view.insertSubview(whiteView, aboveSubview: backgroundImageView!)
            whiteView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            collectionView.backgroundColor = .clear
            collectionView.bounces = false
        } else {
            collectionView.backgroundColor = .black
        }
        
        collectionView.register(PhotoSelectionCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(PhotoSelectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.showsVerticalScrollIndicator = false
        
        resetCachedAssets()
        
        if fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
        
        setupNavigationButtons()
        
    }
    
    var shouldUpdateAssets: Bool = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldUpdateAssets {
            updateCachedAssets()
            selectedAsset = fetchResult.object(at: 0)
            collectionView.reloadData()
        }
    }
    
    fileprivate func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else { return }
        
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: targetSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: targetSize, contentMode: .aspectFill, options: nil)
        
        
        previousPreheatRect = preheatRect
        
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func setupNavigationButtons() {
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        if self.isFromCamera {
            navigationController?.makeTransparent()
            
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            view.addSubview(blurView)
            blurView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            let cancelButtonView: UIButton = {
                let button = UIButton(type: .system)
                button.setTitle("Cancel", for: .normal)
                button.tintColor = .white
                button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
                button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
                button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
                return button
            }()
            
            let doneButtonView: UIButton = {
                let button = UIButton(type: .system)
                button.setTitle("Done", for: .normal)
                button.tintColor = .white
                button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
                button.setShadow(offset: .zero, opacity: 0.3, radius: 3, color: UIColor.black)
                button.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
                return button
            }()
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButtonView)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButtonView)
           
          
        } else {
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
            navigationController?.navigationBar.barTintColor = .black
            navigationItem.leftBarButtonItem = cancelButton
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDone))
            navigationItem.rightBarButtonItem = doneButton
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        }

    }
    
    
    @objc func handleCancel() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    @objc func handleDone() {
        
        guard let photoImageView = header?.photoImageView else { return }
        guard let image = photoImageView.image else { return }
        guard let scrollView = header?.scrollView else { return }
        
        let scale:CGFloat = 1/scrollView.zoomScale
        let x:CGFloat = scrollView.contentOffset.x * scale
        let y:CGFloat = scrollView.contentOffset.y * scale
        let width:CGFloat = scrollView.frame.size.width * scale
        let height:CGFloat = scrollView.frame.size.height * scale
        
        
        if let croppedCGImage = image.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height)) {
            let croppedImage = UIImage(cgImage: croppedCGImage)
            print("need to end session somehow after sharing, probably just a double delegate")
            if isFromCamera {
                self.presentPreviewPhotoController(image: croppedImage)
            } else {
                delegate?.didSelectPhoto(image: croppedImage)
                self.dismiss(animated: true, completion: nil)
            }
            
        } else {
            if isFromCamera {
                self.presentPreviewPhotoController(image: image)
            
            } else {
                delegate?.didSelectPhoto(image: image)
                self.dismiss(animated: true, completion: nil)
            }
            
        }
        
    }
    
    fileprivate func presentPreviewPhotoController(image: UIImage) {
        self.shouldUpdateAssets = false
        let previewPhotoController = PreviewPhotoController()
        previewPhotoController.image = image
        previewPhotoController.delegate = self
        previewPhotoController.isFromCameraRoll = self.isFromCamera
        self.navigationController?.pushViewController(previewPhotoController, animated: true)
    }
    
    var header: PhotoSelectionHeader?
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! PhotoSelectionHeader
        //optimization: store images as they are selected incase user selects different image then goes back to it
        
        self.header = header
        
        header.isFromCamera = self.isFromCamera
        
        if let selectedAsset = selectedAsset {
            
            let selectedIndex = fetchResult.index(of: selectedAsset)
            let selectedAsset = fetchResult.object(at: selectedIndex)
            let imageManager = PHImageManager.default()
            let largerTargetSize = CGSize(width: 1000, height: (isFromCamera ? (1000 * (4/3)) : 1000))
            imageManager.requestImage(for: selectedAsset, targetSize: largerTargetSize, contentMode: .aspectFit, options: nil) { (image, info) in
                
                    header.image = image
                if let backgroundiv = self.backgroundImageView {
                    backgroundiv.image = image
                }
            }
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = view.frame.width
        if isFromCamera {
            return CGSize(width: width, height: width * (4/3))
        } else {
            return CGSize(width: width, height: width)
        }
    }
    
    var selectedImage: UIImage?
    var selectedAsset: PHAsset?
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let asset = fetchResult.object(at: indexPath.item)
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, _) in
            DispatchQueue.main.async {
                self.selectedAsset = asset
                self.selectedImage = image
                self.collectionView.reloadData()
                self.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
                
            }
            
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PhotoSelectionCell
        
        let asset = fetchResult.object(at: indexPath.item)
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, _) in
            
            cell.photoImageView.image = image
            self.selectedImage = image
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3) / 4
        if self.isFromCamera {
            return CGSize(width: width, height: width * 4/3)
        } else {
            return CGSize(width: width, height: width)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
}

extension PhotoSelectionController: PreviewPhotoControllerDelegate {
    func endSessionAfterShare() {
        delegate?.endSessionAfterShare()
    }
    
    
}

