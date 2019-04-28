import UIKit

protocol RolidexCellDelegate: class {
    func enterHive(hivedata: HiveData)
    func showPreview(cell: RolidexCell)
    func recalculateRolodex()
}

let imageCache2 = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    func hivePreviewCache(hd:HiveData){
        image = nil
        let cachekey = hd.id
        if let imageFromCache = imageCache2.object(forKey: cachekey as AnyObject) as? UIImage {
            DispatchQueue.main.async {
                self.image = imageFromCache
                self.isHidden = false
            }
            return
        }
        else {
            guard let imageURL = hd.previewImageUrl else {
                self.isHidden = true
                return
            }
            let request = URLRequest(url: imageURL)
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let response = data {
                    DispatchQueue.main.async {
                        guard let imageToCache = UIImage(data: response) else {return}
                        imageCache2.setObject(imageToCache, forKey: cachekey as AnyObject)
                        self.image = imageToCache
                        self.isHidden = false
                    }}
            }).resume()
            
        }
    }
}

class RolidexCell: UICollectionViewCell {
    
    weak var delegate: RolidexCellDelegate?
    
    var hiveData: HiveData? {
        didSet {
            guard let hiveData = hiveData else { return }
            self.postView.hivePreviewCache(hd: hiveData)
            self.locationLabel.text = hiveData.name
            self.distanceLabel.text = hiveData.distance.metricformat() // Need to have a USA unit format.
            
            setInHiveRange()
            
        }}
    
    func setInHiveRange() {
        guard let hivedata = hiveData else {return}
        
        if hivedata.inHiveRange {
            self.EnterHiveButton.setImage(UIImage(named: "enterhive"), for: .normal)
        } else {
            self.EnterHiveButton.setImage(UIImage(named: "toofaraway"), for: .normal)
        }
    }
    
    override func prepareForReuse() {
        self.EnterHiveButton.setTitle(nil, for: .normal)
        self.hiveData = nil
        self.postView.image = nil
        self.postView.isHidden = false
    }
    
    let postView: UIImageView = {
        let pv = UIImageView()
        pv.contentMode = .scaleAspectFill
        pv.clipsToBounds = true
        pv.isUserInteractionEnabled = true
        pv.layer.borderColor = UIColor.mainRed().cgColor
        pv.layer.borderWidth = 1
        return pv
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14/1.2)
        label.textAlignment = .center
        return label
    }()
    
    let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14/1.2)
        label.textAlignment = .center
        return label
    }()
    
    lazy var EnterHiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.clear
        button.tintColor = .mainRed()
        
        button.addTarget(self, action: #selector(enterhivefunction), for: .touchUpInside)
        return button
    }()
    
    @objc func enterhivefunction() {
        guard let hivedata = hiveData, let inRange = hiveData?.inHiveRange else { return }
        if inRange {
            delegate?.enterHive(hivedata: hivedata)
        } else {
            showTooFarAwayView()
        }
    }
    
    fileprivate func showTooFarAwayView() {
        
        let tooFarAwayLabel = UILabel()
        tooFarAwayLabel.textAlignment = .center
        tooFarAwayLabel.font = UIFont.boldSystemFont(ofSize: 14/1.2)
        tooFarAwayLabel.textColor = .mainRed()
        tooFarAwayLabel.clipsToBounds = true
        tooFarAwayLabel.text = "Too far away!"
        tooFarAwayLabel.backgroundColor = .white
        tooFarAwayLabel.numberOfLines = 0
        tooFarAwayLabel.layer.cornerRadius = 25
        self.EnterHiveButton.isEnabled = false
        addSubview(tooFarAwayLabel)
        tooFarAwayLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 50, width: 0, height: 0)
        let tooFarAwayLeft = tooFarAwayLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: frame.width - 51)
        tooFarAwayLeft.isActive = true
        
        layoutIfNeeded()
        tooFarAwayLeft.constant = 50.0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            
            self.layoutIfNeeded()
            self.EnterHiveButton.alpha = 0.0
            
        }) { (_) in
            tooFarAwayLeft.constant = self.frame.width - 51
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseInOut, animations: {
                
                self.layoutIfNeeded()
                self.EnterHiveButton.alpha = 1.0
                
            }, completion: { (_) in
                tooFarAwayLabel.removeFromSuperview()
                self.EnterHiveButton.isEnabled = true
                self.delegate?.recalculateRolodex()
                
            })
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        layer.cornerRadius = 25
        
        setShadow(offset: CGSize(width: 0, height: 1.5), opacity: 0.2, radius: 2, color: UIColor.black)
        setupViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var labelStackView: UIStackView!
    fileprivate func setupViews() {
        
        
        addSubview(postView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePreview))
        postView.addGestureRecognizer(tapGesture)
        postView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        postView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        postView.layer.cornerRadius = 25
        
        
        addSubview(EnterHiveButton)
        EnterHiveButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        EnterHiveButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        labelStackView = UIStackView(arrangedSubviews: [locationLabel, distanceLabel])
        labelStackView.axis = .vertical
        labelStackView.distribution = .fillEqually
        labelStackView.spacing = 0
        addSubview(labelStackView)
        labelStackView.translatesAutoresizingMaskIntoConstraints = false //will have to update these so that labels cant go over button or postview
        labelStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
    }
    
    @objc fileprivate func handlePreview() {
        //  self.animateLoadPreview()
        delegate?.showPreview(cell: self)
    }
    
}
