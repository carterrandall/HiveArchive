//
//  MapRenderExtensions.swift
//  Hive
//
//  Created by Carter Randall on 2019-02-02.
//  Copyright © 2019 Carter Randall. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox
import Alamofire

extension MapRender: HiveMemberViewDelegate {
    func showProfile(user: User) {
        DispatchQueue.main.async {
            let profileController = ProfileMainController()
            profileController.userId = user.uid
            profileController.partialUser = user
            let profileNavController = UINavigationController(rootViewController: profileController)
            self.tabBarController?.present(profileNavController, animated: true, completion: nil)
        }
    }
}

extension MapRender: UserCalloutDelegate {
    
    func goToChat(user: User) {
        DispatchQueue.main.async {
            let chatController = ChatController(style: .grouped)
            chatController.idToUserDict = [user.uid: user]
            chatController.isFromMap = true
            let chatNavController = UINavigationController(rootViewController: chatController)
            chatNavController.modalPresentationStyle = .overFullScreen
            self.tabBarController?.present(chatNavController, animated: true, completion: nil)
        }
    }
    
    func goToProfile(id: Int) {
        DispatchQueue.main.async {
            let profileController = ProfileMainController()
            profileController.userId = id
            let profileNavController = UINavigationController(rootViewController: profileController)
            self.present(profileNavController, animated: true, completion: nil)
        }
    }

}

extension MapRender: HivePreviewCollectionViewDelegate {
    
    @objc func closePreview() {
        isPreviewShowing = false
        
        self.previewCenterY.constant = self.view.frame.height
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            self.previewContainer.removeFromSuperview()
            self.previewCollectionView.removeFromSuperview()
        }
        
    }
    
    func scrollToItem(withHID: Int) {
        DispatchQueue.main.async {
            guard let index = self.rolodexHives.firstIndex(where: { (data) -> Bool in
                return data.id == withHID
            }) else { return }
            
            self.hiveCollectionView.scrollToItem(at: IndexPath(item: index + 1 , section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
}


//MARK - ALL CREATE HIVE STUFF 
extension MapRender: CreateHiveCellDelegate {
    
    func didTapCreateHive() {
        if let location = MapRender.mapView.userLocation?.coordinate, (location.latitude != -180 && location.longitude != -180) {
            DispatchQueue.main.async {
                self.displayCreateHiveViews()
                self.displayCreateHiveMapElements()
            }
        }else{
            recalculateRolodex()
        }
    }
    
    func displayCreateHiveMapElements() {
        MapRender.newHiveAnnotation.coordinate = MapRender.mapView.centerCoordinate
        MapRender.newHiveAnnotation.title = "To move the center point, first tap and hold."
        let circlesource = MGLShapeSource(identifier: "newhivecirclesource", shape: MapRender.newHiveAnnotation, options: nil)
        let circlelayer = MGLCircleStyleLayer(identifier: "newhivecirclelayer", source: circlesource)
        circlelayer.circleRadius = NSExpression(forConstantValue: MapRender.createHiveSliderValue) //CHANGE THIS TO BE SET AND PASSED TO MENU BAR
        print("See the comments here - displaycreatehivemapelements()")
        circlelayer.circleColor = NSExpression(forConstantValue: UIColor.mainRed())
        circlelayer.circleOpacity = NSExpression(forConstantValue: 0.6)
        MapRender.mapView.addAnnotation(MapRender.newHiveAnnotation)
        MapRender.mapView.style?.addSource(circlesource)
        MapRender.mapView.style?.addLayer(circlelayer)
    }
    
    func displayCreateHiveViews() {
        
        self.navigationController?.navigationBar.isHidden = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        createHiveMenuBar = CreateHiveMenuBar(frame: .zero, collectionViewLayout: layout)
        self.view.addSubview(createHiveMenuBar)
        createHiveMenuBar.menuBarDelegate = self
        let height = 90 + UIApplication.shared.statusBarFrame.height //why status bar height here huh?
        createHiveMenuBar.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: height)
        createHiveMenuBarTopAnchor = createHiveMenuBar.topAnchor.constraint(equalTo: view.topAnchor, constant: -height)
        createHiveMenuBarTopAnchor.isActive = true
        self.view.layoutIfNeeded()
        
        DispatchQueue.main.async {
            self.createHiveMenuBarTopAnchor.constant = 0.0
            self.hiveCollectionViewBottomAnchor.constant = height //make sure this value is always sufficient
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }) { (_) in
                self.hiveCollectionView.isHidden = true
            }
        }
        
        
    }

    
}

