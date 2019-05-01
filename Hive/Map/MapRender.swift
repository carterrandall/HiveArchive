

import UIKit
import CoreLocation
import Mapbox
import Alamofire

class MapRender: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, RolidexCellDelegate {
    
    static let newHiveAnnotation = MGLPointAnnotation()
    static var currentHiveInfo = [Any]() //used in enter hive and other places
    static let didEnterHiveNotificationName = NSNotification.Name(rawValue: "didEnterHive")//used in enter hive
    static var createHiveSliderValue: Float = 50
    var mapLayers : [String] = [] // This is for Handle map Tap.
    var rolodexHives : [HiveData] = []

    let cellId = "cellId"
    let createhivecellid = "createhivecellid"
    
    var isFirstLayout = true
    var invalidHiveView: InvalidHiveView!
    var invalidHiveViewCenterY: NSLayoutConstraint!
    var tintView: UIView!
    var createHiveMenuBar: CreateHiveMenuBar!
    var hiveCollectionViewBottomAnchor: NSLayoutConstraint!
    var createHiveMenuBarTopAnchor: NSLayoutConstraint!

    let hiveCollectionView: UICollectionView = {
        let flowLayout = ZoomAndSnapFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = UIScrollView.DecelerationRate.fast
        return cv
    }()
    
    static let mapView : MGLMapView = {
        let mv = MGLMapView()
        mv.allowsTilting = false
        mv.allowsRotating = false
        
        mv.attributionButton.tintColor = UIColor.lightGray
        mv.attributionButton.alpha = 0.5
        mv.attributionButton.setImage(UIImage(named:"info"), for: .normal)
       // mv.attributionButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
        
        mv.logoView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        mv.logoView.alpha = 0.5
       
        return mv
    }()
    
