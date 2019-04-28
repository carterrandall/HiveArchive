
import UIKit

protocol CreateHiveCellDelegate {
    func didTapCreateHive()
}


class CreateHiveCell: UICollectionViewCell {
    func disableCreateHiveButton() {
        print("disabling the button")
        CreateHiveButton.setTitle("Enable Location Services", for: .normal)
        CreateHiveButton.setTitleColor(UIColor.mainBlue(), for: .normal)
        CreateHiveButton.removeTarget(self, action: #selector(handlecreatehive), for: .touchUpInside)
        CreateHiveButton.addTarget(self, action: #selector(handleOpenSettings), for: .touchUpInside)
    }
    
    func enableCreateHiveButton() {
        CreateHiveButton.setTitle("Create A New Hive", for: .normal)
        CreateHiveButton.setTitleColor(UIColor.mainRed(), for: .normal)
        CreateHiveButton.removeTarget(self, action: #selector(handleOpenSettings), for: .touchUpInside)
        CreateHiveButton.addTarget(self, action: #selector(handlecreatehive), for: .touchUpInside)
    }
    
    @objc func handleOpenSettings(){
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString)  ,UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { (success) in
                print("settings opened")
            }
        }
    }
    
    var delegate : CreateHiveCellDelegate?
    
    lazy var CreateHiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.clear
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14/1.2)
        if (MapRender.mapView.locationManager.authorizationStatus.rawValue == 2) {
            button.setTitle("Enable Location Services", for: .normal)
            button.setTitleColor(UIColor.mainBlue(), for: .normal)
            button.addTarget(self, action: #selector(handleOpenSettings), for: .touchUpInside)
        }else{
            button.setTitle("Create A New Hive", for: .normal)
            button.setTitleColor(UIColor.mainRed(), for: .normal)
            button.addTarget(self, action: #selector(handlecreatehive), for: .touchUpInside)
        }
        return button
    }()
    
    @objc func handlecreatehive() {
        delegate?.didTapCreateHive()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        setShadow(offset: CGSize(width: 0, height: 1.5), opacity: 0.2, radius: 2, color: UIColor.black)
        layer.cornerRadius = 25
        
        addSubview(CreateHiveButton)
        CreateHiveButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        CreateHiveButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        CreateHiveButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