extension MapRender: CreateHiveMenuBarDelegate {
    
    func invalidName() {
        self.showInvalidHiveView(infraction: "Name")
    }
    
    //DELEGATE
    func cancelCreateHive() {
        MapRender.createHiveSliderValue = 50
        self.removeCreateHiveMap()
        self.showMainApplicationViews()
    }
    
    func removeCreateHiveMap() {
        MapRender.mapView.removeAnnotation(MapRender.newHiveAnnotation)
        guard let layer = MapRender.mapView.style?.layer(withIdentifier: "newhivecirclelayer") else {return}
        MapRender.mapView.style?.removeLayer(layer)
        guard let source = MapRender.mapView.style?.source(withIdentifier: "newhivecirclesource") else {return}
        MapRender.mapView.style?.removeSource(source)
    }

    func showMainApplicationViews(){
        
        self.hiveCollectionView.isHidden = false
        self.hiveCollectionViewBottomAnchor.constant = 0.0
        self.createHiveMenuBarTopAnchor.constant = -(90 + UIApplication.shared.statusBarFrame.height)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                
            }, completion: { (_) in
                self.navigationController?.navigationBar.isHidden = false
                self.createHiveMenuBar.removeFromSuperview()
            })
        }
    }
    
    func handleNextCreateHive(sliderValue: Float) {
//        self.createHiveMenuBar.validHive()
        guard let location = MapRender.mapView.userLocation?.location  else {return}
        let coordinate = MapRender.newHiveAnnotation.coordinate
        let distance = location.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        let latitude = Double(coordinate.latitude)*Double.pi/180  // lat in radians
        let zoom = MapRender.mapView.zoomLevel
        let rfloat = sliderValue //PASS VALUE TO HERE
        let radius = Double(rfloat)*111.6752141*cos(latitude)/(pow(2, zoom))
        if (distance > 20000) || (radius > 3) || (radius < 0.1) { // If distance is > 50km or radius is > 15 km dont let hive be made :
            if (distance > 20000) && (radius > 3) {
                showInvalidHiveView(infraction: "Both")
            } else if (distance > 20000 && radius < 0.1){
                showInvalidHiveView(infraction: "bothsmall")
            }else if radius > 3{
                showInvalidHiveView(infraction: "radius")
            }else{
                showInvalidHiveView(infraction: "small")
            }
        }else {
            self.createHiveMenuBar.validHive()
        }
    }
    
    fileprivate func showInvalidHiveView(infraction: String) {
        
        self.tintView = UIView()
        tintView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        invalidHiveView = InvalidHiveView()
        invalidHiveView.delegate = self
        invalidHiveView.infraction = infraction
        
        view.addSubview(tintView)
        tintView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        tintView.alpha = 0.0
        view.addSubview(invalidHiveView)
        invalidHiveView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 100)
        self.invalidHiveViewCenterY = invalidHiveView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: (view.frame.height / 2 + 50))
        self.invalidHiveViewCenterY.isActive = true
        self.view.layoutIfNeeded()
        self.invalidHiveViewCenterY.constant = 0.0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.tintView.alpha = 1.0
        }) { (_) in
            
        }
        
    }

    func createCreateHive(sliderValue: Float, name: String) {
        let latitude = Double(MapRender.newHiveAnnotation.coordinate.latitude)*Double.pi/180  // lat in radians
        let zoom = MapRender.mapView.zoomLevel
        let rfloat = sliderValue
        let radius = Double(rfloat)*111.6752141*cos(latitude)/(pow(2, zoom))
        let HID = NSUUID().uuidString
        generateHive(name: name, HID: HID, center: MapRender.newHiveAnnotation.coordinate, radius: radius)
        self.cancelCreateHive()
    }
    
    func generateHive(name: String, HID: String, center: CLLocationCoordinate2D, radius: Double) {
        let data = generateHiveData(name: name, key: HID, centercoordinates: center, radius: radius)
        if let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/createHive") {
            let latitude = center.latitude
            let longitude = center.longitude
            guard let namedata = name.data(using: .utf8), let radiusdata = "\(radius)".data(using: .utf8), let latitudedata = "\(latitude)".data(using: .utf8), let longitudedata = "\(longitude)".data(using: .utf8) else {return}
            Alamofire.upload(multipartFormData: { (multipart) in
                multipart.append(data, withName: "file", fileName: "\(HID).geojson", mimeType: "application/octet-stream")
                multipart.append(namedata, withName: "name")
                multipart.append(radiusdata, withName: "radius")
                multipart.append(latitudedata, withName: "latitude")
                multipart.append(longitudedata, withName: "longitude")
            }, usingThreshold: UInt64.init(), to: url, method: .post, headers: header) { (stuff) in
                switch stuff {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        //                        debugPrint("debug Print", response)
                        if let json = response.result.value as? [String:Any], let location = MapRender.mapView.userLocation?.coordinate, let urlString = json["url"] as? String, let jsonUrl = URL(string: urlString) {
                            let HJ = HiveJson(json: json, userLocation: CLLocation(latitude: location.latitude, longitude: location.longitude), jsonUrl: jsonUrl)
                            self.appendRolodexHive(data: HJ, scrollTo: true, enterHive: false, fromCamera: false)
                        }
                    }
                    upload.uploadProgress { progress in
                        print("upload progress",progress.fractionCompleted)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                    //                print("failute : ",encodingError)
                }
            }
        }else{
            // JWT not working.
        }
    }

    
    //DELEGATE
    func handleCreateHiveSliderValueChanged(value: Float) {
        MapRender.createHiveSliderValue = value
        guard let circlelayer = MapRender.mapView.style?.layer(withIdentifier: "newhivecirclelayer") as? MGLCircleStyleLayer else {return}
        circlelayer.circleRadius = NSExpression(forConstantValue: value)
    }
    
}

