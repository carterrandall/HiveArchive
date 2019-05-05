import UIKit

class FeedHeaderPageIndicator: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate let cellId = "cellId"
    
    var numberOfItems: Int? {
        didSet {
            reloadData()
        }
    }
    
    var selectedPostIndex: Int = 0 {
        didSet {
            reloadData()
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        delegate = self
        dataSource = self
        backgroundColor = .clear
        isScrollEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        
        cell.layer.cornerRadius = 1.5
        if let numberOfItems = self.numberOfItems, numberOfItems == 1 {
            cell.backgroundColor = .clear
        } else if indexPath.item <= selectedPostIndex {
            cell.backgroundColor = .mainRed()
        } else {
            cell.backgroundColor = UIColor(white: 1, alpha: 0.3)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 3, height: 3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let count = (numberOfItems ?? 1)
        let totalCellWidth = 4 * count
        let totalSpacingWidth = 3 * (count - 1)
        
        let leftInset = (self.frame.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    
}