    static let didEnterForegroundForMapNotificationName = NSNotification.Name(rawValue: "didEnterForeground")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.setupMapView()
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.handleMapTap(sender:)))
        for recognizer in MapRender.mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {singleTap.require(toFail: recognizer)}
        MapRender.mapView.addGestureRecognizer(singleTap)
        self.setupHiveCollectionView()
        self.setupNavBar()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterForeground), name: MapRender.didEnterForegroundForMapNotificationName,  object: nil)
        
    } // End func viewDidLoad()
    
    func logoutOfMap(){ // check that this will work when you are in a hive as well.
        var annotations = [MGLAnnotation]()
        let keys = self.friendAnnotations?.keys
        keys?.forEach({ (int) in
            if let annotation = self.friendAnnotations?[int] {
                annotations.append(annotation)
            }
        })
        MapRender.mapView.removeAnnotations(annotations)
        self.lastRadius = nil
        self.lastCenter = nil
        self.doneLoadingHivesInArea = false
        self.previousLocation = nil
        self.lastFriendUpdate = 0.0
        MapRender.currentHiveInfo = []
        // Also find a way to remove the current user annotation, as we need that to switch pretty fuckin fast brah.
        // That is importantski.
        // This should handle most things, but test it, because we need to re add the user annotation
        // maybe clear the caches as well.
        
        // Set the map camera back to normal, or dont worry about it on login.
    }
    
    var isFirstInset: Bool = true
    override func viewSafeAreaInsetsDidChange() {
        if isFirstInset {
            let mv = MapRender.mapView
            mv.logoView.anchor(top: nil, left: mv.leftAnchor, bottom: mv.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: -10, paddingBottom: view.safeAreaInsets.bottom - 10, paddingRight: 0, width: 0, height: 0)
            mv.attributionButton.anchor(top: nil, left: nil, bottom: mv.bottomAnchor, right: mv.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: view.safeAreaInsets.bottom - 10, paddingRight: 0, width: 20, height: 20)
            isFirstInset = false
        }
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("view is appearing now")
        if (MainTabBarController.didLogout){
            print("did logout now")
            MapRender.mapView.showsUserLocation = false
            MapRender.mapView.showsUserLocation = true
            // should really just check if we are in a hive for sure.
            // reset all the shit on the map.
            if let annotation = MapRender.mapView.annotations{
                MapRender.mapView.removeAnnotations(annotation)
            }
            self.lastCenter = nil
            self.lastRadius = nil
            self.lastFriendUpdate = 0.0
            MainTabBarController.didLogout = false
            //            MainTabBarController.didLogout = false
            //            handleUserLocation(userLocation: MapRender.mapView.userLocation)
        }else{
            handleMapIsAppearing()
        }
        
    }
    
    func handleMapIsAppearing(){
        if (MapRender.mapView.locationManager.authorizationStatus.rawValue == 2) { // 2 is denied, 4 is when in use it seems to me.
            if let _ = MainTabBarController.currentUser?.HID {
                if (MapRender.currentHiveInfo.count == 0){
                    self.didEnterHiveOnLaunch = false
                    // make them leave the hive, then do other stuff.
                    self.exitHiveDatabase()
                    MainTabBarController.currentUser?.HID = nil
                }else{ // so we have entered the hive display wise.
                    self.handleexitHiveButton()
                }
            }else{
                if (MapRender.currentHiveInfo.count > 0){
                    self.handleexitHiveButton()
                }else{
                    checkForNewNotifications()
                }
            }
        }else{
            if (self.lastNotificaitonUpdate != 0){ // wait for the rest of the app to ahndle it.
                checkForNewNotifications()
            }
        }
        recalculateHiveRolodex()
    }
    
    @objc func handleDidEnterForeground() {
        handleMapIsAppearing()
    }
    
    
    func checkForNewNotifications() {
        if (NSDate().timeIntervalSince1970 - lastNotificaitonUpdate < 30){
            return
        }else{
            RequestManager().makeJsonRequest(urlString: "/Hive/api/checkForNewNotifications", params: nil) { (json, _) in
                guard let json = json as? [String: Any] else { return }
                if let notifcount = json["Notifications"] as? Int, notifcount > 0 {
                    self.handleNotificationIndicator(count: notifcount)
                } else {
                    self.handleNotificationIndicator(count: 0)
                }
            }
        }
    }
    
    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) { // update this funciton after we have the hives on the map. add camera hives when tapped to rolidex, see MapRender, and fix the algorithmn.
        if let _ = MainTabBarController.currentUser?.HID {
            return
        }else{
            let spot = sender.location(in: MapRender.mapView) // Will be identified by the HID, which is good.
            let features = MapRender.mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(mapLayers))
            if let feature = features.first, let key = feature.attribute(forKey: "key") as? String {
                let i = rolodexHives.firstIndex { (hd) -> Bool in
                    return hd.key == key
                }
                if let index = i {
                    self.hiveCollectionView.scrollToItem(at: IndexPath(item: index+1, section: 0), at: .centeredHorizontally, animated: true)
                    self.cellIndex = index // Check this.
                }else {
                    return
                }
            }else {
                let camerafeatures = MapRender.mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(cameraLayers))
                if let feature = camerafeatures.first, let key = feature.attribute(forKey: "key") as? String{
                    if (self.rolodexHives.count < 30){ // limits the number of hives that can be added to the roloded to 30, should be good enough.
                        self.removeCameraHive(key: key)
                    }
                    // Remove the layer and add it to the rolodex.
                    // avoid refecthing the hive and just use the data you have already grabbed
                }
            }
            
        }
        
    } // End handleMapTap
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleIndeces = hiveCollectionView.indexPathsForVisibleItems
        visibleIndeces.sort { (i1, i2) -> Bool in
            return i1.item < i2.item
        }
        if visibleIndeces.count == 3 {
            cellIndex = visibleIndeces[1].item-1
        } else if visibleIndeces.first?.item == 0 {
            cellIndex = visibleIndeces[0].item
        } else {
            guard let lastIndexItem = visibleIndeces.last?.item else { return }
            cellIndex = lastIndexItem-1
        }
        if scrollView.contentOffset.x == 0 && isPreviewShowing {
            self.closePreview()
        }
       
    } // End scrollViewDidEndDecelerating

    // KK this works nice and good.
    fileprivate func setCellIndex(oldValue: Int?, newValue: Int, added: Bool){
        if !added {
            cellIndex = newValue
        }else{
            if let oldValue = oldValue {
                if (oldValue < newValue){
                    cellIndex = newValue
                }else{ // newValue< oldValue and new value is an added element
                    cellIndex = newValue
                    let hd = self.rolodexHives[oldValue+1]
                    guard let layer = MapRender.mapView.style?.layer(withIdentifier:"\(hd.id)+HivePolygon") as? MGLFillStyleLayer else {return}
                    layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: newValue, outOf: self.rolodexHives.count))
                }
            }else{
                cellIndex = newValue
            }
        }
    }
    
    var cellIndex : Int? {
        didSet { // Put in guard statements instead of the bang operators.
            guard let index = cellIndex else {return}
            let hd = self.rolodexHives[index]
            guard let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") as? MGLFillStyleLayer else {return}
            layer.fillColor = NSExpression(forConstantValue: UIColor.blueHeatColor(rank: index, outOf: self.rolodexHives.count))
        }
        willSet {
            guard let index = cellIndex else {return}
            let hd = self.rolodexHives[index]
            guard let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") as? MGLFillStyleLayer else {return}
            layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: index, outOf: self.rolodexHives.count))
        }
    } // End cellIndex
    

    fileprivate func setupMapView() {
        MapRender.mapView.delegate = self
        MapRender.mapView.styleURL = URL(string: "mapbox://styles/hiveceo69/cjtrwl0dv05fh1gtdjtipdaky")
        MapRender.mapView.frame = view.bounds
        MapRender.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        MapRender.mapView.showsUserLocation = true
        MapRender.mapView.setUserTrackingMode(.follow, animated: true)

        view.addSubview(MapRender.mapView)
    }
    
    fileprivate func setupHiveCollectionView() {
        hiveCollectionView.delegate = self
        hiveCollectionView.dataSource = self
        hiveCollectionView.register(RolidexCell.self, forCellWithReuseIdentifier: cellId)
        hiveCollectionView.register(CreateHiveCell.self, forCellWithReuseIdentifier: createhivecellid)
        view.addSubview(hiveCollectionView)
        hiveCollectionView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 70)
        hiveCollectionViewBottomAnchor = hiveCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        hiveCollectionViewBottomAnchor.isActive = true
        
        let attributionButton = UIButton()
        hiveCollectionView.addSubview(attributionButton)
        attributionButton.anchor(top: nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 4, width: 20, height: 20)
        attributionButton.addTarget(self, action: #selector(handleAttribution), for: .touchUpInside)
    }
    
    @objc fileprivate func handleAttribution() {
        MapRender.mapView.attributionButton.sendActions(for: .touchUpInside)
    }
    
    fileprivate func setupNavBar() {
        navigationController?.makeTransparent()
        
        let profileButton = UIBarButtonItem(image: UIImage(named: "profile"), style: .plain, target: self, action: #selector(handleProfile))
        navigationItem.leftBarButtonItem = profileButton
        
        let customView: ButtonWithCount = {
            let button = ButtonWithCount(type: .system)
            button.paddingTop = -10
            button.setImage(UIImage(named: "friends")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.count = 0
            button.addTarget(self, action: #selector(handleSearch), for: .touchUpInside)
            return button
        }()
        
        let searchButton = UIBarButtonItem(customView: customView)
        
        let nearbyButton = UIBarButtonItem(image: UIImage(named: "eye")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleNearby))
        
        navigationItem.rightBarButtonItems = [searchButton, nearbyButton]
        navigationController?.navigationBar.tintColor = .black
        
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.mainRed(), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
    }
    
    static let profileCache = NSCache<NSString, ProfileMainController>()
    @objc func handleProfile() {
        
        let profileController: ProfileMainController
        
        if let cachedVersion = MapRender.profileCache.object(forKey: "CachedProfile") {
            profileController = cachedVersion
            profileController.isCached = true
        } else {
            profileController = ProfileMainController()
            MapRender.profileCache.setObject(profileController, forKey: "CachedProfile")
            
        }
        
        if let currentUser = MainTabBarController.currentUser {
            profileController.user = currentUser
        }
        
        let profileNavController = UINavigationController(rootViewController: profileController)
        self.tabBarController?.present(profileNavController, animated: true, completion: nil)
        
        self.endVideosInPreview()
        
    }
    
    @objc func handleSearch() {
        let button = navigationItem.rightBarButtonItem
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let searchNotificationsController = SearchNotificationsController(collectionViewLayout: layout)
        if let currentUser = MainTabBarController.currentUser {
            searchNotificationsController.user = currentUser
        }
        let searchNotificationsNavController = UINavigationController(rootViewController: searchNotificationsController)
        self.tabBarController?.present(searchNotificationsNavController, animated: true, completion: nil)
        self.endVideosInPreview()
        
        if let customView = button?.customView as? ButtonWithCount, let count = customView.count {
            let currentcount = UIApplication.shared.applicationIconBadgeNumber
            if (currentcount - count >= 0 ){
                UIApplication.shared.applicationIconBadgeNumber = currentcount - count
            }else{
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    @objc func handleNearby() {
        print("nearby")
        
        let nearbyController = NearbyController()
        let nearbyControllerNavController = UINavigationController(rootViewController: nearbyController)
        nearbyControllerNavController.modalPresentationStyle = .overFullScreen
        nearbyControllerNavController.modalPresentationCapturesStatusBarAppearance = true
        self.present(nearbyControllerNavController, animated: true, completion: nil)
    }
    
    var friendAnnotations : [Int:friendMGLAnnotation]?
    
    func mapView(_ mapView: MGLMapView, didFailToLocateUserWithError error: Error) {
        print("error", error)
        // Consider this possibility, make sure everything works with location turned off.
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
        print("error", error)
        // Make sure we can handle this area if this does occur.
    }
    
    var didEnterHiveOnLaunch = false
    var previousLocation : CLLocation?
    var madeFirstHiveFetch = false
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let currentLocation = userLocation?.coordinate, let currentUser = MainTabBarController.currentUser else {return}
        if let HID = currentUser.HID { // dont want to call on launch multiple times
            if !didEnterHiveOnLaunch {
                didEnterHiveOnLaunch = true
                self.enterHiveOnLaunch(HID: HID, location: currentLocation)
            }
            else {
                if let index = rolodexHives.firstIndex(where: { (hj) -> Bool in
                    hj.id == HID
                }) {
                    let hiveData = rolodexHives[index]
                    let center = hiveData.center
                    let distance = center.distance(from: CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude))
                    if distance + 100 >= hiveData.radius * 1000 {
                        self.handleexitHiveButton()
                    }else{
                        let currentTime = NSDate().timeIntervalSince1970
                        if let old = previousLocation, old.distance(from: CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)) > 100  {
                            self.updateLocationFriendsNotifications(location: currentLocation)
                            return
                        }else{
                            if (currentTime - self.lastFriendUpdate > 60*2 && self.lastFriendUpdate != 0) {
                                self.updateLocationFriendsNotifications(location: currentLocation)
                            }else{
                                return
                            }
                        }
                    }
                }
                return
            }
            // Call the enter hive functions, where we render the map and get shit going.
        }else {
            if let old = previousLocation {
                let currentCL = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                let distance = currentCL.distance(from: old)
                if distance > 100 {
                    previousLocation = currentCL
                    handleLocation(location: currentCL)
                }else{
                    return
                }
            }
            else {
                let currentCL = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                previousLocation = currentCL
                handleLocation(location: currentCL)
                
            }
        }
    }
    
    fileprivate func updateLocationFriendsNotifications(location : CLLocationCoordinate2D) {
        if (location.latitude == -180 || location.longitude == -180){
            checkForNewNotifications()
        }else{
            let params = ["latitude": location.latitude, "longitude": location.longitude, "lastFriendUpdate": self.lastFriendUpdate]
            RequestManager().makeJsonRequest(urlString: "/Hive/api/updateLocationFriendsNotifications", params: params) { (json, _) in
                guard let json = json as? [String: Any] else { return }
                
                if let friends = json["Friends"] as? [[String:Any]] {
                    self.lastFriendUpdate = NSDate().timeIntervalSince1970
                    self.handleRenderFriends(friends: friends)
                }
                
                if let notifications = json["Notifications"] as? Int, notifications > 0 {
                    self.handleNotificationIndicator(count: notifications)
                } else {
                    self.handleNotificationIndicator(count: 0)
                }
            }
        }
    }
    
    var lastFriendUpdate = 0.0
    fileprivate func handleLocation(location : CLLocation) {
        if location.coordinate.latitude == -180 || location.coordinate.latitude == -180 {
            return
        }else{
            let radius = 10.0 // km
            let params = ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude, "lastFriendUpdate": self.lastFriendUpdate] as [String : Any]
            RequestManager().makeJsonRequest(urlString: "/Hive/api/updateLocationFriendsHives", params: params) { (json, _) in
                guard let json = json as? [String: Any] else { return }
                if let hives = json["Hives"] as? [[String:Any]] {
                    if (!self.madeFirstHiveFetch) {
                        self.lastRadius = radius*1000
                        self.lastCenter = location
                        if hives.count < 15 {
                            self.doneLoadingHivesInArea = true
                        }
                    }
                    self.processRolodexHiveArray(hives: hives, location: location)
                }
                if self.lastFriendUpdate == 0.0 { // then this is the first fetch, so make the bloody heat map.
                    if let data = json["HeatMap"] as? [String:Any] {
                        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        if let heatData = jsonData {
                            self.handleHeatMap(data: heatData)
                        }
                    }
                }
                if let friends = json["Friends"] as? [[String:Any]] {
                    self.lastFriendUpdate = NSDate().timeIntervalSince1970
                    self.handleRenderFriends(friends: friends)
                }
                if let notifications = json["Notifications"] as? Int, notifications > 0 {
                    self.handleNotificationIndicator(count: notifications)
                } else {
                    self.handleNotificationIndicator(count: 0)
                }
            }
        }
    }
    
    fileprivate func processRolodexHiveArray(hives:[[String:Any]], location: CLLocation){
        var tempHiveJson : [HiveJson] = []
        var roloHives = self.rolodexHives
        hives.forEach({ (data) in
            guard let urlString = data["url"] as? String, let jsonUrl = URL(string: urlString) else {return}
            let j = HiveJson(json: data, userLocation: location, jsonUrl: jsonUrl)
            tempHiveJson.append(j)
            if let index = roloHives.firstIndex(where: { (hd) -> Bool in
                if (j.heat == hd.heat) {
                    return (j.distance > hd.distance)
                }else{
                    return (j.range*Double(Float(j.heat)) > hd.range*Double(Float(hd.heat)))
                }
            }){
                if (index >= 14) { // because starts at 0
                    return
                }else{
                    if roloHives.contains(where: { (hivedata) -> Bool in
                        return hivedata.id == j.id
                    }){
                        print("0 return")
                        return
                    }else{
                        print("here", index)
                        roloHives.insert(HiveData(json: j), at: index)
                    }
                }
            }else{
                if roloHives.contains(where: { (hivedata) -> Bool in
                    return hivedata.id == j.id
                }){
                    print("2 return")
                    return
                }else{
                    roloHives.append(HiveData(json: j))
                }
            }
        })
        // okay so at this point, roloHives is an array of the 15 greatest hives (i think) -- check sorting to make sure it works good (index if let)
        // Okay so lets get the hives on the map now.
        self.rolodexHives = roloHives
        renderRolodexHives(hives: roloHives)
    }
    
    // append roloded hive - just put your hive right on the array, try this in the handle map tap thing.
    
    fileprivate func addSource(source: MGLShapeSource, identifier: String){
        if let _ = MapRender.mapView.style?.source(withIdentifier: identifier){
            return
        }else{
             MapRender.mapView.style?.addSource(source)
        }
    }
    
    
    
    fileprivate func renderRolodexHives(hives: [HiveData]) {
        let count = hives.count
        var i = 0
        while (i < min(count, 15)){
            let hd = hives[i]
            if let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") as? MGLFillStyleLayer {
                DispatchQueue.main.async {
                    layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: i, outOf: count))
                }
            }else{
                let sourceid = "\(hd.id)+HiveSource"
                let source = MGLShapeSource(identifier: sourceid, url: hd.purl, options: nil)
                addSource(source: source, identifier: sourceid)
                
                
                
                let layerID = "\(hd.id)+HivePolygon"
                let layer = MGLFillStyleLayer(identifier: layerID, source: source)
                let namelayer = createNameLayer(hd: hd, source: source)
                self.mapLayers.append(layerID)
                layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: i, outOf: count))
                if let belowlayer = MapRender.mapView.style?.layer(withIdentifier: "country-label"), let statelayer = MapRender.mapView.style?.layer(withIdentifier: "state-label") {
                    DispatchQueue.main.async { // Consider hive entrance here.\
                        MapRender.mapView.style?.insertLayer(namelayer, above: belowlayer)
                        MapRender.mapView.style?.insertLayer(layer, below: statelayer)
                    }
                }else{
                    DispatchQueue.main.async { // Consider hive entrance here.\
                        MapRender.mapView.style?.addLayer(layer)
                        MapRender.mapView.style?.addLayer(namelayer)
                    }
                }
            }
            if (i == min(count, 15) - 1){
                self.hiveCollectionView.reloadData()
            }
            i+=1
        }
    }
    
    fileprivate func renderHive(hd: HiveData, scrollTo: Bool, enterHive: Bool, fromCamera: Bool){
        // need layer identifiers for map tap - when clicking on heat map, popup annotations for top posts.
        // Consider entering a hive on relaunch as well in here.
        if !fromCamera {
            if let _ = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") {
                return
            }else{
                
                
                let sourceid = "\(hd.id)+HiveSource"
                let source = MGLShapeSource(identifier: "\(hd.id)+HiveSource", url: hd.purl, options: nil)
                addSource(source: source, identifier: sourceid)
            
                let layerID = "\(hd.id)+HivePolygon"
                let layer = MGLFillStyleLayer(identifier: layerID, source: source)
                let namelayer = createNameLayer(hd: hd, source: source)
                self.mapLayers.append(layerID)
                if let index = self.rolodexHives.firstIndex(where: { (element) -> Bool in
                    if (hd.heat == element.heat) {
                        return (hd.distance > element.distance)
                    }else{
                        return (hd.range*Double(Float(hd.heat)) > element.range*Double(Float(element.heat)))
                    }
                }){
                    layer.fillColor = NSExpression(forConstantValue:UIColor.heatColor(rank: index, outOf: self.rolodexHives.count))
                }else{
                    layer.fillColor = NSExpression(forConstantValue:UIColor.heatColor(rank: self.rolodexHives.count - 1, outOf: self.rolodexHives.count))
                }
                if let belowlayer = MapRender.mapView.style?.layer(withIdentifier: "country-label"), let statelayer = MapRender.mapView.style?.layer(withIdentifier: "state-label") {
                    DispatchQueue.main.async { // Consider hive entrance here.\
                        MapRender.mapView.style?.insertLayer(namelayer, above: belowlayer)
                        MapRender.mapView.style?.insertLayer(layer, below: statelayer)
                        self.hiveCollectionView.reloadData()
                        guard let locationCL2D = MapRender.mapView.userLocation?.coordinate else {return}
                        let CL = CLLocation(latitude: locationCL2D.latitude, longitude: locationCL2D.longitude)
                        if enterHive && CL.distance(from: hd.center) <= hd.radius*1000 {
                            self.enterHive(hivedata: hd)
                        }else{
                            if enterHive {
                                self.exitHiveDatabase()
                                MainTabBarController.currentUser?.HID = nil
                                self.didEnterHiveOnLaunch = false
                            }
                        }
                    }
                }else {
                    DispatchQueue.main.async { // Consider hive entrance here.
                        MapRender.mapView.style?.addLayer(layer)
                        MapRender.mapView.style?.addLayer(namelayer)
                        self.hiveCollectionView.reloadData()
                        guard let locationCL2D = MapRender.mapView.userLocation?.coordinate else {return}
                        let CL = CLLocation(latitude: locationCL2D.latitude, longitude: locationCL2D.longitude)
                        // Only potential issue is if the location data is wildly innacurate, but this is on lauch, so say long periuods where uwse dont turn on phone, now we should get things being checked from the location update, to kick people out of hives etc
                        if enterHive && CL.distance(from: hd.center) <= hd.radius*1000 + 100 { // plus 100 meters to be safe?
                            print("can enter the hive brah")
                            self.enterHive(hivedata: hd)
                        }else{
                            if enterHive {
                                self.exitHiveDatabase()
                                //                            self.updateHiveRolodex(center: CL)
                                // Already built in to exitHiveDatabase()
                                MainTabBarController.currentUser?.HID = nil
                                self.didEnterHiveOnLaunch = false
                            }
                        }
                    }
                }
                if scrollTo {
                    if let index = self.rolodexHives.firstIndex( where: { (h) -> Bool in
                        return h.id == hd.id}) {
                        DispatchQueue.main.async {
                            self.hiveCollectionView.scrollToItem(at: IndexPath(item: index+1, section: 0), at: .centeredHorizontally, animated: true)
                            self.setCellIndex(oldValue: self.cellIndex, newValue: index, added: true)
                        }
                    }
                }
            }
            
        }else{
            let layerID = "\(hd.id)+HivePolygon"
            self.mapLayers.append(layerID)
            
            DispatchQueue.main.async { // Consider hive entrance here.\
                
                self.hiveCollectionView.reloadData()
                guard let locationCL2D = MapRender.mapView.userLocation?.coordinate else {return}
                let CL = CLLocation(latitude: locationCL2D.latitude, longitude: locationCL2D.longitude)
                if enterHive && CL.distance(from: hd.center) <= hd.radius*1000 {
                    print("can enter the hive brah")
                    self.enterHive(hivedata: hd)
                }else{
                    if enterHive {
                        self.exitHiveDatabase()
                        //                        self.updateHiveRolodex(center: CL)
                        MainTabBarController.currentUser?.HID = nil
                        self.didEnterHiveOnLaunch = false
                    }
                }
            }
            if scrollTo {
                if let index = self.rolodexHives.firstIndex( where: { (h) -> Bool in
                    return h.id == hd.id}) {
                    DispatchQueue.main.async {
                        self.hiveCollectionView.scrollToItem(at: IndexPath(item: index+1, section: 0), at: .centeredHorizontally, animated: true)
                        self.setCellIndex(oldValue: self.cellIndex, newValue: index, added: true)
                    }
                }
            }
        }
        
    }
    
    func appendRolodexHive(data: HiveJson, scrollTo: Bool, enterHive: Bool, fromCamera: Bool) {
        let hd = HiveData(json: data)
        if let index = self.rolodexHives.firstIndex(where: { (element) -> Bool in
            return (element.distance > hd.distance)
        }){
            self.rolodexHives.insert(hd, at: index)
        }else{
            self.rolodexHives.append(hd)
        }
        self.renderHive(hd: hd, scrollTo: scrollTo, enterHive: enterHive, fromCamera: fromCamera)
    }
    
    fileprivate func handleRenderFriends(friends: [[String:Any]]) {
        // Just for future reference if this ever breaks, the name of the game here is to take care of optional shit and make sure everything appears as usual.
        var friendsonmap = [Int:friendMGLAnnotation]()
        var newfriends = [friendMGLAnnotation]()
        var removefriends = [friendMGLAnnotation]()
        if let x = self.friendAnnotations {
            friendsonmap = x
        }
        friends.forEach({ (snapshot) in
            if let id = snapshot["id"] as? Int, let latitude = snapshot["latitude"] as? Double, let longitude =  snapshot["longitude"] as? Double{
                let keys = friendsonmap.keys
                if (keys.contains(id)){
                    guard let oldannotation = friendsonmap[id] else {return}
                    removefriends.append(oldannotation)
                    friendsonmap.removeValue(forKey: id)
                }
                if (latitude != -180 && longitude != -180){
                    guard let username = snapshot["username"] as? String else {return}
//                    guard let url = snapshot["profileImageUrl"] as? String else {return}// End of else for image caching.
                    
                    let url = snapshot["profileImageUrl"] as? String ?? MainTabBarController.defualtProfileImageUrl
                    guard let unreadMessage = snapshot["unreadMessage"] as? Bool else {return}
                    let hiveName = snapshot["hiveName"] as? String ?? nil
                    guard let profileImageUrl = URL(string: url) else {return}
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let annotation = friendMGLAnnotation(coordinate: coordinate, username: username, profileImageUrl: profileImageUrl, FUID: id, hiveName: hiveName, unreadMessage: unreadMessage)
                    newfriends.append(annotation)
                    friendsonmap[id] = annotation
                }
            }
        })
        self.friendAnnotations = friendsonmap
        DispatchQueue.main.async {
            MapRender.mapView.removeAnnotations(removefriends)
            MapRender.mapView.addAnnotations(newfriends)
        }
    }
    
    // if the user is in a hive, get the hive on lauch so we do not have to immidiately do this, maybe with a delegate method, talk to carter about it.
    // make sure this enterhiveonlaunch thing is not used, as it is a garbage function.
    fileprivate func enterHiveOnLaunch(HID: Int, location: CLLocationCoordinate2D){ // should this protect against the dark arts?
        if (location.latitude == -180 || location.longitude == -180){
            checkForNewNotifications()
        }else{
            if let header = UserDefaults.standard.getAuthorizationHeader(), let url = URL(string: MainTabBarController.serverurl + "/Hive/api/enterHiveOnLaunch") {
                let Clocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                //                let radius = 10.0 // km
                let params = ["latitude": location.latitude, "longitude": location.longitude, "lastFriendUpdate": self.lastFriendUpdate, "HID": HID] as [String : Any]
                Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: header).responseJSON { (data) in
                    if let json = data.result.value as? [String:Any] {
                        print(json)
                        print("no dead json at least")
                        if let hives = json["Hives"] as? [[String:Any]]{
                            if let index = hives.firstIndex(where: { (element) -> Bool in
                                guard let hiveId = element["id"] as? Int else {return false}
                                return hiveId == HID
                            }), let urlString = hives[index]["url"] as? String, let jsonUrl = URL(string: urlString){
                                
                                let j = HiveJson(json: hives[index], userLocation: Clocation, jsonUrl: jsonUrl)
                                self.appendRolodexHive(data: j, scrollTo: false, enterHive: true, fromCamera: false)
                            }else{
                                self.didEnterHiveOnLaunch = false
                                self.handleexitHiveButton()
                                // This should take care of the issue.
                                self.processRolodexHiveArray(hives: hives, location: Clocation)
                            }
                        }else{
                            print("make sure that this works in case of failure")
                            self.didEnterHiveOnLaunch = false
                            self.handleexitHiveButton()
                        }
                        if self.lastFriendUpdate == 0.0 { // then this is the first fetch, so make the bloody heat map.
                            if let data = json["HeatMap"] as? [String:Any] {
                                print("got in here")
                                let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                                if let heatData = jsonData {
                                    print("JSON data worked as well - albeit in wrong order and shit, which we are fixing now.")
                                    self.handleHeatMap(data: heatData)
                                }
                            }
                        }
                        if let friends = json["Friends"] as? [[String:Any]] {
                            self.lastFriendUpdate = NSDate().timeIntervalSince1970
                            self.handleRenderFriends(friends: friends)
                        }
                        
                        if let notifications = json["Notifications"] as? Int, notifications > 0 {
                            self.handleNotificationIndicator(count: notifications)
                        } else {
                            self.handleNotificationIndicator(count: 0)
                        }
                        // figure out how to get the heat map data in here as well.
                        // When it is used
                    }
                    else{
                        print("dead json on the enter hive")
                        MainTabBarController.currentUser?.HID = nil
                        self.handleLocation(location: CLLocation(latitude: location.latitude, longitude: location.longitude))
                    }
                }
            }
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
      // Done loading, can start up the location queue probably, or somethign along those lines.
        
    }

    
    static var regionWillChangeViaRelocate = false
    
    
    static func toCurrentLocation() {
        MapRender.regionWillChangeViaRelocate = true
        if MapRender.currentHiveInfo.count == 0, let location = MapRender.mapView.userLocation?.coordinate { // ie: if the user is not in a hive.
            // will have to animate this probably.
            if (location.latitude == -180 && location.longitude == -180){
                return
            }else{
                MapRender.mapView.setCenter(location, zoomLevel: 14, direction: 0, animated: true) {
                    let camera = MapRender.mapView.camera
                    camera.pitch = 0
                    MapRender.mapView.setCamera(camera, animated: true)
                }
            }
        }
        else{
            guard let center = MapRender.currentHiveInfo[0] as? [Double], let radius = MapRender.currentHiveInfo[1] as? Double else {print("no coordinates");return}
//            let camera = MGLMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: center[0], longitude: center[1]), fromDistance: 2*2*radius*1000, pitch: 30, heading: 0)
            let camera = MGLMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: center[0], longitude: center[1]), altitude: 2*2*radius*1000, pitch: 30, heading: 0)
            print("have camera")
            DispatchQueue.main.async {
                MapRender.mapView.setCamera(camera, withDuration: 0.3, animationTimingFunction: CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut))
            }
        }
    }
    
    
    var regionDidChangeReason = 0
    // 0 - do nothin, 1 - panning around, so do something depending on if in hive, 2 - changed due to relocation button, so load the heatmap
    func mapView(_ mapView: MGLMapView, regionWillChangeWith reason: MGLCameraChangeReason, animated: Bool) { // get carter to make icon.
        if (reason.rawValue == 0){
            self.regionDidChangeReason = 0
        }
        if (reason == MGLCameraChangeReason.gesturePan) {
            self.regionDidChangeReason = 1
        }
        if (reason == MGLCameraChangeReason.programmatic) {
            guard let button = self.tabBarController?.viewControllers?[0].tabBarItem else {print("nothing");return}
            button.selectedImage = UIImage(named: "map")!
            if (MapRender.regionWillChangeViaRelocate) {
                self.regionDidChangeReason = 2
                MapRender.regionWillChangeViaRelocate = false // reset the flag
            }else{ // so this is on the .follow
                self.regionDidChangeReason = 0
            }
        }else{
            guard let button = self.tabBarController?.viewControllers?[0].tabBarItem else {print("nothing");return}
            button.selectedImage = UIImage(named: "relocate")!
            
        }
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        // This is where the camera hives should be updated, if the distance is significant.
        if (self.regionDidChangeReason == 0){
            // do nothing in this case
            return
        }
        if (self.regionDidChangeReason == 1){
            if let _ = MainTabBarController.currentUser?.HID { // user is in a hive
                return
                // Do just the heat map + friends + notifications.
            }
            else{
                if MapRender.mapView.zoomLevel > 8 {
                    // load camera hives in the region,
                    loadCameraHives()
                }else{
                    loadHeatMapFar()
                    // Could consider gettiing a heat map for very far zooms, just need to get a good distribution of most recent posts, which would show the most active areas, but we will handle this shit later.
                }
            }
        }
        if (self.regionDidChangeReason == 2) {
                reloadCurrentLocationHeat()
            // do the heatmap (+friends + notificaitons)
            // Maybe we can put a date in the database so that we only grab friends who have recently updated their location, as that seems like a pretty chill method and keeps things generally up to date
        }
        
        
        // Just have to get this to wait for the new hives.
    }
    
    // How should we do this, okay, so what we want is the following, lets get this shit working, then some other shit working, then this shit working again.
    // Hmmm what the hell eh
    // Because we want to get some of the stuff going pretty good fuck
    // also deal with the ability to reload and retry requests,
    // Make sure the map works on movement, kicking you out of hives and shit,
    // ideally calm down all the requests off of launch of the map.
    // something else I just forgot.
    // notifiucations, make them look cool
    // maybe some kind of touch functionality from the home screen like tinder
    // how to deal with chat.
    fileprivate func reloadCurrentLocationHeat(){
        guard let location = MapRender.mapView.userLocation?.coordinate else { return }
        if (location.latitude == -180 || location.longitude == -180){
            return
        }else{
            let params = ["latitude": location.latitude, "longitude": location.longitude, "lastFriendUpdate": self.lastFriendUpdate] as [String :Any]
            RequestManager().makeJsonRequest(urlString: "/Hive/api/returnToCurrentLocation", params: params) { (json, _) in
                guard let json = json as? [String: Any] else { return }
                self.lastRadius = 10*1000
                self.lastCenter = CLLocation(latitude: location.latitude, longitude: location.longitude)
                if let data = json["HeatMap"] as? [String:Any] {
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    if let heatData = jsonData {
                        self.handleHeatMap(data: heatData)
                    }
                }
                if let friends = json["Friends"] as? [[String:Any]] {
                    self.lastFriendUpdate = NSDate().timeIntervalSince1970
                    self.handleRenderFriends(friends: friends)
                }
                if let notifications = json["Notifications"] as? Int, notifications > 0 {
                    self.handleNotificationIndicator(count: notifications)
                } else {
                    self.handleNotificationIndicator(count: 0)
                }
            }
        }
    }
    
    var LargeNorthEast : CLLocationCoordinate2D?
    var LargeSouthWest : CLLocationCoordinate2D?
    fileprivate func loadHeatMapFar(){
        let NE = MapRender.mapView.visibleCoordinateBounds.ne
        let SW = MapRender.mapView.visibleCoordinateBounds.sw
        let maxlat = NE.latitude
        let minlat = SW.latitude
        let maxlon = NE.longitude
        let minlon = SW.longitude
        let params = ["maxlat": maxlat, "minlat": minlat, "maxlon": maxlon, "minlon": minlon, "lastFriendUpdate": self.lastFriendUpdate]
        
        if let oldNE = self.LargeNorthEast, let oldSW = self.LargeSouthWest, oldSW.longitude < minlon && oldSW.latitude < minlat &&  oldNE.longitude > maxlon && oldNE.latitude > maxlat  {
            return
        }else{
            self.LargeSouthWest = SW
            self.LargeNorthEast = NE
            
            RequestManager().makeJsonRequest(urlString: "/Hive/api/largeHeatMapFriends", params: params) { (json, _) in
                guard let json = json as? [String: Any] else { return }
                
                if let friends = json["Friends"] as? [[String:Any]] {
                    self.lastFriendUpdate = NSDate().timeIntervalSince1970
                    self.handleRenderFriends(friends: friends)
                }
                if let heat = json["HeatMap"] as? [String:Any] {
                    let jsonData = try? JSONSerialization.data(withJSONObject: heat, options: .prettyPrinted)
                    if let heatData = jsonData {
                        self.handleHeatMap(data: heatData)
                    }
                }
            }
            
        }
        
    }

    var lastCenter : CLLocation?
    var lastRadius: Double?
    var doneLoadingHivesInArea = false
    var cameraJSONS = [HiveJson]()
    // copy this above shit.
    fileprivate func loadCameraHives(){
        let NE = MapRender.mapView.visibleCoordinateBounds.ne
        let SW = MapRender.mapView.visibleCoordinateBounds.sw
        let center = MapRender.mapView.centerCoordinate
        let distance = CLLocation(latitude: NE.latitude, longitude: NE.longitude).distance(from: CLLocation(latitude: SW.latitude, longitude: SW.longitude))/2
        let params = ["lastFriendUpdate": self.lastFriendUpdate, "distance": distance, "centerLongitude": center.longitude, "centerLatitude" : center.latitude]
        
        if let oldcenter = self.lastCenter, let oldradius = self.lastRadius {
            // fix this not working currently.
            let difference = oldcenter.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
            if (distance + difference <= oldradius){
                if (doneLoadingHivesInArea){
                    return
                }else{
                    fetchCameraHives(params: params)
                }
            }else{
                self.lastCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
                self.lastRadius = distance
                self.doneLoadingHivesInArea = false // because we have a new area.
                fetchCameraHives(params: params)
            }
        }else{
            self.lastCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
            self.lastRadius = distance
            self.doneLoadingHivesInArea = false
            fetchCameraHives(params: params)
        }
    }
    
    fileprivate func handleCameraHives(json: [[String:Any]]) {
        json.forEach({ (snapshot) in
            guard let id = snapshot["id"] as? Int else {return}
            if !self.mapLayers.contains("\(id)+HivePolygon") && !self.cameraLayers.contains("\(id)+HivePolygon") { // so it isn't on the map.
                guard let urlString = snapshot["url"] as? String, let url = URL(string: urlString), let name = snapshot["name"] as? String, let radius = snapshot["radius"] as? Double, let latitude = snapshot["latitude"] as? Double, let _ = snapshot["population"] as? Double, let _ = snapshot["postcount"] as? Double,let key = snapshot["identifier"] as? String else {return}
                //\(hd.id)+HiveSource
                let sourceid = "\(id)+HiveSource"
                let source = MGLShapeSource(identifier:sourceid , url: url, options: nil)
                addSource(source: source, identifier: sourceid)
                
                let namelayer = self.createCameraNameLayer(name: name, radius: radius, latitude: latitude, id: id, source: source) //identifier: "\(id)+CameraNameLayer"
                let layer = MGLFillStyleLayer(identifier: "\(id)+HivePolygon", source: source)
                // This is the problem.
                let location = MapRender.mapView.userLocation?.location // This is
                let cameraJson = HiveJson(json: snapshot, userLocation: location, jsonUrl: url)
                self.cameraJSONS.append(cameraJson)
                if let index = self.rolodexHives.firstIndex(where: { (hd) -> Bool in
                    if (cameraJson.heat == hd.heat) {
                        return (cameraJson.distance > hd.distance)
                    }else{
                        return (cameraJson.range*Double(Float(cameraJson.heat)) > hd.range*Double(Float(hd.heat)))
                    }
                }){
                    layer.fillColor = NSExpression(forConstantValue:UIColor.heatColor(rank: index, outOf: self.rolodexHives.count))
                }else{
                    layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: self.rolodexHives.count-1, outOf: self.rolodexHives.count))
                }
//                DispatchQueue.main.async {
//                    self.cameraKeys[key.replacingOccurrences(of: ".geojson", with: "")] = id
//                    self.cameraLayers.append("\(id)+HivePolygon")
//                    MapRender.mapView.style?.addLayer(layer)
//                    MapRender.mapView.style?.addLayer(nameLayer)
//                }
//
                if let belowlayer = MapRender.mapView.style?.layer(withIdentifier: "country-label"), let statelayer = MapRender.mapView.style?.layer(withIdentifier: "state-label") {
                    DispatchQueue.main.async { // Consider hive entrance here.\
                        self.cameraKeys[key.replacingOccurrences(of: ".geojson", with: "")] = id
                        self.cameraLayers.append("\(id)+HivePolygon")
                        MapRender.mapView.style?.insertLayer(namelayer, above: belowlayer)
                        MapRender.mapView.style?.insertLayer(layer, below: statelayer)
                    }
                }else{
                    DispatchQueue.main.async { // Consider hive entrance here.\
                        self.cameraKeys[key.replacingOccurrences(of: ".geojson", with: "")] = id
                        self.cameraLayers.append("\(id)+HivePolygon")
                        MapRender.mapView.style?.addLayer(layer)
                        MapRender.mapView.style?.addLayer(namelayer)
                    }
                }
                
                
                
                
            }
        })
    }
    
    fileprivate func fetchCameraHives(params: [String: Any]) {
        RequestManager().makeJsonRequest(urlString: "/Hive/api/loadCameraHeatNotificationsFriends", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let hives = json["Hives"] as? [[String:Any]]{
                if hives.count < 7 {
                    self.doneLoadingHivesInArea = true
                }else{
                    self.doneLoadingHivesInArea = false
                }
                self.handleCameraHives(json: hives)
            }
            if let friends = json["Friends"] as? [[String:Any]] {
                self.lastFriendUpdate = NSDate().timeIntervalSince1970
                self.handleRenderFriends(friends: friends)
            }
            if let notifications = json["Notifications"] as? Int, notifications > 0 {
                self.handleNotificationIndicator(count: notifications)
            } else {
                self.handleNotificationIndicator(count: 0)
            }
            if let data = json["HeatMap"] as? [String:Any] {
                let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                if let heatData = jsonData {
                    self.handleHeatMap(data: heatData)
                }
            }
        }
    }
    
    var cameraLayers : [String] = []
    var cameraKeys = [String:Int]()
    fileprivate func removeCameraHive(key: String) {
        if let index = cameraJSONS.firstIndex(where: { (hj) -> Bool in
            return hj.key.replacingOccurrences(of: ".geojson", with: "") == key
        }){
            self.appendRolodexHive(data: cameraJSONS[index], scrollTo: true, enterHive: false, fromCamera: true)
        }else{
            print("nothing matched in terms of keys in the cameraJSONS")
        }
    }
    
    fileprivate func handleHeatMap(data: Data){
        if let globalHeatSource = MapRender.mapView.style?.source(withIdentifier: "GlobalHeatMapSource") as? MGLShapeSource {
            let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
            globalHeatSource.shape = shape
        }else{
            let shape = try? MGLShape(data: data, encoding: String.Encoding.utf8.rawValue)
            
            
            let sourceid = "GlobalHeatMapSource"
            let source = MGLShapeSource(identifier: sourceid, shape: shape, options: nil)
            addSource(source: source, identifier: sourceid)
            let layer = MGLHeatmapStyleLayer(identifier: "GlobalHeatMapLayer", source: source)
            //            let colorDictionary: [NSNumber: UIColor] = [
            //                0.0: UIColor.clear,
            //                0.5: UIColor.rgb(red: 255, green: 0, blue: 25),
            //                0.6:  UIColor.rgb(red: 218, green: 162, blue: 34),
            //                0.7: UIColor.rgb(red: 205, green: 218, blue: 34),
            //                0.8: UIColor.rgb(red: 34, green: 218, blue: 181),
            //                0.9: UIColor.rgb(red: 100, green: 32, blue: 238),
            //                1: UIColor.rgb(red: 255, green: 255, blue: 255)
            //            ]
            
            let colorDictionary: [NSNumber: UIColor] = [
                0.0: UIColor.clear,
                //                0.2: UIColor.rgb(red: 255, green: 255, blue: 255),
                //                0.2: UIColor.rgb(red: 255, green: 0, blue: 0),
                0.1: UIColor.rgb(red: 255, green: 45, blue: 85),
                //                0.15: UIColor.rgb(red: 255, green: 20, blue: 240),
                //                0.6: UIColor.rgb(red: 51, green: 51, blue: 255),
                0.55: UIColor.mainBlue(), // purple
                //                0.9: UIColor.rgb(red: 100, green: 32, blue: 238),
                //                0.25: UIColor.mainBlue(),
                1: UIColor.rgb(red: 255, green: 255, blue: 255),
            ]
            
            //          layer.heatmapWeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [10: 0.01,12: 0.1])
            layer.heatmapWeight = NSExpression(forConstantValue: 0.1)
            layer.heatmapColor = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($heatmapDensity, 'linear', nil, %@)", colorDictionary)
            layer.heatmapIntensity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [0: 1,9: 0.5, 13: 1, 16: 0.8])
            layer.heatmapRadius = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",[0:1, 9:2, 12:4, 16.5:15, 15:20, 18: 15])
            layer.heatmapOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",[0: 0, 1:0.1, 12: 1,17.9:1 ,18: 0])
            
            if let statelayer = MapRender.mapView.style?.layer(withIdentifier: "state-label") {
                DispatchQueue.main.async {
                    MapRender.mapView.style?.insertLayer(layer, above: statelayer)
                }
            }else{
                DispatchQueue.main.async {
                    MapRender.mapView.style?.addLayer(layer)
                }
            }
        }
    }
    
    fileprivate func createCameraNameLayer(name:String,radius: Double, latitude: Double, id: Int,source: MGLShapeSource) -> MGLSymbolStyleLayer {
        let namelayer = MGLSymbolStyleLayer(identifier: "\(id)+NameLayer", source: source)
        namelayer.text = NSExpression(forConstantValue: name)
        var charactercount: Double
        if name.count <= 4 {
            charactercount = Double(9)
        }
        else {
            charactercount = Double(name.count)
        }
        let phi = (3.6*radius)/(cos(latitude*Double.pi/180)*111.6752141*charactercount)
        let fontsizestops = [0:0, 1 : 0, 4 : 0, 5:0, 6:0, 7:0, 8: 0, 9: 0, 10: 1024*phi, 11 : 2048*phi, 12: 4096*phi, 13: 8192*phi, 14 : 16384*phi, 15: 32768*phi, 16 : 0]
        print("ALEX PRE-COMPUTE THESE POWERS")
        namelayer.textFontSize = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", fontsizestops)
        namelayer.textFontNames = NSExpression(forConstantValue: ["Rubik Medium","Open Sans Regular"])
        //if enterHiveHID != nil {
        //namelayer.isVisible = false
        //}
        return namelayer
    }

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if (annotation is friendMGLAnnotation), let fannotation = annotation as? friendMGLAnnotation{ // friends
            let identifier = fannotation.reuseIdentifier ?? "friendannotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = CustomFriendAnnotationView(postannotation: fannotation, reuseIdentifier: identifier)
            }
            return annotationView
        }else if (annotation is MGLUserLocation && MapRender.mapView.userLocation != nil){ // User annotation
            var userlocation = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation")
            if userlocation == nil {
                userlocation = CustomUserAnnotationView()
                userlocation?.centerOffset = CGVector(dx: 0, dy: 0)
            }
            return userlocation
        }else{
           if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") {
                return annotationView
            } else {
                return DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 50)
            }
            
        }
        
    } // End ViewFor Annotation
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        if (annotation is MGLUserLocation && MapRender.mapView.userLocation != nil) || (annotation is friendMGLAnnotation) || (annotation is MGLPointAnnotation){
            return true
        }else{
            return false
        }
        
    }

    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        if (annotation is MGLUserLocation && MapRender.mapView.userLocation != nil) || (annotation is friendMGLAnnotation) {

            let callout = UserCalloutView(annotation: annotation)
            
            if annotation is friendMGLAnnotation {
                callout.calloutDelegate = self
            }
            
            return callout
            
        }else{
            return CreateHiveCalloutView(annotation: annotation)
        }
    }

    fileprivate func recalculateHiveRolodex(){
        print("recalculating the thign")
        print(MapRender.mapView.locationManager.authorizationStatus.rawValue, "the raw value is:")
        
        // The problem is when there is no fuckin location just yet, that mekes sence.
        
        if (MapRender.mapView.locationManager.authorizationStatus.rawValue != 2){
            if let cell = hiveCollectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? CreateHiveCell {
                cell.enableCreateHiveButton()
            }
            if let location = MapRender.mapView.userLocation?.location, (location.coordinate.latitude != -180 && location.coordinate.longitude != -180) {
                let count = self.rolodexHives.count
                var i = 0
                while i < count {
                    let distance = self.rolodexHives[i].center.distance(from: location)
                    self.rolodexHives[i].distance = distance
                    self.rolodexHives[i].inHiveRange = (self.rolodexHives[i].radius*1000 >= distance)
                    i += 1
                }
                // sort them as well
                self.rolodexHives.sort { (hj1, hj2) -> Bool in
                    let r1 = hj1.range; let r2 = hj2.range; let h1 = hj1.heat; let h2 = hj2.heat; let d1 = hj2.distance; let d2 = hj2.distance
                    if (h1 == h2){
                        return (d1 < d2)
                    }else{
                        return (r1*Double(Float(h1)) > r2*Double(Float(h2)))
                    }
                }
            }
        }else{
            
            if let cell = hiveCollectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? CreateHiveCell {
                cell.disableCreateHiveButton()
            }
            var i = 0
            let count = self.rolodexHives.count
            while i < count{
                self.rolodexHives[i].distance = 0
                self.rolodexHives[i].inHiveRange = false
                i+=1
            }
        }
        self.hiveCollectionView.reloadData()
    }
    
    
    fileprivate func createNameLayer(hd: HiveData,source: MGLShapeSource) -> MGLSymbolStyleLayer {
        let namelayer = MGLSymbolStyleLayer(identifier: "\(hd.id)+NameLayer", source: source)
        namelayer.text = NSExpression(forConstantValue: hd.name)
        var charactercount: Double
        if hd.name.count <= 4 {
            charactercount = Double(9)
        }
        else {
            charactercount = Double(hd.name.count)
        }
        // 3.6 was the multiplier before
        let phi = (3.4*hd.radius)/(cos(hd.center.coordinate.latitude*Double.pi/180)*111.6752141*charactercount)
        let fontsizestops = [0:0, 1 : 0, 4 : 0, 5:0, 6:0, 7:0, 8: 0, 9: 0, 10: pow(2, 10)*phi, 11 : pow(2, 11)*phi, 12: pow(2, 12)*phi, 13: pow(2, 13)*phi, 14 : pow(2, 14)*phi, 15: pow(2, 15)*phi, 16 : 0]
        print("ALEX : PRE-COMPUTE THESE POWERS.")
        namelayer.textFontSize = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", fontsizestops)
        namelayer.textFontNames = NSExpression(forConstantValue: ["Rubik Medium","Open Sans Regular"])
        let opacitystops = [0 : 1.0, 14:1.0, 14.5 :0.0]
        namelayer.textOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", opacitystops)
        //        if enterHiveHID != nil {
        //            namelayer.isVisible = false
        //        }
        return namelayer
    }


    func enterHive(hivedata: HiveData) {
        if self.isPreviewShowing {
            self.closePreview()
        }
        if let location = MapRender.mapView.userLocation?.coordinate, (location.latitude != -180 && location.longitude != -180 && (MapRender.mapView.locationManager.authorizationStatus.rawValue != 2)){
            let distance = hivedata.center.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
            if (distance < hivedata.radius*1000 ){ // we are in range, so enter the hive.
                let hidDict: [String: Int] = ["HID": hivedata.id]
                NotificationCenter.default.post(name: MapRender.didEnterHiveNotificationName, object: nil, userInfo: hidDict)
                MapRender.currentHiveInfo = [[hivedata.center.coordinate.latitude, hivedata.center.coordinate.longitude],hivedata.radius]
                enterHiveColorationEffect(hd: hivedata)
                enterHiveClearMap(hivedata: hivedata)
                self.hiveCollectionViewBottomAnchor.constant = 90 + UIApplication.shared.statusBarFrame.height
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: { (_) in
                        self.hiveCollectionView.isHidden = true
                        self.enterHiveExitButtonMembersView(data: hivedata)
                    })
                }
                enterHiveDatabase(hd: hivedata)
                enterHiveCameraSet(hd: hivedata)
                self.navigationItem.title = hivedata.name //Make sure this shows
            }else{
                recalculateHiveRolodex()
                return
            }
        }else{
            recalculateHiveRolodex()
            return
        }
    }
    
    fileprivate func enterHiveDatabase(hd: HiveData) {
        self.didEnterHiveOnLaunch = true
        if let serverhid = MainTabBarController.currentUser?.HID, serverhid == hd.id {
            MainTabBarController.currentUser?.hiveName = hd.name
            return
        }else{
            MainTabBarController.currentUser?.HID = hd.id
            MainTabBarController.currentUser?.hiveName = hd.name
            let params = ["HID": hd.id]
            RequestManager().makeResponseRequest(urlString: "/Hive/api/joinHive", params: params) { (response) in
                if response.response?.statusCode == 200 {
                    print("joined hive")
                } else {
                    print("Failed to join hive")
                }
            }
        }
    }
    
    fileprivate func enterHiveExitButtonMembersView(data: HiveData) { //data is not used here???
        let exitHiveButton : UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Leave", for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            button.backgroundColor = .white
            button.layer.cornerRadius = 15
            button.setShadow(offset: CGSize(width: 0, height: 2), opacity: 0.3, radius: 3, color: UIColor.black)
            button.setTitleColor(.mainRed(), for: .normal)
            button.addTarget(self, action: #selector(handleexitHiveButton), for: .touchUpInside)
            return button
        }()
    
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let memberView = HiveMemberView(frame: .zero, collectionViewLayout: layout)
        memberView.hid = data.id
        memberView.tag = 97
        memberView.memberDelegate = self
        if let currentUser = MainTabBarController.currentUser {
            memberView.users.append(currentUser)
            memberView.uids.append(currentUser.uid)
        }
        self.view.addSubview(memberView)
        memberView.anchor(top: nil, left: self.view.leftAnchor, bottom: self.view.safeAreaLayoutGuide.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 70)//slighly taller to allow for shadows
        
        self.view.addSubview(exitHiveButton)
        exitHiveButton.tag = 96
        exitHiveButton.isHidden = false
        exitHiveButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: UIScreen.main.bounds.width / 3, height: 30)
        exitHiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        exitHiveButton.isEnabled = true

    }
    
    fileprivate func removeHiveUI() {
        if let button = self.view.viewWithTag(96) as? UIButton{
            button.isHidden = true
            button.isEnabled = false
            button.removeFromSuperview()
        }
        if let memberView = self.view.viewWithTag(97) {
            memberView.isHidden = true 
            memberView.removeFromSuperview()
        }
        
    }
    
    fileprivate func enterHiveColorationEffect(hd: HiveData){
        guard let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") as? MGLFillStyleLayer else {return}
        layer.fillColor = NSExpression(forConstantValue: UIColor(red: 1, green: 0, blue: 0, alpha: 0.2))
    }
   fileprivate func enterHiveClearMap(hivedata:HiveData) {
        for hive in self.rolodexHives{
            if hive.id == hivedata.id{
                
                guard let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hive.id)+HivePolygon") else {print("unable to change layer visibility");return}
                // Could maybe use a dispatch queue main async in here.
                guard let namelayer = MapRender.mapView.style?.layer(withIdentifier: "\(hive.id)+NameLayer") else {print("unabletohide name layer");return}
                DispatchQueue.main.async {
                    layer.isVisible = true
                    namelayer.isVisible = false
                }
            }
            else{
                guard let layer = MapRender.mapView.style?.layer(withIdentifier:"\(hive.id)+HivePolygon") else {print("unable to remove layer");return}
                // Could maybe use a dispatch queue main async in here.
                guard let namelayer = MapRender.mapView.style?.layer(withIdentifier: "\(hive.id)+NameLayer") else {print("unable to remove layer");return}
                DispatchQueue.main.async {
                    layer.isVisible = false
                    namelayer.isVisible = false
                }
            }
        }
    }
    
    func enterHiveCameraSet(hd: HiveData) { // Display top posts in the completing block here.
        // MapRender.CurrentHiveInfo = [hd.center,hd.radius] -- Not sure what thi is for, but it is of the form static var = [Any] -- [center, radius]
        MapRender.mapView.userTrackingMode = .none
        let center = CLLocationCoordinate2D(latitude: hd.center.coordinate.latitude, longitude: hd.center.coordinate.longitude)
//        let camera = MGLMapCamera(lookingAtCenter: center, fromDistance: 4000*hd.radius, pitch: 30, heading: 0)
        //        let camera = MGLMapCamera(lookingAtCenter: center, altitude: 2*2*hd.radius*1000, pitch: 30, heading: 0)
        let camera = MGLMapCamera(lookingAtCenter: center, altitude: 4000*hd.radius, pitch: 30, heading: 0)
        DispatchQueue.main.async {
            MapRender.mapView.setCamera(camera, withDuration: 0.4, animationTimingFunction: CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut), completionHandler: {
                // get top posts.
            })
        }
    }
    