extension MapRender: InvalidHiveViewDelegate {
    func closeInvalidHiveView() {// animate this
        
        self.invalidHiveViewCenterY.constant = (self.view.frame.height / 2) + 50
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.tintView.alpha = 0.0
        }) { (_) in
            self.invalidHiveView.removeFromSuperview()
            self.tintView.removeFromSuperview()
        }
        
    }
}

extension MapRender: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFirstLayout {
            if rolodexHives.count >= 1 {
                DispatchQueue.main.async {
                    self.hiveCollectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
                    self.isFirstLayout = false
                }
            }
            return rolodexHives.count + 1 // 1 is the create hive cell.
        }
        else{
            return rolodexHives.count + 1 // 1 is the create hive cell.
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = hiveCollectionView.dequeueReusableCell(withReuseIdentifier: createhivecellid, for: indexPath) as! CreateHiveCell
            cell.delegate = self
            return cell
        }
        else { // This seems to get everything in the right order, now I have to get the highlighting correct on click.
            let cell = hiveCollectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! RolidexCell
            cell.hiveData = rolodexHives[indexPath.item-1]
            cell.delegate = self
            return cell
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if isPreviewShowing {
            
            guard let indexPath = hiveCollectionView.indexPathForItem(at: CGPoint(x: targetContentOffset.pointee.x + view.frame.width / 2, y: hiveCollectionView.frame.height / 2)) else { print("NO INDEX"); return }
            if indexPath.item == 0  || indexPath.item == self.currentPreviewIndex {
                return
            } else {
                self.currentPreviewIndex = indexPath.item
                self.previewCollectionView.attemptToScrollToSectionWithHID(hid: self.rolodexHives[indexPath.item - 1].id)
            }
        }
    }
}