//    Exit hive
    static let didExitHiveNotificationName = NSNotification.Name(rawValue: "didExitHive")
    @objc func handleexitHiveButton() {
        recalculateHiveRolodex()
        self.navigationItem.title = nil
        NotificationCenter.default.post(name: MapRender.didExitHiveNotificationName, object: nil)
        exitHiveDatabase()
        removeHiveUI()
        MapRender.currentHiveInfo = []
        self.exitHiveUndoColorationAndHideEffect()
        DispatchQueue.main.async {
            self.hiveCollectionView.isHidden = false
            self.hiveCollectionViewBottomAnchor.constant = 0
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (_) in
                    
                })
            }
        }
        
        MapRender.toCurrentLocation()
        MainTabBarController.currentUser?.HID = nil
        MainTabBarController.currentUser?.hiveName = nil
        if let _ = self.navigationController?.navigationBar.subviews.last as? UITextView{
            self.navigationController?.navigationBar.subviews.last?.removeFromSuperview()
        }
        
        //        MapViewController.mapView.removeAnnotations(self.topPostAnnotations)
    }
    
    fileprivate func exitHiveUndoColorationAndHideEffect() {
        self.rolodexHives.forEach { (hd) in
            if let layer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HivePolygon") as? MGLFillStyleLayer, let namelayer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+NameLayer") as? MGLSymbolStyleLayer {
                DispatchQueue.main.async {
                    layer.fillColor = NSExpression(forConstantValue: UIColor.heatColor(rank: 0, outOf: self.rolodexHives.count))
                    layer.isVisible = true
                    namelayer.isVisible = true
                }
            }
            if let heatsource = MapRender.mapView.style?.source(withIdentifier: "\(hd.id)+HeatMapSource") as? MGLShapeSource {
                if let heatlayer = MapRender.mapView.style?.layer(withIdentifier: "\(hd.id)+HeatMapLayer") as? MGLHeatmapStyleLayer {
                    DispatchQueue.main.async {
                        heatlayer.isVisible = false
                        MapRender.mapView.style?.removeLayer(heatlayer)
                        MapRender.mapView.style?.removeSource(heatsource)
                    }
                }
            }
        }
    }
    
    // Have to look up where this is called, because we dont want to reload everything all the time.
    var lastNotificaitonUpdate = 0.0
    fileprivate func handleNotificationIndicator(count: Int){
        let button = navigationItem.rightBarButtonItem
        if let customView = button?.customView as? ButtonWithCount {
            customView.count = count
            self.lastNotificaitonUpdate = NSDate().timeIntervalSince1970
        }
    }
    
    
    fileprivate func exitHiveDatabase() {
        // need to change this function to allow the user to leave with no location.
        var params = ["lastFriendUpdate": self.lastFriendUpdate] as [String : Any]
        if let location = MapRender.mapView.userLocation?.coordinate, (location.latitude != -180 && location.longitude != -180) {
            params["latitude"] = location.latitude
            params["longitude"] = location.longitude
        }
        RequestManager().makeJsonRequest(urlString: "/Hive/api/exitHiveUpdateRolodex", params: params) { (json, _) in
            guard let json = json as? [String: Any] else { return }
            if let hives = json["Hives"] as? [[String:Any]]{
                if let location = MapRender.mapView.userLocation?.coordinate {
                    self.processRolodexHiveArray(hives: hives, location: CLLocation(latitude: location.latitude, longitude: location.longitude))
                }
            }
            if let friends = json["Friends"] as? [[String:Any]] {
                self.lastFriendUpdate = NSDate().timeIntervalSince1970
                self.handleRenderFriends(friends: friends)
            }
            if let notifications = json["Notifications"] as? Int, notifications > 0 {
                self.handleNotificationIndicator(count: notifications)
            } else {
                self.handleNotificationIndicator(count: 0)
            }
        }
    }
    
    func recalculateRolodex() { // is a delegate function for the rolodex cells.
        recalculateHiveRolodex()
    }

    //PREVIEW STUFF
    var isPreviewShowing: Bool = false
    var previewCenterY: NSLayoutConstraint!
    var currentPreviewIndex: Int = 0
    var previewContainer: UIView!
    var previewCollectionView: HivePreviewCollectionView!
    func showPreview(cell: RolidexCell) {
        
        //animate this onto screen later
        guard let indexPath = hiveCollectionView.indexPath(for: cell) else { return }
        DispatchQueue.main.async {
            self.hiveCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.currentPreviewIndex = indexPath.item
            if !self.isPreviewShowing {
                self.animateLoadPreview(cell: cell)
               
                let (hids, offsetFront, offsetRear) = self.getIds(index: indexPath.item - 1)
                self.loadFirstPreview(hids: hids, offsetFront: offsetFront, offsetRear: offsetRear, indexPath: indexPath, completion: {
                    DispatchQueue.main.async {
                        cell.postView.layer.removeAllAnimations()
                    }
                })
               
                
            }
        }
        
    }
    
    fileprivate func animateLoadPreview(cell: RolidexCell) {
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.fromValue = NSNumber(floatLiteral: 0)
        fullRotation.toValue = NSNumber(floatLiteral: Double(CGFloat.pi * 2))
        fullRotation.duration = 0.5
        fullRotation.repeatCount = HUGE
        cell.postView.layer.add(fullRotation, forKey: "360")
        
    }
    
    fileprivate func loadFirstPreview(hids: [Int], offsetFront: Int, offsetRear: Int, indexPath: IndexPath, completion: @escaping() -> ()) {
        
        var posts = [[Post]]()
        let params = ["HIDS": hids] as [String: [Int]]
        RequestManager().makeJsonRequest(urlString: "/Hive/api/fetchHivePreviews", params: params) { (json, rc) in
            if let  code = rc, code == 200 {
            } else {
                completion()
            }
            guard let json = json as? [String: Any] else {print("bAd!"); return }
            
            if json.count > 0 {
                hids.forEach({ (hid) in
                    var postArray = [Post]()
                    if let postJson = json[String(hid)] as? [[String: Any]], postJson.count > 0 {
                        postJson.forEach({ (snapshot) in
                            var post = Post(dictionary: snapshot)
                            let user = User(postdictionary: snapshot)
                            post.user = user
                            postArray.append(post)
                        })
                        posts.append(postArray)
                    } else {
                        print("appending empty post")
                        let post = Post(dictionary: ["id": -1])
                        posts.append([post])
                    }
                })
                
                self.animateUpPreview(indexPath: indexPath, offsetFront: offsetFront, offsetRear: offsetRear, fetchedHids: hids, posts: posts)

                completion()
    
            } else {
                print("json was empty, end animation")
                
                completion()
            }

        }
    }
    
    fileprivate func getIds(index: Int) -> ([Int], Int, Int) {
    
        var ids = [Int]()
        ids.append(self.rolodexHives[index].id)
        
        var i = index - 1
        while i >= 0 && index - i <= 2 {
            ids.insert(self.rolodexHives[i].id, at: 0)
            i-=1
        }
        
        var j = index + 1
        while j < self.rolodexHives.count && j - index <= 2 {
            ids.append(self.rolodexHives[j].id)
            j+=1
        }
        
        return (ids, j - index - 1, index - i - 1)
        
    }
    
    fileprivate func animateUpPreview(indexPath: IndexPath, offsetFront: Int, offsetRear: Int, fetchedHids: [Int] ,posts: [[Post]]) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        previewCollectionView = HivePreviewCollectionView(frame: .zero, collectionViewLayout: layout)
        previewCollectionView.hives = self.rolodexHives
        previewCollectionView.previewDelegate = self
        previewCollectionView.posts = posts
        print(offsetFront, "F", offsetRear, "R")
        previewCollectionView.currentMaxHIDItem = indexPath.item - 1 + offsetFront
        previewCollectionView.currentMinHIDItem = indexPath.item - 1 - offsetRear
        previewCollectionView.startingItem = offsetRear
        previewCollectionView.fetchedHids = fetchedHids
        
        previewContainer = UIView() //to help center the preview
        view.insertSubview(previewContainer, belowSubview: hiveCollectionView)
        previewContainer.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: hiveCollectionView.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.insertSubview(previewCollectionView, aboveSubview: previewContainer)
        previewCollectionView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: (view.frame.width < 350 ? view.frame.width - 20 : view.frame.width), height: view.frame.width * (4/3))
        previewCollectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        previewCenterY = previewCollectionView.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor, constant: view.frame.height)
        previewCenterY.isActive = true
        
        self.view.layoutIfNeeded()
        isPreviewShowing = true
        
        previewCenterY.constant = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            
        }
    }
    
    func endVideosInPreview() {
        if self.isPreviewShowing {
            self.previewCollectionView.endPlayingVideos()
        }
    }

} // End MapRender Class.



