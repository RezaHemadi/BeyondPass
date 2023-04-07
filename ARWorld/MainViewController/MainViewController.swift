//
//  MainViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 10/10/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import CoreLocation
import ARKit
import FoursquareAPIClient
import Parse
import AVFoundation
import CoreMotion

class MainViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, CAAnimationDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - IBOutlets

    @IBOutlet var sceneView: ARWorldView!
    
    @IBOutlet var _profilePic: UIButton!
    
    @IBOutlet var _totalNotifications: UILabel!
    
    @IBOutlet var arCoinLabel: UILabel!
    
    @IBOutlet private var stopButton: UIButton!
    
    @IBOutlet private var playButton: UIButton!
    
    @IBOutlet private var recordButton: UIButton!
    
    @IBOutlet private var timeLabel: UILabel!
    
    @IBOutlet var audioConsole: UIView!
    
    @IBOutlet var insertAudio: UIButton!
    
    @IBOutlet var cancelAudio: UIButton!
    
    @IBOutlet var transactionNotificationLabel: UILabel!
    
    @IBOutlet var coinModificationLabel: UILabel!
    
    @IBOutlet var coinIcon: UIImageView!
    
    @IBOutlet var _addTextDialog: UIView!
    
    @IBOutlet var _addTextField: UITextField!
    
    @IBOutlet var _addTextFieldNoCharacters: UILabel!
    
    // MARK: - Properties
    var shouldDetectPlanes: Bool = true
    
    var graffitiesToBeDisplayed: [String: PFObject] = [:]
    
    var trophyController = TrophyController(user: PFUser.current()!)
    
    var isPickingColor: Bool = false
    
    var targetingVerticalPlane: Bool = false {
        didSet {
            guard oldValue != targetingVerticalPlane , accurateLocationAvailable  else { return }
            
            if targetingVerticalPlane {
                showGraffitiUI()
            } else {
                hideGraffitiUI()
            }
        }
    }
    var previewNode: PreviewNode?
    
    var boardIndicatorView: PinboardIndicatorView!
    
    var treasureManager: TreasureManager?
    
    var publicPinBoard: [PinBoardPublic] = []
    
    var stickyTempLocalPos: SCNVector3?
    
    var stickyTempEulerAngles: SCNVector3?
    
    var stickyHitResult: SCNHitTestResult?
    
    var currentVenue: Venue?
    
    var updatingVenue: Bool = false
    
    var story: Story?
    
    var activeStory: Bool?
    
    var location: CLLocation!
    
    var userHeading: CLLocationDirection!
    
    var notification: Notification!
    
    weak var targetUserProfile: PFUser!
    
    var audioPlayer: AVAudioPlayer?
    
    var audioRecorder: AVAudioRecorder?
    
    private var timer: Timer?
    
    private var elapsedTimeInSeconds: Int = 0
    
    var cassettePlayer: AVAudioPlayer?
    
    var audioSession: AVAudioSession?

    var robot = Robot()
    
    var dock = Dock()
    
    var appMode: AppMode = .normal {
        didSet {
            guard appMode != oldValue else { return }
            
            switch appMode {
            case .normal:
                locationManager.startUpdatingLocation()
                dock.collapse()
            default:
                currentVenue = nil
                publicPinBoard.forEach { $0.rootNode?.removeFromParentNode() }
                publicPinBoard.removeAll()
                compassBar.bearingToPinBoard.removeAll()
                dock.hide()
                hidePlusButton()
                locationManager.stopUpdatingLocation()
                accurateLocationAvailable = false
                hideLocationBasedContent()
            }
        }
    }
    
    var targetingTemple: Bool = false {
        didSet {
            guard oldValue != targetingTemple else { return }
            
            if targetingTemple {
                DispatchQueue.main.async {
                    self.plusButton.isHidden = true
                    UIView.animate(withDuration: 0.3, animations: {
                        self.stickyIconsView.transform = CGAffineTransform.identity
                        self.boardIndicatorView.transform = CGAffineTransform.identity
                    })
                }
            } else {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.stickyIconsView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                        if !self.targetingSticky {
                            self.boardIndicatorView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                            self.plusButton.isHidden = false
                        }
                    })
                }
            }
        }
    }
    
    var targetingSticky: Bool = false {
        didSet {
            guard oldValue != targetingSticky else { return }
            
            if targetingSticky {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.boardIndicatorView.transform = CGAffineTransform.identity
                    })
                }
                if isStickyDeletable(hitResult: lastHitTest!) {
                    DispatchQueue.main.async {
                        self.stickyRecycleView.transform = CGAffineTransform.identity
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.stickyRecycleView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                }
            }
        }
    }
    
    var needPlane: Bool = false
    
    var lastHitTest: SCNHitTestResult?
    
    var accurateLocationAvailable: Bool = false {
        didSet {
            if accurateLocationAvailable && activeStory == false {
                showLocationBasedContent()
            } else {
                hideLocationBasedContent()
                
                
            }
        }
    }
    
    //var sandboxTimeWatcher: TimeWatcher?
    
    let locationManager = CLLocationManager()
    
    let motionManager = CMMotionManager()
    
    var deviceMotions: [CMDeviceMotion] = []
    
    var currentDartGame: DartGame?
    
    var screenCenter: CGPoint!
    
    var charactersOnPlaneQueue: [Character] = []
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "beyondpass.thingoteam.serialSceneKitQueue")
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let modelLoader = ModelLoader()
    
    var portal: ARPortal?
    
    var initializingGPS: Bool = true
    
    var personalPinBoard: PersonalPinBoard?
    
    // MARK: - UI Elements
    var hsbColorPickerView: HSBColorPicker!
    
    var colorPicker: UIColorPickerView!
    
    var sprayCan: SprayCan = SprayCan()
    
    var graffitiUIView: GraffitiUIView!
    
    var stickyNote: UITextView!
    
    var stickyIconsView: UIView!
    
    var stickyRecycleView: UIView!
    
    var portalDecorationOK: UIImageView?
    
    var portalDecorationReject: UIImageView?
    
    var optionsDock: OptionsDock? {
        didSet {
            if optionsDock != nil {
                optionsDock!.delegate = self
                let trailingConstraint = NSLayoutConstraint(item: optionsDock!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: optionsDock!.expandedX)
                optionsDock!.state = .expanded
                optionsDock!.constraint = trailingConstraint
                let centerVerticallyConstraint = NSLayoutConstraint(item: optionsDock!, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
                
                view.addConstraints([trailingConstraint, centerVerticallyConstraint])
                optionsDockConstraints.append(contentsOf: [trailingConstraint, centerVerticallyConstraint])
                
                // Add gesture recognizers for the sandbox dock
                let swipeLeftGesture = UIScreenEdgePanGestureRecognizer(target: optionsDock!, action: #selector(OptionsDock.dockPanned))
                swipeLeftGesture.edges = .right
                optionsDock!.addGestureRecognizer(swipeLeftGesture)
                
                let swipeRightGesture = UISwipeGestureRecognizer(target: optionsDock!, action: #selector(OptionsDock.swipedRight))
                swipeRightGesture.direction = .right
                optionsDock!.addGestureRecognizer(swipeRightGesture)
            } else {
                optionsDockConstraints.forEach( { self.view.removeConstraint($0)} )
                optionsDockConstraints = []
            }
        }
    }
    
    var optionsDockConstraints: [NSLayoutConstraint] = []
    
    var portalDecorationsView: PortalDecorationsView?
    
    var focusSquare: FocusSquare?
    
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    /// The view controller that displays the status.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// View controller for displaying a form for gifting in ar view
    fileprivate lazy var arGiftViewController: ARGiftViewController = self.buildFromStoryboard("Main")
    
    lazy var creditsViewController: CreditsViewController = self.buildFromStoryboard("Main")
    
    lazy var mainStoreViewController: MainStoreViewController = self.buildFromStoryboard("Main")
    
    var chestViewController: ChestViewController?
    
    var hintsController = HintsController.sharedInstance()
    
    var compassBar = CompassBar()
    
    lazy var plusButton = PlusButton()
    
    lazy var radialMenue = RadialMenue()
    
    var sandboxNodes: [SCNNode]?
    
    var locationBasedNodes: [SCNNode] = []
    
    // MARK: - Instances to control Texts and Cassettes and SkyStickers
    var skyWritingViewer: SkyWritingViewer?
    var cassetteViewer: CassetteViewer?
    var skyStickerViewer: SkyStickerViewer?
    var whisperMarkerManager: WhisperMarkerManager?
    var graffitiLoader: GraffitiLoader?
    
    // MARK: - Instances to control banners
    
    /// Instance to control the displaying of nearby user banners
    var userBannerViewer: UserBannerViewer?
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds = sceneView.bounds
        screenCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        /// Find the User's progress in Story
        let storyQuery = PFQuery(className: "Story")
        storyQuery.whereKey("User", equalTo: PFUser.current()!)
        storyQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if (objects?.first) != nil {
                   // let level = storyObject["Level"] as! NSNumber
                   // self.story = Story(level: level.intValue)
                   // self.story?.delegate = self
                    self.activeStory = false
                    
                    // Add dock
                    self.addDock()
                    
                } else {
                    // Play level 1
                    self.story = Story(level: 1)
                    self.story?.delegate = self
                    self.activeStory = true
                }
            }
        }
        
        let inventoryQuery = PFQuery(className: "Inventory")
        inventoryQuery.whereKey("User", equalTo: PFUser.current()!)
        inventoryQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                if objects!.isEmpty {
                    PFUser.current()!.createDefaultInventory()
                }
            }
        }

        portal?.user = PFUser.current()!
        portal?.delegate = self
        // Do any additional setup after loading the view.
        blurEffectView.frame = view.bounds
        blurEffectView.layer.opacity = 1.0
        sceneView.addSubview(blurEffectView)
        navigationController?.isNavigationBarHidden = true
        
        trophyController.delegate = self
        
        // Display the compass bar
        showCompassBar()
        showPlusButton()
        
        initGraffitiUI()
        initColorPickerView()
        initHSBColorPickerView()
        
        showStickyIcons()
        
        showStickyRecycleIcon()
        
        statusViewController.delegate = self
        
        _addTextField.delegate = self
        
        _profilePic.isEnabled = false
        
        setupAudioSession()
        
        notification = Notification(user: PFUser.current()!)
        
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        //sceneView.automaticallyUpdatesLighting = true
        sceneView.isUserInteractionEnabled = true
        //sceneView.debugOptions = [SCNDebugOptions.showPhysicsShapes]
        sceneView.setupDirectionalLighting()
        
        //sceneView.automaticallyUpdatesLighting = false
        
        setupCamera()
        
        startLocationService()
        
        showProfilePictureOnScreen()
        DispatchQueue.main.async {
            self.registerGestureRecognizers()
        }
        
        initializeSubViewTransforms()
        
        refreshARCoins()
        
        let currentInstallation = PFInstallation.current()
        currentInstallation?["user"] = PFUser.current()!
        currentInstallation?.saveInBackground()
        
        enableSpeech(robot: robot) // let the robot speak
        
        let when2 = DispatchTime.now() + 15
        DispatchQueue.main.asyncAfter(deadline: when2) {
            self.initializingGPS = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = .personSegmentationWithDepth
        if #available(iOS 12, *) {
            configuration.environmentTexturing = .automatic
        }
        self.navigationController?.isNavigationBarHidden = true
        
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        sceneView.antialiasingMode = .multisampling4X
        //sceneView.autoenablesDefaultLighting = true
    }
    
   override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self._profilePic.layer.cornerRadius = self._profilePic.bounds.width / 2
    }
    
    // MARK: - User Interface
    
    private func showProfilePictureOnScreen() {
        if let currentUser = PFUser.current() {
            let image = currentUser["profilePic"] as? PFFileObject
            if let image = image {
                image.getDataInBackground {
                    (imageData: Data?, error: Error?) -> Void in
                    if let imageData = imageData {
                        self._profilePic.setImage(UIImage(data: imageData), for: UIControl.State.normal)
                        self._profilePic.imageView?.contentMode = .scaleAspectFit
                        self._profilePic.clipsToBounds = true
                        self._profilePic.contentMode = .scaleAspectFill
                            
                        self.refreshNotifications()
                    }
                }
            } else {
                // attempt to get profile pic from user's facebook profile
                Profile.loadCurrentProfile {
                    (profile, error) in
                    if let profile = profile {
                        let imageURL = profile.imageURL(forMode: Profile.PictureMode.normal, size: CGSize.init(width: 60, height:60))!
                        
                        URLSession.shared.dataTask(with: imageURL) {
                            (data: Data?, urlResponse: URLResponse?, error: Error?) in
                            if let data = data {
                                self._profilePic.setImage(UIImage(data: data), for: UIControl.State.normal)
                                self._profilePic.clipsToBounds = true
                                self._profilePic.imageView?.contentMode = .scaleAspectFit
                                self._profilePic.contentMode = .scaleAspectFill
                                
                                self.refreshNotifications()
                            }
                            }.resume()
                    }
                }
            }
        }
    }
    
    private func initializeSubViewTransforms() {
        audioConsole.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        _addTextDialog.transform = CGAffineTransform.init(scaleX: 0, y: 0)
    }
    
    private func refreshARCoins() {
        PFUser.current()!.fetchInBackground {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                let coin = user["ARCoin"] as? NSNumber
                if let coin = coin {
                    self.arCoinLabel.text = String(describing: coin)
                }
            }
        }
    }
    
    
    @IBAction func TSubmit(_ sender: Any) {
        
        // if the user has enough coins
        let currentUser = PFUser.current()
        
        if let currentUser = currentUser {
            
            let coins = currentUser["ARCoin"] as? Int
            
            if let coins = coins {
                
                if (coins < 15) {
                    
                    let alertMessage = UIAlertController(title: "Insufficient ARCoin", message: "You need 15 ARCoins to add a message", preferredStyle: .alert)
                    alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.present(alertMessage, animated: true, completion:nil)
                    
                    return
                }
                
                let text = _addTextField.text!
                
                
                updateQueue.async {
                    let skyWriting = SkyWriting.init(text, author: PFUser.current()!, location: self.location)
                    self.sceneView.addInfrontOfCamera(node: skyWriting, at: SCNVector3Make(0, 0, -1))
                    skyWriting.saveInDataBase { (succeed, error) in
                        DispatchQueue.main.async {
                            self.skyWritingViewer?.addedObjects.append(skyWriting)
                            self.modifyARCoin(.SkyWriting)
                        }
                    }
                }
                
                _addTextField.isUserInteractionEnabled = false
                _addTextField.text = ""
                
                UIView.animate(withDuration: 0.3, animations: {
                    self._addTextDialog.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                })
                
                plusButton.interfaceHidden = false
                unhidePlusButton()
                
                
            } else {
                return
            }
        }
    }
    @IBAction func closeButton(_ sender: Any) {
        UIView.animate(withDuration: 0.3, animations: {
            self._addTextDialog.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        })
        self._addTextField.isUserInteractionEnabled = false
        self._addTextField.text = ""
        plusButton.interfaceHidden = false
        unhidePlusButton()
    }
    
    func startLocationService() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = LocationManagerDistanceFilter
        
        
        if (CLLocationManager.authorizationStatus() == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        
  
        
        if ( CLLocationManager.headingAvailable() ) {
            locationManager.headingFilter = LocationManagerHeadingFilter
            locationManager.startUpdatingHeading()
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if (status == .authorizedWhenInUse) {
            self.locationManager.startUpdatingLocation()
            self.location = locationManager.location
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if  let location = locations.last {
            
            let eventDate: Date = location.timestamp
            let howRecent = eventDate.timeIntervalSinceNow
            
            if (abs(howRecent) < LocationUpdateHowRecentTolerance) {
                
                // if the event is recent do something with it
                let accuracy = location.horizontalAccuracy
                
                if (Int(accuracy) < 50 && Int(accuracy) > 0) && story == nil {
                    if treasureManager == nil {
                        treasureManager = TreasureManager(location: location)
                        treasureManager?.delegate = self
                    } else {
                        treasureManager?.location = location
                    }
                }
                
                if (Int(accuracy) < PrefferedLocationAccuracy && Int(accuracy) > 0) {
                    self.location = location
                    updateQueue.async {
                        self.userBannerViewer?.location = location
                        self.skyWritingViewer?.location = location
                        self.skyStickerViewer?.location = location
                        self.whisperMarkerManager?.location = location
                        self.graffitiLoader?.location = location
                        self.accurateLocationAvailable = true
                    }
                    updateUserLocation()
 
                } else {
                    accurateLocationAvailable = false
                    
                    // if gps is fully initialized, check for accurate position and show PinBoard
                    if !initializingGPS {
                        // user is indoors
                        activatePublicPinBoard()
                    }
                }
            } else {
                accurateLocationAvailable = false
            }
        }
 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        guard newHeading.headingAccuracy > 0 else { return }
        
        // use the true heading if its valid
        if (newHeading.trueHeading > 0) {
            self.userHeading = newHeading.trueHeading
            compassBar.heading = newHeading.trueHeading
            
            var pinBoardAngles: [CGFloat] = []
            for pinBoard in self.publicPinBoard {
                guard pinBoard.rootNode != nil else { continue }
                /// Calculate angle
                if let camera = sceneView.pointOfView {
                    let vector = sceneView.scene.rootNode.simdConvertPosition(pinBoard.rootNode!.simdPosition, to: camera)
                    let normalizedVector = simd_normalize(float3(vector.x, 0, vector.z))
                    let teta = acos(simd_dot(normalizedVector, float3(0, 0, -1))) * 180 / .pi
                    
                    if vector.x > 0 {
                        pinBoardAngles.append(CGFloat(teta))
                    } else {
                        pinBoardAngles.append(CGFloat(-teta))
                    }
                }
            }
            
            if let treasureManager = treasureManager {
                if let treasure = treasureManager.activeTreasure {
                    if let camera = sceneView.pointOfView {
                        let vector = sceneView.scene.rootNode.simdConvertPosition(treasure.refNode.simdPosition, to: camera)
                        let normalizedVector = simd_normalize(float3(vector.x, 0, vector.z))
                        let teta = acos(simd_dot(normalizedVector, float3(0, 0, -1))) * 180 / .pi
                        
                        if vector.x > 0 {
                            compassBar.bearingToTreasure = CGFloat(teta)
                        } else {
                            compassBar.bearingToTreasure = CGFloat(-teta)
                        }
                    }
                }
            }
            compassBar.bearingToPinBoard = pinBoardAngles
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Notification" {
            let notificationViewController = segue.destination as! NotificationsViewController
            notificationViewController.notification = self.notification
        }
        else if segue.identifier == "MainToUsersProfile" {
            let destinationViewController = segue.destination as! UsersProfileViewController
            destinationViewController.delegate = self
            destinationViewController.targetUser = self.targetUserProfile
        }
    }
    
    @IBAction func unwindToMainFromEditProfile(segue: UIStoryboardSegue) {
        
        if let currentUser = PFUser.current() {
            
            let profilePic = currentUser["profilePic"] as? PFFileObject
            
            if let profilePic = profilePic {
                
                profilePic.getDataInBackground {
                    (data: Data?, error: Error?) -> Void in
                    
                    if let data = data {
                        
                        self._profilePic.imageView?.image = UIImage(data: data)
                        self._profilePic.imageView?.contentMode = .scaleAspectFit
                        self._profilePic.clipsToBounds = true
                    }
                }
            }
        }
    }
    
    // MARK: - Location Based Content
    
    private func showLocationBasedContent() {
        guard self.location != nil else { return }
        unhidePlusButton()
        updateQueue.async {
        if self.userBannerViewer == nil {
            
                self.userBannerViewer = UserBannerViewer(location: self.location)
                self.userBannerViewer?.delegate = self
            
        }
        if self.skyWritingViewer == nil {
            
                self.skyWritingViewer = SkyWritingViewer(location: self.location)
                self.skyWritingViewer?.skyWritingViewerDelegate = self
            
        }
        if self.cassetteViewer == nil {
            
                self.cassetteViewer = CassetteViewer(location: self.location)
                self.cassetteViewer?.cassetteViewerDelegate = self
            
        }
        if self.skyStickerViewer == nil {
            
                self.skyStickerViewer = SkyStickerViewer(location: self.location)
                self.skyStickerViewer?.skyStickerViewerDelegate = self
            
        }
        if self.whisperMarkerManager == nil {
           
                self.whisperMarkerManager = WhisperMarkerManager(location: self.location)
                self.whisperMarkerManager?.delegate = self.compassBar
            
        } 
        if self.graffitiLoader == nil {
            
                self.graffitiLoader = GraffitiLoader(location: self.location)
                self.graffitiLoader?.delegate = self
            
        }
        
            self.userBannerViewer?.displayedBanners.forEach({$0.isHidden = false})
            self.skyWritingViewer?.addedObjects.forEach({ $0.isHidden = false })
            self.cassetteViewer?.addedObjects.forEach({ $0.isHidden = false })
            self.skyStickerViewer?.addedObjects.forEach({ $0.node.isHidden = false })
        }
    }
    
    private func hideLocationBasedContent() {
        hidePlusButton()
        
        updateQueue.async {
            self.userBannerViewer?.displayedBanners.forEach({$0.isHidden = true})
            self.skyWritingViewer?.addedObjects.forEach({ $0.isHidden = true })
            self.cassetteViewer?.addedObjects.forEach({ $0.isHidden = true })
            self.skyStickerViewer?.addedObjects.forEach({ $0.node.isHidden = true })
            self.compassBar.bearingToTreasure = nil
        }
    }
    
    func registerGestureRecognizers() {
        
        // tap gesture to dismiss the keyboard
        let viewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(viewTapGestureRecognizer)
        
        // screen edge pan gesture recognizer for the left dock
        let dockPanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: dock, action: #selector(Dock.dockPanned))
        dockPanGestureRecognizer.edges = .left
        dock.addGestureRecognizer(dockPanGestureRecognizer)
        
        // swipe left gesture recognizer for the left dock
        let dockSwipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: dock, action: #selector(Dock.swipedLeft))
        dockSwipeLeftGestureRecognizer.direction = .left
        dock.addGestureRecognizer(dockSwipeLeftGestureRecognizer)
        
        // Tap gesture Recognizer for models
        let modelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.modelTapped))
        self.sceneView.addGestureRecognizer(modelTapGestureRecognizer)
 
    }
   
    @IBAction func profilePicTapped(sender: UIButton) {
        self.performSegue(withIdentifier: "Notification", sender: self)
    }
    
    func displayOutsideScene () {
        /*
        self.addNearTexts() {
            (succeed: Bool?, error: Error?) -> Void in
        }
        /*
        self.addFarTexts() {
            (succeed: Bool?, error: Error?) -> Void in
        }
 */
        self.addNearOutsideModels() {
            (succeed: Bool?, error: Error?) -> Void in
        }
/*
        self.addSkyStickers() {
            (succeed: Bool?, error: Error?) -> Void in
            
        }
 */
        self.addNearCassettes() {
            (succeed: Bool?, error: Error?) -> Void in
        }
/*
        self.addWhispers() {
            (succeed: Bool?, error: Error?) -> Void in
        }
 */
 */
    }
    
    func positionToDistance(_ position: SCNVector3) -> Double {
        var distance: Double = Double(pow(position.x, 2) + pow(position.y, 2) + pow(position.z, 2))
        distance = distance.squareRoot()
        
        return distance
    }
    
    func getScalingFactor(_ distance: Double) -> Double {
        return (distance / BannerScalingFactorConstant)
    }
    
    @IBAction func viewObjects(_ sender: UIButton) {
        
        // Display a view holding the models
        let holderView = UIView()
        holderView.translatesAutoresizingMaskIntoConstraints = false
        holderView.tag = MainView.ModelsHolder.rawValue
        view.addSubview(holderView)
        holderView.backgroundColor = UIColor.gray
        holderView.alpha = 0.6
        
        holderView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        let holderViewWidthConstraint = NSLayoutConstraint(item: holderView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.5, constant: 0)
        let holderViewCenterHorizontally = NSLayoutConstraint(item: holderView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let holderViewCenterVertically = NSLayoutConstraint(item: holderView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.5, constant: 0)
        view.addConstraints([holderViewWidthConstraint,
                             holderViewCenterHorizontally,
                             holderViewCenterVertically])
        
        // set different height constraint for different size classes
        if view.traitCollection.verticalSizeClass == .compact {
            
            let holderViewHeightConstraint = NSLayoutConstraint(item: holderView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
            holderView.addConstraint(holderViewHeightConstraint)
            holderView.layer.cornerRadius = 7.5
        } else if view.traitCollection.verticalSizeClass == .regular {
            
            let holderViewHeightConstraint = NSLayoutConstraint(item: holderView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
            holderView.addConstraint(holderViewHeightConstraint)
            holderView.layer.cornerRadius = 15
        }
        
        // Add the models photos to the holder view
        let heartImageView = UIImageView(image: UIImage(named: "Heart")!)
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
        holderView.addSubview(heartImageView)
        
        let heartAspectRatioConstraint = NSLayoutConstraint(item: heartImageView, attribute: .width, relatedBy: .equal, toItem: heartImageView, attribute: .height, multiplier: 1.02, constant: 0)
        heartImageView.addConstraint(heartAspectRatioConstraint)
        
        let hearHorizontalConstraint = NSLayoutConstraint(item: heartImageView, attribute: .centerX, relatedBy: .equal, toItem: holderView, attribute: .centerX, multiplier: 0.3, constant: 0)
        let heartHeightConstraint = NSLayoutConstraint(item: heartImageView, attribute: .height, relatedBy: .equal, toItem: holderView, attribute: .height, multiplier: 0.7, constant: 0)
        let heartCenterVerticallyConstraint = NSLayoutConstraint(item: heartImageView, attribute: .centerY, relatedBy: .equal, toItem: holderView, attribute: .centerY, multiplier: 1, constant: 0)
        holderView.addConstraints([hearHorizontalConstraint, heartHeightConstraint, heartCenterVerticallyConstraint])
        
        let candleImageView = UIImageView(image: UIImage(named: "CandlePhoto")!)
        candleImageView.translatesAutoresizingMaskIntoConstraints = false
        holderView.addSubview(candleImageView)
        
        let candleAspectRatioConstraint = NSLayoutConstraint(item: candleImageView, attribute: .width, relatedBy: .equal, toItem: candleImageView, attribute: .height, multiplier: 0.5, constant: 0)
        candleImageView.addConstraint(candleAspectRatioConstraint)
        
        let candleCenterVerticallyConstraint = NSLayoutConstraint(item: candleImageView, attribute: .centerY, relatedBy: .equal, toItem: holderView, attribute: .centerY, multiplier: 1, constant: 0)
        let candleHorizontalConstraint = NSLayoutConstraint(item: candleImageView, attribute: .centerX, relatedBy: .equal, toItem: holderView, attribute: .centerX, multiplier: 0.75, constant: 0)
        let candleHeightConstraint = NSLayoutConstraint(item: candleImageView, attribute: .height, relatedBy: .equal, toItem: holderView, attribute: .height, multiplier: 0.7, constant: 0)
        
        holderView.addConstraints([candleHorizontalConstraint, candleHeightConstraint, candleCenterVerticallyConstraint])
        
        UIView.animate(withDuration: 0.3, animations: {
            holderView.transform = CGAffineTransform.identity
        })
    }
    func updateUserLocation() {
        if let user = PFUser.current() , let location = self.location {
            let userLocation = PFGeoPoint(location: location)
            user["location"] = userLocation
            user.saveEventually()
        }
    }
    
    func fetchUserImage(_ user: PFUser, _ completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) -> Void {
        let profilePic = user["profilePic"] as? PFFileObject
        profilePic?.getDataInBackground {
            (data: Data?, error: Error?) -> Void in
            if error == nil {
                if let data = data {
                    completion(UIImage(data: data), nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    func buttom(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
    
    @objc func modelTapped(recognizer: UITapGestureRecognizer) {
        let sceneView = recognizer.view as! ARWorldView
        let touchLocation = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        
        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else {
                return
            }
            let node = hitResult.node
            
            // check the node category
            if (node.categoryBitMask == NodeCategories.follow.rawValue) {
                // send the target a follow request
                // fetch the target user
                if let id = node.name {
                    let query = PFUser.query()
                    query?.whereKey("objectId", equalTo: id)
                    query?.findObjectsInBackground {
                        (objects: [PFObject]?, error: Error?) -> Void in
                        if let error = error {
                            print("error: \(error.localizedDescription)")
                        } else if let objects = objects {
                            let targetUser = objects.first
                            if let from = PFUser.current(), let to = targetUser {
                                sendFollowRequest(from: from, to: to) {
                                    (status: FollowStatus?, error: Error?) -> Void in
                                    if let error = error {
                                        print("error: \(error.localizedDescription)")
                                    } else if let status = status {
                                        if let banner = self.userBannerViewer?.displayedBanners.first(where: { $0.id == id }) {
                                            banner.statusBox.status = status
                                        }
                                        switch status {
                                        case FollowStatus.following:
                                            // change the badge to following
                                            do {
                                                
                                               try modifyInfoBadge(inNode: node, to: "Following")
                                                
                                                self.modifyARCoin(CoinTransaction.FollowedUser)
                                                
                                                let params = ["followedUserId": to.objectId!]
                                                PFCloud.callFunction(inBackground: "newFollowerCoin", withParameters: params) {
                                                    (response: Any?, error: Error?) -> Void in
                                                    
                                                }
                                            } catch {
                                                print("error: \(error.localizedDescription)")
                                            }
                                        case FollowStatus.requested:
                                            // change the badge to requested
                                            do {
                                                try modifyInfoBadge(inNode: node, to: "Requested")
                                            } catch {
                                                print("error: \(error.localizedDescription)")
                                            }
                                        default:
                                            print("error: followRequest sent unknown")
                                        }
                                    }
                                }
                            } else {
                                print("error: no such user")
                            }
                        }
                    }
                } else {
                    print("error: planeNodeBadge has no name")
                }
            }
            if node.categoryBitMask == NodeCategories.treasure.rawValue {
                treasureManager?.treasureCollected()
            }
            if node.categoryBitMask == NodeCategories.portalDecoration.rawValue {
                guard portal != nil, portal!.state == .decorating else { return }
                
                let id = node.name!
                
                if let modelNode = portal!.decorationModels[id] {
                    modelNode.removeFromParentNode()
                    let preview = PreviewNode(node: modelNode)
                    let (min, max) = preview.boundingBox
                    let dx = min.x + 0.5 * (max.x - min.x)
                    let dy = min.y
                    let dz = min.z + 0.5 * (max.z - min.z)
                    preview.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                    preview.opacity = 0.8
                    self.portal!.decorationModelPreview = preview
                    self.sceneView.addInfrontOfCamera(node: self.portal!.decorationModelPreview!, at: SCNVector3Make(0, 0, -1))
                    self.showPortalDecorationsUI()
                    self.portal!.editingExistingDecorationModel = true
                    self.portal!.editingDecorationID = id
                }
                print("Decoration item with id \(id) tapped.")
            }
            if node.categoryBitMask == NodeCategories.voiceBadge.rawValue {
                print("Voice badge tapped")
                if let id = node.name {
                    print("Voice badge id: \(id)")
                    
                    switch appMode {
                    case .normal:
                        publicPinBoard.first!.playVoiceBadge(id: id)
                    case .portal:
                        break
                    case .pinBoard:
                        break
                    default:
                        break
                    }
                    
                    /*
                    if let voiceBadge = publicPinBoard.first?.voiceBadges[id] {
                        voiceBadge.loadAudio() { (data, error) in
                            do {
                                self.cassettePlayer = try AVAudioPlayer(data: data!)
                                self.cassettePlayer?.delegate = self
                                self.cassettePlayer?.isMeteringEnabled = true
                                self.cassettePlayer?.prepareToPlay()
                                self.cassettePlayer?.play()
                            } catch {
                                print(error)
                            }
                        }
                    } */
                } else {
                    print("node has no name")
                }
            }
            if node.categoryBitMask == NodeCategories.dartboardOption.rawValue {
                guard portal != nil, portal?.dartboard.optionNode != nil else { return }
                
                portal?.dartboard.optionTapped()
            }
            if node.categoryBitMask == NodeCategories.dart1.rawValue {
                guard appMode == .portal else { return }
                
                switch portal!.dartboard.gameState {
                case .pickingDart:
                    portal!.dartboard.gameState = .throwingDart(variant: .right)
                default:
                    break
                }
            }
            if node.categoryBitMask == NodeCategories.dart2.rawValue {
                guard appMode == .portal else { return }
                
                switch portal!.dartboard.gameState {
                case .pickingDart:
                    portal!.dartboard.gameState = .throwingDart(variant: .left)
                default:
                    break
                }
            }
            if node.categoryBitMask == NodeCategories.visitPortal.rawValue {
                guard appMode == .normal else { return }
                let userID = node.name!
                let userQuery = PFUser.query()!
                userQuery.getObjectInBackground(withId: userID, block: { (object, error) in
                    if error == nil {
                        if let user = object as? PFUser {
                            if self.portal == nil {
                                self.portal = ARPortal(user: user)
                            }
                            self.portal?.visiting = true
                            
                            self.appMode = .portal
                            
                            self.shouldDetectPlanes = false
                            
                            self.portal?.delegate = self
                            
                            self.portal?.setupPreview({ (preview) in
                                DispatchQueue.main.async {
                                    self.sceneView.scene.rootNode.addChildNode(preview!)
                                }
                            })
                            
                            self.statusViewController.showMessage("Portal Mode - Tap To Close", autoHide: false)
                            self.targetingSticky = false
                            self.targetingTemple = false
                            self.removePopUpViews()
                        }
                    }
                })
            }
            if node.categoryBitMask == NodeCategories.giftBox.rawValue {
                // Display gift form
                addChild(arGiftViewController)
                
                // Setup constraints for the form view
                let formView = arGiftViewController.view!
                
                view.addSubview(formView)
                
                formView.translatesAutoresizingMaskIntoConstraints = false
                formView.alpha = 0.6
                
                let centerHorizontally = NSLayoutConstraint(item: formView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
                let centerVertically = NSLayoutConstraint(item: formView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
                let widthConstraint = NSLayoutConstraint(item: formView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.7, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: formView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
                
                view.addConstraints([centerHorizontally,
                                     centerVertically,
                                     widthConstraint,
                                     heightConstraint])
                
                arGiftViewController.didMove(toParent: self)
                
                // Find the target user
                let targetUser = userBannerViewer?.nearUsers.first(where: { $0.objectId == node.name! })
                arGiftViewController.targetUser = targetUser
            }
            if node.categoryBitMask == NodeCategories.modelOnTable.rawValue {
                // check to see if the info plane is already displayed
                let name = node.parent?.name
                let planeNode = node.childNode(withName: name!, recursively: true)
                if let planeNode = planeNode {
                    planeNode.removeFromParentNode()
                } else {
                    // add info plane for node
                    self.addInfoPlane(node)
                }
            }
            // show users profile when info plane node is tapped
            if node.categoryBitMask == NodeCategories.infoPlane.rawValue {
                // name of the node is the object id in the IndoorObjects table
                // find the user who added this object
                let indoorObjectQuery = PFQuery(className: "IndoorObject")
                let indoorObjectId = node.name
                if let indoorObjectId = indoorObjectId {
                    indoorObjectQuery.whereKey("objectId", equalTo: indoorObjectId)
                    indoorObjectQuery.findObjectsInBackground {
                        (objects: [PFObject]?, error: Error?) -> Void in
                        if let object = objects?.first {
                            let addedBy = object["addedBy"] as? PFUser
                            if let addedBy = addedBy {
                                self.targetUserProfile = addedBy
                                self.performSegue(withIdentifier: "MainToUsersProfile", sender: self)
                            }
                        }
                    }
                }
            }
            if node.categoryBitMask == NodeCategories.profilePic.rawValue {
                let userId = node.name
                let userQuery = PFUser.query()
                if let userQuery = userQuery, let userId = userId {
                    userQuery.getObjectInBackground(withId: userId) {
                        (userObject: PFObject?, error: Error?) -> Void in
                        if let userObject = userObject {
                            self.targetUserProfile = userObject as! PFUser
                            self.performSegue(withIdentifier: "MainToUsersProfile", sender: self)
                        }
                    }
                }
            }
            
            // case an outside cassette is tapped
            if (node.categoryBitMask == NodeCategories.cassette.rawValue) {
                let id = node.name
                print("Cassette tapped with id: \(id)")
                let cassetteQuery = PFQuery(className: "Cassette")
                cassetteQuery.whereKey("objectId", equalTo: id)
                
                cassetteQuery.findObjectsInBackground {
                    (objects: [PFObject]?, error: Error?) -> Void in
                    
                    if let error = error {
                        print(error)
                    } else if let cassetteObject = objects?.first, let currentUser = PFUser.current() {
                        
                        // check whether this cassette is visited by this user before
                        let visitedCassettesRelation = currentUser.relation(forKey: "VisitedCassettes")
                        let visitedCassettesQuery = visitedCassettesRelation.query()
                        visitedCassettesQuery.whereKey("objectId", equalTo: cassetteObject.objectId!)
                        
                        visitedCassettesQuery.findObjectsInBackground {
                            (objects: [PFObject]?, error: Error?) -> Void in
                            
                            if let _ = objects?.first {
                                
                                // don't modify user's ar coins
                                
                            } else if error == nil {
                                
                                visitedCassettesRelation.add(cassetteObject)
                                
                                currentUser.saveInBackground {
                                    (succeed: Bool?, error: Error?) -> Void in
                                    
                                    if let _ = succeed {
                                        
                                        // modify the user coins
                                        self.modifyARCoin(CoinTransaction.ListenVoice)
                                    }
                                }
                            }
                        }
                        
                        //play the audio file
                        let audioFile = cassetteObject["audio"] as! PFFileObject
                        audioFile.getDataInBackground {
                            (audioData: Data?, error: Error?) -> Void in
                            
                            if error == nil {
                                
                                do {
                                    self.cassettePlayer = try AVAudioPlayer(data: audioData!)
                                    self.cassettePlayer?.delegate = self
                                    self.cassettePlayer?.isMeteringEnabled = true
                                    self.cassettePlayer?.prepareToPlay()
                                    self.cassettePlayer?.play()
                                    
                                    
                                } catch {
                                    print(error)
                                }
                                
                            } else {
                                let alertMessage = UIAlertController(title: "File Error", message: "failed to get the directory url", preferredStyle: .alert)
                                alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                
                                self.present(alertMessage, animated: true, completion: nil)
                            }
                            
                        }
                        // display user info
                        let addedBy = cassetteObject["addedBy"] as! PFObject
                        
                        addedBy.fetchInBackground {
                            (object: PFObject?, error: Error?) -> Void in
                            if let user = object {
                                
                                let userPlane = SCNPlane(width: 0.1, height: 0.1)
                                let billboardConstraint = SCNBillboardConstraint()
                                billboardConstraint.freeAxes = SCNBillboardAxis.Y
                                userPlane.cornerRadius = 0.5
                                
                                let userPlaneNode = SCNNode(geometry: userPlane)
                                userPlaneNode.constraints = [billboardConstraint]
                                self.buttom(userPlaneNode)
                                
                                // find the profile picture of the adder user
                                let profilePic = user["profilePic"] as? PFFileObject
                                
                                if let profilePic = profilePic {
                                    
                                    profilePic.getDataInBackground {
                                        (imageData: Data?, error: Error?) -> Void in
                                        
                                        if let imageData = imageData {
                                            
                                            userPlane.firstMaterial?.diffuse.contents = UIImage(data: imageData)
                                            
                                            
                                        } else if let error = error {
                                            print(error)
                                        }
                                    }
                                    
                                } else {
                                    
                                    // display a default image for users with no
                                }
                                
                                // find the top of the cassette node
                                userPlaneNode.position = SCNVector3.init(0, 100, 0)
                                
                                
                                userPlaneNode.name = user.objectId
                                userPlaneNode.categoryBitMask = NodeCategories.profilePic.rawValue
                                
                                // follow box
                                let box = SCNBox(width: 0.1, height: 0.04, length: 0.02, chamferRadius: 0.01)
                                box.firstMaterial?.diffuse.contents = UIColor.green
                                box.firstMaterial?.transparency = 0.5
                                let boxNode = SCNNode(geometry: box)
                                boxNode.adjustPivot(to: .center)
                                boxNode.position = SCNVector3Make(-0.04, 0.05, 0)
                                boxNode.name = user.objectId! // the name of the plane node badge is the object id of the user who added it
                                
                                node.addChildNode(userPlaneNode)
                                
                                // determine follow or following or requested
                                var textGeometry: SCNText!
                                PFUser.current()!.followStatus(to: user as! PFUser) {
                                    (status: FollowStatus?, error: Error?) -> Void in
                                    if let status = status {
                                        switch status {
                                        case FollowStatus.notFollowing:
                                            textGeometry = SCNText(string: "Follow",
                                                                   extrusionDepth: 0.01)
                                            boxNode.categoryBitMask = NodeCategories.follow.rawValue
                                            
                                        case FollowStatus.following:
                                            textGeometry = SCNText(string: "Following",
                                                                   extrusionDepth: 0.01)
                                            
                                        case FollowStatus.requested:
                                            textGeometry = SCNText(string: "Requested",
                                                                   extrusionDepth: 0.01)
                                            
                                        case FollowStatus.currentUser:
                                            
                                            return
                                        }
                                    }
                                    userPlaneNode.addChildNode(boxNode)
                                    
                                    textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
                                    textGeometry.font = UIFont(name: "Futura", size: 2.0)
                                    textGeometry.isWrapped = true
                                    textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
                                    textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
                                    textGeometry.firstMaterial?.diffuse.contents = UIColor.white
                                    textGeometry.firstMaterial?.isDoubleSided = true
                                    textGeometry.chamferRadius = CGFloat(0)
                                    
                                    let textNode = SCNNode(geometry: textGeometry)
                                    textNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
                                    //textNode.constraints = [billBoardConstraint]
                                    textNode.adjustPivot(to: .center)
                                    textNode.position = SCNVector3Make(0, 0, 0)
                                    boxNode.addChildNode(textNode)
                                }
                            } else if let error = error {
                                print(error)
                            }
                        }
                    }
                }
            }
            
            // case a messageBottle is tapped
            if (node.categoryBitMask == NodeCategories.messageBottle.rawValue) {
                
                if let id = node.name {
                    
                    let messageBottleQuery = PFQuery(className: "MessageBottle")
                    
                    messageBottleQuery.getObjectInBackground(withId: id) {
                        (object: PFObject?, error: Error?) -> Void in
                        
                        if let messageBottleObject = object {
                            
                            let addedBy = messageBottleObject["addedBy"] as? PFObject
                            let message = messageBottleObject["text"] as? String
                            
                            if let addedBy = addedBy, let message = message {
                                
                                
                                // show the user contents of the bottle
                                addedBy.fetchInBackground {
                                    (object: PFObject?, error: Error?) -> Void in
                                    
                                    if let addedBy = object as? PFUser, let currentUser = PFUser.current() {
                                        
                                        // determine if the bottle is visited by this user before
                                        let visitedBottles = currentUser.relation(forKey: "VisitedBottles")
                                        let visitedBottleQuery = visitedBottles.query()
                                        visitedBottleQuery.whereKey("objectId", equalTo: messageBottleObject.objectId)
                                        visitedBottleQuery.findObjectsInBackground {
                                            (objects: [PFObject]?, error: Error?) -> Void in
                                            
                                            if let _ = objects?.first {

                                                // don't modify user's ar coin
                                                
                                                
                                            } else if error == nil {
                                                visitedBottles.add(messageBottleObject)
                                                currentUser.saveInBackground {
                                                    (succeed: Bool?, error: Error?) -> Void in
                                                    
                                                    if let _ = succeed {
                                                        self.modifyARCoin(CoinTransaction.ReadBottle)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        
                                        let username = addedBy.username!
                                        
                                        let title = "\(username) says:"
                                        
                                        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                        alertMessage.addAction(UIAlertAction(title: "Report Abuse", style: .destructive, handler: {
                                            (action: UIAlertAction) -> Void in
                                            
                                            let reportAbuse = PFObject(className: "ReportAbuse")
                                            let relation = reportAbuse.relation(forKey: "MessageBottle")
                                            relation.add(messageBottleObject)
                                            
                                            reportAbuse.saveInBackground {
                                                (succeed: Bool?, error: Error?) -> Void in
                                                
                                            }
                                        }))
                                        
                                        self.present(alertMessage, animated: true, completion: nil)
                                        
                                        //display info
                                        if let profilePic = addedBy["profilePic"] as? PFFileObject {
                                            
                                            profilePic.getDataInBackground {
                                                (data: Data?, error: Error?) -> Void in
                                                
                                                if let imageData = data {
                                                    
                                                    let userPlane = SCNPlane(width: 0.1, height: 0.1)
                                                    userPlane.firstMaterial?.diffuse.contents = UIImage(data: imageData)
                                                    let billboardConstraint = SCNBillboardConstraint()
                                                    billboardConstraint.freeAxes = SCNBillboardAxis.Y
                                                    userPlane.cornerRadius = 0.05
                                                    
                                                    let userPlaneNode = SCNNode(geometry: userPlane)
                                                    userPlaneNode.constraints = [billboardConstraint]
                                                    self.buttom(userPlaneNode)
                                                    userPlaneNode.position = SCNVector3Make(0, 0, 15)
                                                    userPlaneNode.name = addedBy.objectId
                                                    userPlaneNode.categoryBitMask = NodeCategories.profilePic.rawValue
                                                    
                                                    node.addChildNode(userPlaneNode)
                                                }
                                            }
                                        }
                                        
                                    } else if let _ = error {
                                        
                                        let alertMessage = UIAlertController(title: "Server Error", message: "Could not connect to server. Please try again later.", preferredStyle: .alert)
                                        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                        
                                        self.present(alertMessage, animated: true, completion: nil)
                                    }
                                }
                                
                            }
                            
                        } else if error != nil {
                            
                            let alertMessage = UIAlertController(title: "Server error", message: "Could not connect to server, please try again later", preferredStyle: .alert)
                            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            
                            self.present(alertMessage, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func addInfoPlane(_ node: SCNNode) -> Void {
        let name = node.parent?.name
        let query = PFQuery(className: "IndoorObject")
        query.whereKey("objectId", equalTo: name)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let model = objects?.first {
                let plane = SCNPlane(width: 0.1, height: 0.1)
                let billBoardConstraint = SCNBillboardConstraint()
                billBoardConstraint.freeAxes = SCNBillboardAxis.Y
                plane.cornerRadius = 0.5
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.constraints = [billBoardConstraint]
                self.buttom(planeNode)
                
                // find the userPicture for the plane
                let adder = model["addedBy"] as! PFUser
                adder.fetchInBackground {
                    (user: PFObject?, error: Error?) -> Void in
                    if let user = user {
                        let profilePic = user["profilePic"] as! PFFileObject
                        profilePic.getDataInBackground {
                            (data: Data?, error: Error?) -> Void in
                            if let data = data {
                                let image = UIImage(data: data)
                                plane.firstMaterial?.diffuse.contents = image
                                // find the top of the node
                                let query = PFQuery(className: "Models")
                                let id = model["modelID"] as! String
                                query.whereKey("id", equalTo: id)
                                query.findObjectsInBackground {
                                    (objects: [PFObject]?, error: Error?) -> Void in
                                    if let object = objects?.first {
                                        let scaleWeight = object["indoorScale"] as! Float
                                        _ = SCNVector3Make(scaleWeight, scaleWeight, scaleWeight)
                                        _ = node.boundingSphere.center
                                        let radius = node.boundingSphere.radius * scaleWeight
                                        
                                        var translation = SCNVector3Make(0, 3 * radius ,0)
                                        translation = self.sceneView.scene.rootNode.convertVector(translation, to: node)
                                        var transform = planeNode.transform
                                        transform = SCNMatrix4Translate(transform, translation.x, translation.y, translation.z)
                                        
                                        planeNode.transform = transform
                                        planeNode.name = name
                                        planeNode.categoryBitMask = NodeCategories.infoPlane.rawValue
                                        self.buttom(planeNode)
                                        
                                        // follow box
                                        let box = SCNBox(width: 0.1, height: 0.04, length: 0.02, chamferRadius: 0.01)
                                        box.firstMaterial?.diffuse.contents = UIColor.green
                                        box.firstMaterial?.transparency = 0.5
                                        let boxNode = SCNNode(geometry: box)
                                        boxNode.adjustPivot(to: .center)
                                        boxNode.position = SCNVector3Make(-0.04, 0.05, 0)
                                        boxNode.name = adder.objectId! // the name of the plane node badge is the object id of the user who added it
                                        
                                        node.addChildNode(planeNode)
                                        
                                        // determine follow or following or requested
                                        var textGeometry: SCNText!
                                        PFUser.current()!.followStatus(to: user as! PFUser) {
                                            (status: FollowStatus?, error: Error?) -> Void in
                                            if let status = status {
                                                switch status {
                                                case FollowStatus.notFollowing:
                                                    textGeometry = SCNText(string: "Follow",
                                                                               extrusionDepth: 0.01)
                                                    boxNode.categoryBitMask = NodeCategories.follow.rawValue
                                                    
                                                case FollowStatus.following:
                                                    textGeometry = SCNText(string: "Following",
                                                                           extrusionDepth: 0.01)
                                                    
                                                case FollowStatus.requested:
                                                    textGeometry = SCNText(string: "Requested",
                                                                           extrusionDepth: 0.01)
                                                    
                                                case FollowStatus.currentUser:
                                                    
                                                    return
                                                }
                                            }
                                            planeNode.addChildNode(boxNode)
                                            
                                            textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
                                            textGeometry.font = UIFont(name: "Futura", size: 2.0)
                                            textGeometry.isWrapped = true
                                            textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
                                            textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
                                            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
                                            textGeometry.firstMaterial?.isDoubleSided = true
                                            textGeometry.chamferRadius = CGFloat(0)
                                            
                                            let textNode = SCNNode(geometry: textGeometry)
                                            textNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
                                            //textNode.constraints = [billBoardConstraint]
                                            textNode.adjustPivot(to: .center)
                                            textNode.position = SCNVector3Make(0, 0, 0)
                                            boxNode.addChildNode(textNode)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
         
      func cassetteButtonTapped() {
        stopButton.isEnabled = false
        playButton.isEnabled = false
        insertAudio.isEnabled = false
        
        if let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first {
            
            //display the console
            self.audioConsole.transform = CGAffineTransform.identity
            
            let audioFileURL = directoryURL.appendingPathComponent("cassetteRecording.m4a")
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                
                try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
                
                let recorderSetting: [String:Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                
                audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
            } catch {
                print(error)
            }
            
        } else {
            let alertMessage = UIAlertController(title: "error", message: "Failed to get the document directory of the user. Please try again later.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: {
                // hide the audio console
                
            })
        }
    }
    
    @IBAction func stop(sender: UIButton) {
        recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        playButton.isEnabled = true
        
        audioRecorder?.stop()
        resetTimer()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
    @IBAction func play(sender: UIButton) {
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                audioPlayer = try? AVAudioPlayer(contentsOf: recorder.url)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                startTimer()
            }
        }
    }
    
    @IBAction func record(sender: UIButton) {
        do {
            try self.audioSession?.setCategory(.playAndRecord, options: [.allowBluetooth,
                                                                         .duckOthers,
                                                                         .allowBluetoothA2DP])
            try audioSession?.setActive(true)
        } catch {
            
        }
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
            }
        }
        
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    try audioSession.setActive(true)
                    
                    recorder.record()
                    startTimer()
                    
                    recordButton.setImage(UIImage(named: "Pause"), for: UIControl.State.normal)
                    self.insertAudio.isEnabled = true
                } catch {
                    print(error)
                }
            } else {
                recorder.pause()
                pauseTimer()
                
                recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
            }
        }
        
        stopButton.isEnabled = true
        playButton.isEnabled = false
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let alertMessage = UIAlertController(title: "Finish Recording", message: "Successfully recorded the audio!", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(alertMessage, animated: true, completion: nil)
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {
            (timer) in
            self.elapsedTimeInSeconds += 1
            self.updateTimeLabel()
        })
    }
    
    func pauseTimer() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        timer?.invalidate()
        elapsedTimeInSeconds = 0
        updateTimeLabel()
    }
    
    func updateTimeLabel() {
        let seconds = elapsedTimeInSeconds % 60
        let minutes = (elapsedTimeInSeconds / 60) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @IBAction func insertAudio(sender: UIButton) {
        guard audioRecorder != nil else { return }
        
        do {
            try self.audioSession?.setCategory(.playback, options: [.duckOthers,
                                                                    .allowBluetooth,
                                                                    .allowBluetoothA2DP])
            try audioSession?.setActive(true)
        } catch {
            
        }
        
        // Hide Audio Console
        UIView.animate(withDuration: ButtonsAnimationDuration) {
            self.audioConsole.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
        
        let url = audioRecorder!.url
        let data = try! Data(contentsOf: url)
        
        if let hitResult = self.stickyHitResult, let euler = self.stickyTempEulerAngles, let localPos = self.stickyTempLocalPos {
            /// Show a voice badge on the board and save the data to the server
            let voiceBadge = AudioBadge()
            voiceBadge.rootNode.position = localPos
            voiceBadge.rootNode.eulerAngles = SCNVector3Make(.pi / 2, euler.y, 0)
            
            hitResult.node.addChildNode(voiceBadge.rootNode)
            
            voiceBadge.data = data
            
            if appMode == .portal || appMode == .pinBoard {
                voiceBadge.saveInDB(for: PFUser.current()!) { (succeed, error) in
                    if error == nil {
                        if self.appMode == .pinBoard {
                            self.personalPinBoard?.voiceBadges[voiceBadge.id!] = voiceBadge
                            voiceBadge.isDeletable = true
                        } else if self.appMode == .portal {
                            self.portal?.pinBoard?.voiceBadges[voiceBadge.id!] = voiceBadge
                            if !self.portal!.visiting {
                                voiceBadge.isDeletable = true
                            }
                        }
                        self.stickyTempLocalPos = nil
                        self.stickyHitResult = nil
                        self.stickyTempEulerAngles = nil
                        DispatchQueue.main.async {
                            self.plusButton.interfaceHidden = false
                        }
                    }
                }
            } else {
                voiceBadge.author = PFUser.current()
                voiceBadge.saveInDB(for: currentVenue!) { (id, error) in
                    if error == nil {
                        self.publicPinBoard.first!.voiceBadges[id!] = voiceBadge
                        self.stickyTempLocalPos = nil
                        self.stickyHitResult = nil
                        self.stickyTempEulerAngles = nil
                        DispatchQueue.main.async {
                            self.plusButton.interfaceHidden = false
                        }
                    }
                }
            }
        } else {
            updateQueue.async {
                let cassette = Cassette(location: self.location, author: PFUser.current()!)
                cassette.data = data
                
                self.sceneView.addInfrontOfCamera(node: cassette, at: SCNVector3Make(0, 0, -1))
                
                // Save Cassette in DB
                cassette.saveToDB { (succeeed, error) in
                    // get rid of audio player and audio recorder
                    self.audioPlayer = nil
                    self.audioRecorder = nil
                    self.cassetteViewer?.addedObjects.append(cassette)
                    DispatchQueue.main.async {
                        self.plusButton.interfaceHidden = false
                    }
                }
            }
        }
    }
    
    @IBAction func cancelAudio(sender: UIButton) {
        
        // delete the temp audio file
        
        // reset the timer
        self.resetTimer()
        
        // stop the recorder if recording
        if let recorder = audioRecorder {
            if recorder.isRecording {
                recorder.stop()
            }
            
            recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
            recordButton.isEnabled = true
            playButton.isEnabled = false
            stopButton.isEnabled = false
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                
                try audioSession.setCategory(.playback, options: [.duckOthers,
                                                                  .allowBluetoothA2DP,
                                                                  .allowBluetooth])
                
            } catch {
                print(error)
            }
        }
        
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                
                try audioSession.setCategory(.playback, options: [.duckOthers,
                                                                  .allowBluetoothA2DP,
                                                                  .allowBluetooth])
                
            } catch {
                print(error)
            }
        }
        
        self.audioConsole.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        DispatchQueue.main.async {
            self.plusButton.interfaceHidden = false
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playButton.isSelected = false
        
        let alertMessage = UIAlertController(title: "Finish Playing", message: "Finish Playing the recording", preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alertMessage, animated: true, completion: nil)
        
        resetTimer()
    }
    
    func modifyARCoin(_ coinTransaction: CoinTransaction) {
        
        var sign: String = ""
        let user = PFUser.current()
        let currentCoins = user!["ARCoin"] as! Int
        
        let (amount, description) = transaction(coinTransaction)
        
        if (amount > 0) {
            
            sign = "+"
            self.coinModificationLabel.textColor = UIColor.green
            self.transactionNotificationLabel.textColor = UIColor.green
        } else {
            
            self.coinModificationLabel.textColor = UIColor.red
            self.transactionNotificationLabel.textColor = UIColor.red
        }
        
        self.coinModificationLabel.text = "\(sign)\(amount)"
        self.transactionNotificationLabel.text = description
        
        let when = DispatchTime.now() + 3
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            self.coinModificationLabel.text = ""
            self.transactionNotificationLabel.text = ""
            
            let newCoins = currentCoins + amount
            user!["ARCoin"] = newCoins
            
            user!.saveInBackground {
                (succeed: Bool?, error: Error?) -> Void in
                
                if let _ = succeed {
                    
                    self.arCoinLabel.text = String(newCoins)
                }
            }
        }
        
    }
    
    // MARK: - AR Temple
    
    func activatePublicPinBoard() {
        guard currentVenue == nil && !updatingVenue && appMode == .normal && personalPinBoard == nil && story == nil else { return }
        
        updatingVenue = true
        /// Check if the current position is stored in the database
        getCurrentVenue { (venue: Venue?, error: Error?) -> Void in
            if error == nil {
                if let venue = venue {
                    // show ar temple corresponding to this venue

                    if let plane = SurfacePlane.planes.sorted(by: { $0.position.y < $1.position.y }).first, plane.planeAnchor?.alignment == .horizontal {
                        let position = plane.position
                        
                        // Place AR Temple on this plane
                        let publicPinBoard = PinBoardPublic(venue)
                        self.currentVenue = venue
                        self.publicPinBoard.append(publicPinBoard)
                        
                        publicPinBoard.initializePinBoardNode({ (node) in
                            if let pinBoardNode = node {
                                pinBoardNode.position = position
                                pinBoardNode.eulerAngles = SCNVector3Make(-.pi / 2, 0, 0)
                                
                                DispatchQueue.main.async {
                                    if let yaw = self.session.currentFrame?.camera.eulerAngles.y {
                                        pinBoardNode.eulerAngles.y = (yaw)
                                    }
                                    DispatchQueue.main.async {
                                        self.sceneView.scene.rootNode.addChildNode(pinBoardNode)
                                        self.updatingVenue = false
                                    }
                                }
                            }
                        })
                    } else {
                        self.updatingVenue = false
                    }
                }
            } else {
                // server error; failed to establish venue
            }
        }
    }
    
    func getCurrentVenue(_ completion: @escaping (_ venue: Venue?, _ error: Error?) -> Void) {
        guard locationManager.location != nil else { return }
        
        let currentGeoPoint = PFGeoPoint(location: locationManager.location)
        
        let venueQuery = PFQuery(className: "Venue")
        
        venueQuery.whereKey("location", nearGeoPoint: currentGeoPoint, withinKilometers: 0.1)
        
        venueQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let venueObject = objects?.first {
                    // Venue is already in the database
                    let venueGeoPoint = venueObject["location"] as! PFGeoPoint
                    let venueID = venueObject.objectId!
                    
                    let venue = Venue(id: venueID, geoPoint: venueGeoPoint)
                    completion(venue, nil)
                } else {
                    // Create a new venue in the db for this geopoint
                    let venueObject = PFObject(className: "Venue")
                    venueObject["location"] = currentGeoPoint
                    venueObject.saveInBackground { (succeed: Bool?, error: Error?) -> Void in
                        if error == nil {
                            if succeed == true {
                                // Venue saved in db
                                let venue = Venue(id: venueObject.objectId!, geoPoint: currentGeoPoint)
                                completion(venue, nil)
                            }
                        } else {
                            // Server Connection error
                            completion(nil, error)
                        }
                    }
                }
            } else {
                // server connection error
                completion(nil, error)
            }
        }
    }
    /*
    func addNearOutsideModels(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) -> Void {
        
        let nearQuery = PFQuery(className: "OutdoorObject")
        
        if let currentLocation = self.location, let currentHeading = self.userHeading, let camera = sceneView.pointOfView {
            
            let currentGeoPoint = PFGeoPoint(location: currentLocation)
            
            nearQuery.whereKey("location", nearGeoPoint: currentGeoPoint)
            
            nearQuery.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error {
                    completion(nil, error)
                } else if var nearObjects = objects {
                    
                    nearObjects = nearObjects.filter {
                        (object: PFObject) -> Bool in
                        
                        let objectGeoPoint = object["location"] as! PFGeoPoint
                        let objectLocation = CLLocation(latitude: objectGeoPoint.latitude, longitude: objectGeoPoint.longitude)
                        let distance = currentLocation.distance(from: objectLocation)
                        
                        if (distance < ObjectsRadius) {
                            return true
                        }
                        return false
                    }
                    
                    for nearObject in nearObjects {
                        
                        let node = self.sceneView.scene.rootNode.childNode(withName: nearObject.objectId!, recursively: true)
                        
                        if let node = node {
                            
                            if node.categoryBitMask == NodeCategories.skySticker.rawValue {
                                
                                node.removeFromParentNode()
                                
                                let nearModel = NearModel(forObject: nearObject)
                                
                                nearModel.getModel() {
                                    (succeed: Bool?, error: Error?) -> Void in
                                    
                                    if let _ = succeed {
                                        
                                        let virtualObject = nearModel.virtualObject
                                        let objectNode = virtualObject?.getNode()
                                        
                                        let currentNode = camera.clone()
                                        currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                                        let position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: nearModel.location)
                                        
                                        objectNode?.position = (currentNode.convertPosition(position, to: self.sceneView.scene.rootNode))
                                        objectNode?.name = nearObject.objectId
                                        objectNode?.categoryBitMask = NodeCategories.outsideModel.rawValue
                                        objectNode?.scale = (virtualObject?.scale)!
                                        
                                        self.sceneView.scene.rootNode.addChildNode(objectNode!)
                                        
                                        nearModel.isDisplayed = true
                                        
                                    }
                                }
                            }
                        } else {
                            
                            let nearModel = NearModel(forObject: nearObject)
                            
                            nearModel.getModel() {
                                (succeed: Bool?, error: Error?) -> Void in
                                
                                if let _ = succeed {
                                    
                                    let virtualObject = nearModel.virtualObject
                                    let objectNode = virtualObject?.getNode()
                                    
                                    let currentNode = camera.clone()
                                    currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                                    let position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: nearModel.location)
                                    
                                    objectNode?.position = (currentNode.convertPosition(position, to: self.sceneView.scene.rootNode))
                                    objectNode?.name = nearObject.objectId
                                    objectNode?.categoryBitMask = NodeCategories.outsideModel.rawValue
                                    objectNode?.scale = (virtualObject?.scale)!
                                    
                                    self.sceneView.scene.rootNode.addChildNode(objectNode!)
                                    
                                    nearModel.isDisplayed = true
                                    
                                }
                            }
                        }
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    func addSkyStickers(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) -> Void {
        
        let farQuery = PFQuery(className: "OutdoorObject")
        
        if let currentLocation = self.location, let currentHeading = self.userHeading, let camera = sceneView.pointOfView {
            
            let currentGeoPoint = PFGeoPoint(location: currentLocation)
            
            farQuery.whereKey("location", nearGeoPoint: currentGeoPoint)
            
            farQuery.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error {
                    completion(nil, error)
                } else if var farObjects = objects {
                    
                    farObjects = farObjects.filter {
                        (object: PFObject) -> Bool in
                        
                        let objectGeoPoint = object["location"] as! PFGeoPoint
                        let objectLocation = CLLocation(latitude: objectGeoPoint.latitude, longitude: objectGeoPoint.longitude)
                        let distance = currentLocation.distance(from: objectLocation)
                        
                        if (distance > ObjectsRadius && distance < BannersRadius) {
                            return true
                        }
                        return false
                    }
                    
                    for farObject in farObjects {
                        
                        let node = self.sceneView.scene.rootNode.childNode(withName: farObject.objectId!, recursively: true)
                        
                        if let node = node {
                            
                            if node.categoryBitMask == NodeCategories.outsideModel.rawValue {
                                
                                node.removeFromParentNode()
                                
                                let targetLocation = farObject["location"] as? PFGeoPoint
                                let targetUser = farObject["addedBy"] as? PFObject
                                
                                if let targetLocation = targetLocation, let targetUser = targetUser {
                                    
                                    let location = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
                                    let distance = currentLocation.distance(from: location)
                                    let scalingFactor = self.getScalingFactor(distance)
                                    let skySticker = SkySticker(forUser: targetUser, forObject: farObject, scalingFactor: scalingFactor)
                                    var position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: location)
                                    let currentNode = camera.clone()
                                    currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                                    position.y = Float(10 * scalingFactor)
                                    skySticker.node.categoryBitMask = NodeCategories.skySticker.rawValue
                                    skySticker.node.name = farObject.objectId!
                                    skySticker.node.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                                    
                                    self.sceneView.scene.rootNode.addChildNode(skySticker.node)
                                }
                            }
                        } else {
                            
                            let targetLocation = farObject["location"] as? PFGeoPoint
                            let targetUser = farObject["addedBy"] as? PFObject
                            
                            if let targetLocation = targetLocation, let targetUser = targetUser {
                                
                                let location = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
                                let distance = currentLocation.distance(from: location)
                                let scalingFactor = self.getScalingFactor(distance)
                                let skySticker = SkySticker(forUser: targetUser, forObject: farObject, scalingFactor: scalingFactor)
                                var position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: location)
                                let currentNode = camera.clone()
                                currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                                position.y = Float(10 * scalingFactor)
                                skySticker.node.categoryBitMask = NodeCategories.skySticker.rawValue
                                skySticker.node.name = farObject.objectId!
                                skySticker.node.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                                
                                self.sceneView.scene.rootNode.addChildNode(skySticker.node)
                            }
                        }
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    func addNearCassettes (_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) -> Void {
        /*
        let nearQuery = PFQuery(className: "Cassette")
        
        if let currentLocation = self.location, let currentHeading = self.userHeading, let camera = sceneView.pointOfView {
            
            let currentGeoPoint = PFGeoPoint(location: currentLocation)
            
            nearQuery.whereKey("location", nearGeoPoint: currentGeoPoint)
            
            nearQuery.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error {
                    completion(nil, error)
                } else if var nearObjects = objects {
                    
                    nearObjects = nearObjects.filter {
                        (object: PFObject) -> Bool in
                        
                        let objectGeoPoint = object["location"] as! PFGeoPoint
                        let objectLocation = CLLocation(latitude: objectGeoPoint.latitude, longitude: objectGeoPoint.longitude)
                        let distance = currentLocation.distance(from: objectLocation)
                        
                        if (distance < ObjectsRadius) {
                            
                            return true
                        }
                        return false
                    }
                    
                    for nearObject in nearObjects {
                        
                        let node = self.sceneView.scene.rootNode.childNode(withName: nearObject.objectId!, recursively: true)
                        
                        if let node = node {
                            
                            if node.categoryBitMask == NodeCategories.whisper.rawValue {
                                
                                node.removeFromParentNode()
                                
                                let cassetteNode = try! self.nodeForScene("Cassette.scn")
                                cassetteNode.scale = SCNVector3.init(0.002, 0.002, 0.002)
                                cassetteNode.eulerAngles = SCNVector3.init((Double.pi / 2), 0, 0)
                                
                                let objectGeopoint = nearObject["location"] as! PFGeoPoint
                                
                                cassetteNode.name = nearObject.objectId
                                cassetteNode.categoryBitMask = NodeCategories.cassette.rawValue
                                
                                let objectLocation = CLLocation.init(latitude: objectGeopoint.latitude, longitude: objectGeopoint.longitude)
                                let position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: objectLocation)
                                
                                let currentNode = camera.clone()
                                currentNode.eulerAngles = SCNVector3Make(0, camera.eulerAngles.y, 0)
                                cassetteNode.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                                
                                self.sceneView.scene.rootNode.addChildNode(cassetteNode)
                            }
                        } else {
                            
                            let cassetteNode = try! self.nodeForScene("Cassette.scn")
                            cassetteNode.scale = SCNVector3.init(0.002, 0.002, 0.002)
                            cassetteNode.eulerAngles = SCNVector3.init((Double.pi / 2), 0, 0)
                            
                            let objectGeopoint = nearObject["location"] as! PFGeoPoint
                            
                            cassetteNode.name = nearObject.objectId
                            cassetteNode.categoryBitMask = NodeCategories.cassette.rawValue
                            
                            let objectLocation = CLLocation.init(latitude: objectGeopoint.latitude, longitude: objectGeopoint.longitude)
                            let position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: objectLocation)
                            
                            let currentNode = camera.clone()
                            currentNode.eulerAngles = SCNVector3Make(0, camera.eulerAngles.y, 0)
                            cassetteNode.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                            
                            self.sceneView.scene.rootNode.addChildNode(cassetteNode)
                        }
                    }
                    completion(true, nil)
                }
            }
        }
 */
    }
    
    func addWhispers(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) -> Void {
        /*
        
        let farQuery = PFQuery(className: "Cassette")
        
        if let currentLocation = self.location, let currentHeading = self.userHeading, let camera = self.cameraNode {
            
            let currentGeoPoint = PFGeoPoint(location: currentLocation)
            
            farQuery.whereKey("location", nearGeoPoint: currentGeoPoint)
            
            farQuery.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error {
                    completion(nil, error)
                } else if var farObjects = objects {
                    
                    farObjects = farObjects.filter {
                        (object: PFObject) -> Bool in
                        
                        let objectGeoPoint = object["location"] as! PFGeoPoint
                        let objectLocation = CLLocation(latitude: objectGeoPoint.latitude, longitude: objectGeoPoint.longitude)
                        let distance = currentLocation.distance(from: objectLocation)
                        
                        if (distance > ObjectsRadius && distance < BannersRadius) {
                            
                            return true
                        }
                        return false
                    }
                    
                    for farObject in farObjects {
                        
                        let node = self.sceneView.scene.rootNode.childNode(withName: farObject.objectId!, recursively: true)
                        
                        if let node = node {
                            
                            if node.categoryBitMask == NodeCategories.cassette.rawValue {
                                
                                node.removeFromParentNode()
                                
                                let addedBy = farObject["addedBy"] as! PFObject
                                let geoPoint = farObject["location"] as! PFGeoPoint
                                
                                let location = CLLocation.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                                let distance = currentLocation.distance(from: location)
                                let scalingFactor = self.getScalingFactor(distance)
                                
                                let whisper = Whisper(forUser: addedBy, forObject: farObject, scalingFactor: scalingFactor)
                                
                                var position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: location)
                                
                                let currentNode = camera.clone()
                                position.y = Float(20 * scalingFactor)
                                currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                                
                                whisper.node.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                                whisper.node.name = farObject.objectId!
                                whisper.node.categoryBitMask = NodeCategories.whisper.rawValue
                                
                                self.sceneView.scene.rootNode.addChildNode(whisper.node)
                            }
                        } else {
                            
                            let addedBy = farObject["addedBy"] as! PFObject
                            let geoPoint = farObject["location"] as! PFGeoPoint
                            
                            let location = CLLocation.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                            let distance = currentLocation.distance(from: location)
                            let scalingFactor = self.getScalingFactor(distance)
                            
                            let whisper = Whisper(forUser: addedBy, forObject: farObject, scalingFactor: scalingFactor)
                            
                            var position = getPosition(userLocation: currentLocation, userHeading: currentHeading, to: location)
                            
                            let currentNode = camera.clone()
                            position.y = Float(20 * scalingFactor)
                            currentNode.eulerAngles = SCNVector3.init(x: 0, y: camera.eulerAngles.y, z: 0)
                            
                            whisper.node.position = currentNode.convertPosition(position, to: self.sceneView.scene.rootNode)
                            whisper.node.name = farObject.objectId!
                            whisper.node.categoryBitMask = NodeCategories.whisper.rawValue
                            
                            self.sceneView.scene.rootNode.addChildNode(whisper.node)
                        }
                    }
                    completion(true, nil)
                }
            }
        }
 */
    }
    */
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        switch textField.tag {
            
        case MainView.SkyWritingText.rawValue:
            let newLength = ((textField.text?.utf16.count)! + string.utf16.count - range.length)
            //change the value of the label
            self._addTextFieldNoCharacters.text =  String(newLength)
            //you can save this value to a global var
            //myCounter = newLength
            //return true to allow the change, if you want to limit the number of characters in the text field use something like
            return newLength <= 21 // To just allow up to 25 characters
            
        case MainView.VenueNameField.rawValue:
            let newLength = ((textField.text?.utf16.count)! + string.utf16.count - range.length)
            //change the value of the label
            let characterCounter = self.view.viewWithTag(MainView.VenueNameCharacterCounter.rawValue) as! UILabel
            characterCounter.text =  "\(newLength)/20"
            //you can save this value to a global var
            //myCounter = newLength
            //return true to allow the change, if you want to limit the number of characters in the text field use something like
            return newLength <= 20 // To just allow up to 25 characters
            
        default:
            return true
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        switch textField.tag {
            
        case MainView.SkyWritingText.rawValue:
             self._addTextFieldNoCharacters.text = String(0)
             
        case MainView.VenueNameField.rawValue:
            let venueNameCharacterCounter = self.view.viewWithTag(MainView.VenueNameCharacterCounter.rawValue) as! UILabel
            venueNameCharacterCounter.text = "0/20"
            
        default:
            return
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        print("screen touched")
        if let touch = touches.first {
            
            let maximumForce = touch.maximumPossibleForce
            let force = touch.force
            let normalizedForce = (force / maximumForce)
            
            if normalizedForce > 0.4 {
                
                let sceneView = touch.view as! ARWorldView
                let touchLocation = touch.location(in: sceneView)
                
                let hitResults = sceneView.hitTest(touchLocation, options: [:])
                
                if !hitResults.isEmpty {
                    
                    guard let hitResult = hitResults.first else {
                        return
                    }
                    
                    let node = hitResult.node
                    
                    if (node.categoryBitMask == NodeCategories.profilePic.rawValue || node.categoryBitMask == NodeCategories.cassette.rawValue || node.categoryBitMask == NodeCategories.skyWriting.rawValue || node.categoryBitMask == NodeCategories.tableCassette.rawValue) {
                        
                        let alertMessage = UIAlertController(title: "Inapropriate?", message: "Report abuse if this instance violated our community guidline.", preferredStyle: .alert)
                        alertMessage.addAction(UIAlertAction(title: "Report abuse", style: .destructive, handler: {
                            (action: UIAlertAction) -> Void in
                            
                            if let id = node.name {
                                
                                switch node.categoryBitMask {
                                    
                                case NodeCategories.profilePic.rawValue:
                                    
                                    let userQuery = PFUser.query()
                                    userQuery?.getObjectInBackground(withId: id) {
                                        (object: PFObject?, error: Error?) -> Void in
                                        
                                        if let user = object {
                                            
                                            let reportAbuse = PFObject(className: "ReportAbuse")
                                            let relation = reportAbuse.relation(forKey: "User")
                                            relation.add(user)
                                            
                                            reportAbuse.saveInBackground {
                                                (succeed: Bool?, error: Error?) -> Void in
                                                
                                            }
                                        }
                                    }
                                case NodeCategories.cassette.rawValue:
                                    
                                    let cassetteQuery = PFQuery(className: "Cassette")
                                    cassetteQuery.getObjectInBackground(withId: id) {
                                        (object: PFObject?, error: Error?) ->  Void in
                                        
                                        if let cassetteObject = object {
                                            
                                            let reportAbuse = PFObject(className: "ReportAbuse")
                                            let relation = reportAbuse.relation(forKey: "Cassette")
                                            relation.add(cassetteObject)
                                            
                                            reportAbuse.saveInBackground {
                                                (succeed: Bool?, error: Error?) -> Void in
                                                
                                            }
                                        }
                                    }
                                    
                                case NodeCategories.tableCassette.rawValue:
                                    
                                    let tableCassetteQuery = PFQuery(className: "TableCassette")
                                    tableCassetteQuery.getObjectInBackground(withId: id) {
                                        (object: PFObject?, error: Error?) -> Void in
                                        
                                        if let tableCassetteObject = object {
                                            
                                            let reportAbuse = PFObject(className: "ReportAbuse")
                                            let relation = reportAbuse.relation(forKey: "TableCassette")
                                            relation.add(tableCassetteObject)
                                            
                                            reportAbuse.saveInBackground {
                                                (succeed: Bool?, error: Error?) -> Void in
                                                
                                            }
                                        }
                                    }
                                    
                                case NodeCategories.skyWriting.rawValue:
                                    
                                    let textQuery = PFQuery(className: "text")
                                    textQuery.getObjectInBackground(withId: id) {
                                        (object: PFObject?, error: Error?) -> Void in
                                        
                                        if let textObject = object {
                                            
                                            let reportAbuse = PFObject(className: "ReportAbuse")
                                            let relation = reportAbuse.relation(forKey: "SkyWriting")
                                            relation.add(textObject)
                                            
                                            reportAbuse.saveInBackground {
                                                (succeed: Bool?, error: Error?) -> Void in
                                                
                                            }
                                        }
                                    }
                                    
                                default:
                                    return
                                }
                            }
                        }))
                        alertMessage.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                        
                        self.present(alertMessage, animated: true, completion: nil)
                    }
                }

            }
        }
    }
 
    func refreshNotifications() {
        
        if let notification = self.notification {
            notification.fetchFollowRequests {
                (succeed: Bool?, error: Error?) -> Void in
                if let _ = succeed {
                    
                    self._profilePic.isEnabled = true
                    if notification.totalFollowRequests != 0 {
                        self._totalNotifications.text = String(notification.totalFollowRequests)
                        self._totalNotifications.clipsToBounds = true
                        self._totalNotifications.sizeToFit()
                        self._totalNotifications.layer.cornerRadius = self._totalNotifications.frame.height / 2
                    } else {
                        
                        self._totalNotifications.text = ""
                    }
                }
            }
        }
    }
    
    func getChannelNames() -> [String] {
        
        let audioSession = self.audioSession
        let route = audioSession?.currentRoute
        let outputPorts = route?.outputs
        
        var channels = [String]()
        
        for outputPort in outputPorts! {
            
            for channel in outputPort.channels! {
                
                channels.append(channel.channelName)
            }
 
        }
        
        return channels
    }
    
    func setSpeechSynthesizer(_ speechSynthesizer: AVSpeechSynthesizer, toChannels: [String]) {
        
        let session = self.audioSession
        let route = session?.currentRoute
        let outputPorts = route?.outputs
        var channelDescriptions = [AVAudioSessionChannelDescription]()
        
        for channelName in toChannels {
            
            for outputPort in outputPorts! {
                
                for channel in outputPort.channels! {
                    
                    if channel.channelName == channelName {
                        
                        channelDescriptions.append(channel)
                    }
                }
            }
        }
        
        if !channelDescriptions.isEmpty {
            print("found channels")
            speechSynthesizer.outputChannels = channelDescriptions
        }
    }
    
    func enableSpeech(robot: Robot) { /*
        
        robot.setupSound()
        let channels = self.getChannelNames()
        self.setSpeechSynthesizer(robot.synthesizer, toChannels: channels)
  */  }
    
    @objc func showMyProfile(sender: UIButton) {
        
        performSegue(withIdentifier: "MainToSelfProfile", sender: self)
    }
    
    func addDock() {
        dock.delegate = self
        view.addSubview(dock)
        
        dock.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = NSLayoutConstraint(item: dock, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: dock.collapsedX)
        dock.constraint = leading
        let centerHorizontally = NSLayoutConstraint(item: dock, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        view.addConstraint(leading)
        view.addConstraint(centerHorizontally)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func cancelAddVenue() {
        
        guard let form = self.view.viewWithTag(MainView.AddVenueForm.rawValue) else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            form.transform = CGAffineTransform.init(translationX: 0, y: 700)
        }, completion: {
            (succeed) in
            form.removeFromSuperview()
            self.dock.buttons[2].isEnabled = true
        })
    }
    
    // MARK: - Dock Action Methods
    
    @objc func sandboxTapped(sender: UIButton) {
        
        // Show status message
        statusViewController.showMessage("Sandbox - Tap to return", autoHide: false)
        
        // change app mode
        appMode = .sandbox
        
        // Get rid of any additional Default mode resources
        //_vn.isHidden = true
        arCoinLabel.isHidden = true
        coinIcon.isHidden = true
        _profilePic.isHidden = true
        
        // show options dock
        let sandboxDock = InventoryDock()
        sandboxDock.inventoryDelegate = self
        sandboxDock.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sandboxDock)
        sandboxDock.state = .expanded
        
        // Add the focus square
        self.focusSquare = FocusSquare()
        
        sandboxNodes = []
        
        optionsDock = sandboxDock
        targetingSticky = false
        targetingTemple = false
        removePopUpViews()
        DispatchQueue.main.async {
            SurfacePlane.generateInfinitePlane()
        }
    }
    
    func exitSandboxMode() {
        // Hide the right dock
        optionsDock?.hide()
        optionsDock?.removeFromSuperview()
        optionsDock = nil
        
        // Show profile ar coin ...
        //_vn.isHidden = false
        arCoinLabel.isHidden = false
        coinIcon.isHidden = false
        _profilePic.isHidden = false
        
        updateQueue.async {
            // hide the focus square
            self.focusSquare?.removeFromParentNode()
            self.focusSquare = nil
            
            self.sandboxNodes?.forEach { $0.removeFromParentNode() }
            self.sandboxNodes = nil
        }
        // enter normal app mode
        self.appMode = .normal
        
        DispatchQueue.main.async {
            SurfacePlane.infinitePlane?.restoreRealTransform()
            SurfacePlane.infinitePlane = nil
        }
    }
    
    @objc func chestTapped(sender: UIButton) {
        // Show Chest View Controller
        let chestViewController: ChestViewController = buildFromStoryboard("Main")
        
        addChild(chestViewController)
        
        let chestView = chestViewController.view!
        
        view.addSubview(chestView)
        chestView.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: chestView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: chestView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: chestView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.7, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: chestView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
        
        view.addConstraints([centerHorizontally,
                             centerVertically,
                             widthConstraint,
                             heightConstraint])
        
        self.chestViewController = chestViewController
        
        chestViewController.didMove(toParent: self)
    }
    
    @objc func treasureIconTapped() {
        // Show Chest View Controller
        let treasureViewController: TreasureViewController = buildFromStoryboard("Main")
        
        addChild(treasureViewController)
        
        let treasureView = treasureViewController.view!
        
        view.addSubview(treasureView)
        treasureView.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: treasureView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: treasureView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: treasureView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.7, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: treasureView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
        
        view.addConstraints([centerHorizontally,
                             centerVertically,
                             widthConstraint,
                             heightConstraint])
        
        treasureViewController.didMove(toParent: self)
    }
    
    @objc func mainStoreButtonTapped() {
        // Display gift form
        addChild(mainStoreViewController)
        mainStoreViewController.delegate = self
        
        // Setup constraints for the form view
        let formView = mainStoreViewController.view!
        
        view.addSubview(formView)
        
        formView.translatesAutoresizingMaskIntoConstraints = false
        formView.alpha = 0.6
        
        let centerHorizontally = NSLayoutConstraint(item: formView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: formView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: formView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.7, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: formView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
        
        view.addConstraints([centerHorizontally,
                             centerVertically,
                             widthConstraint,
                             heightConstraint])
        
        mainStoreViewController.didMove(toParent: self)
    }
    
    @objc func arPortalTapped() {
        // Initialize ARPortal
        self.appMode = .portal
        SurfacePlane.planes.forEach { ($0.isHidden = true) }
        shouldDetectPlanes = false
        if portal == nil {
            portal = ARPortal(user: PFUser.current()!)
            portal?.delegate = self
        }
        portal?.state = .preview
        portal?.visiting = false
        portal?.setupPreview({ (preview) in
            DispatchQueue.main.async {
                self.sceneView.scene.rootNode.addChildNode(preview!)
            }
        })
        // Set Portal Mode Status
        statusViewController.showMessage("Portal Mode - Tap To Close", autoHide: false)
        targetingSticky = false
        targetingTemple = false
        removePopUpViews()
    }
    
    func exitPortalMode() {
        guard portal != nil else { return }
        
        SurfacePlane.planes.forEach { $0.isHidden = false }
        hidePortalDock()
        portal!.close()
        appMode = .normal
        if let dartGame = self.currentDartGame {
            dartGame.equippedDart?.removeFromParentNode()
            dartGame.reticle?.removeFromSuperview()
        }
        self.currentDartGame = nil
        portal = nil
        shouldDetectPlanes = true
    }
    
    @objc func creditsTapped() {
        addChild(creditsViewController)
        let creditsView = creditsViewController.view!
        view.addSubview(creditsView)
        creditsView.translatesAutoresizingMaskIntoConstraints = false
        creditsView.layer.cornerRadius = 10
        
        let widthConstraint = NSLayoutConstraint(item: creditsView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.7, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: creditsView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: creditsView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: creditsView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        
        view.addConstraints([widthConstraint,
                             heightConstraint,
                             centerHorizontally,
                             centerVertically])
        
        creditsViewController.didMove(toParent: self)
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    func updateFocusSquare() {
        guard let focusSquare = self.focusSquare else { return }
        
        if let modelHitTest = self.sceneView.modelHitTestWithPhysics(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(focusSquare)
                let camera = self.session.currentFrame?.camera
                focusSquare.state = .detecting(hitTestResult: .object(modelHitTest: modelHitTest), camera: camera)
            }
        } else if let surfacePlaneHitTest = self.sceneView.surfacePlaneHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(focusSquare)
                let camera = self.session.currentFrame?.camera
                focusSquare.state = .detecting(hitTestResult: .object(modelHitTest: surfacePlaneHitTest), camera: camera)
            }
        }
        
        else if let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(focusSquare)
                let camera = self.session.currentFrame?.camera
                focusSquare.state = .detecting(hitTestResult: .arHitTest(hitTestResult: result), camera: camera)
            }
        } else {
            updateQueue.async {
                focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(focusSquare)
            }
            return
        }
        
    }
    
    
    func setupAudioSession() {
        do {
            
            audioSession = AVAudioSession.sharedInstance()
            try self.audioSession?.setCategory(.playback, options: [.duckOthers,
                                                                    .allowBluetoothA2DP,
                                                                    .allowBluetooth])
            try audioSession?.setActive(true)
            
        } catch {
            print(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildFromStoryboard<T>(_ name: String) -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let identifier = String(describing: T.self)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("Missing \(identifier) in Storyboard")
        }
        return viewController
    }
    
    // MARK: - Display UI
    private func initHSBColorPickerView() {
        hsbColorPickerView = HSBColorPicker()
        hsbColorPickerView.delegate = self
        hsbColorPickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hsbColorPickerView)
        
        let centerHorizontally = NSLayoutConstraint(item: hsbColorPickerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: hsbColorPickerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let aspectRatio = NSLayoutConstraint(item: hsbColorPickerView, attribute: .width, relatedBy: .equal, toItem: hsbColorPickerView, attribute: .height, multiplier: 1, constant: 0)
        
        var widthConstraint: NSLayoutConstraint?
        
        if view.traitCollection.verticalSizeClass == .regular {
            widthConstraint = NSLayoutConstraint(item: hsbColorPickerView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.4, constant: 0)
        } else {
            widthConstraint = NSLayoutConstraint(item: hsbColorPickerView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 0)
        }
        
        hsbColorPickerView.addConstraint(aspectRatio)
        view.addConstraints([centerHorizontally,
                             centerVertically,
                             widthConstraint!])
        
        hsbColorPickerView.setNeedsDisplay()
        
        hsbColorPickerView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
    }
    private func initColorPickerView() {
        colorPicker = UIColorPickerView()
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPicker)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(colorPickerTapped))
        colorPicker.addGestureRecognizer(tapGestureRecognizer)
        
        let trailingConstraint = NSLayoutConstraint(item: colorPicker, attribute: .trailing, relatedBy: .equal, toItem: sceneView, attribute: .trailing, multiplier: 1, constant: -20)
        let widthConstraint = NSLayoutConstraint(item: colorPicker, attribute: .width, relatedBy: .equal, toItem: sceneView, attribute: .width, multiplier: 0.2, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: colorPicker, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: -20)
        let aspectRatio = NSLayoutConstraint(item: colorPicker, attribute: .width, relatedBy: .equal, toItem: colorPicker, attribute: .height, multiplier: 1, constant: 0)
        
        colorPicker.addConstraint(aspectRatio)
        view.addConstraints([trailingConstraint, widthConstraint, bottomConstraint])
        colorPicker.setNeedsDisplay()
        
        colorPicker.transform = CGAffineTransform.init(scaleX: 0, y: 0)
    }
    @objc func colorPickerTapped() {
        if isPickingColor {
            hideHSBColorPicker()
            sprayCan.color = colorPicker.color
            isPickingColor = false
        } else {
            showHSBColorPickerView()
            isPickingColor = true
        }
    }
    private func showHSBColorPickerView() {
        DispatchQueue.main.async {
            self.hsbColorPickerView.transform = CGAffineTransform.identity
        }
    }
    private func hideHSBColorPicker() {
        DispatchQueue.main.async {
            self.hsbColorPickerView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
    }
    private func initGraffitiUI() {
        graffitiUIView = GraffitiUIView()
        graffitiUIView.delegate = self
        view.addSubview(graffitiUIView)
        graffitiUIView.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: graffitiUIView, attribute: .centerX, relatedBy: .equal, toItem: sceneView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: graffitiUIView, attribute: .width, relatedBy: .equal, toItem: sceneView, attribute: .width, multiplier: 0.2, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: graffitiUIView, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: -10)
        let aspectRatio = NSLayoutConstraint(item: graffitiUIView, attribute: .width, relatedBy: .equal, toItem: graffitiUIView, attribute: .height, multiplier: 0.5, constant: 0)
        
        graffitiUIView.addConstraint(aspectRatio)
        view.addConstraints([centerHorizontally, widthConstraint, bottomConstraint])
        
        //graffitiUIView.setNeedsDisplay()
        
        graffitiUIView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
    }
    
    private func showGraffitiUI() {
        DispatchQueue.main.async {
            self.hidePlusButton()
            self.plusButton.interfaceHidden = true
            self.sprayCan.equip()
            self.sprayCan.playShakeSound()
            self.graffitiUIView.transform = CGAffineTransform.identity
            self.boardIndicatorView.transform = CGAffineTransform.identity
            self.colorPicker.transform = CGAffineTransform.identity
        }
    }
    
    private func hideGraffitiUI() {
        DispatchQueue.main.async {
            self.plusButton.interfaceHidden = false
            self.sprayCan.holster()
            self.graffitiUIView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
            self.boardIndicatorView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
            self.colorPicker.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
    }
    private func showPlusButton() {
        view.addSubview(plusButton)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        let centerVertically = NSLayoutConstraint(item: plusButton, attribute: .centerX, relatedBy: .equal, toItem: sceneView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: plusButton, attribute: .centerY, relatedBy: .equal, toItem: sceneView, attribute: .centerY, multiplier: 1, constant: 0)
        
        let aspectRatio = NSLayoutConstraint(item: plusButton, attribute: .width, relatedBy: .equal, toItem: plusButton, attribute: .height, multiplier: 1, constant: 0)
        plusButton.addConstraint(aspectRatio)
        
        let widthConstraint = NSLayoutConstraint(item: plusButton, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.07, constant: 0)
        
        view.addConstraints([centerVertically,
                             centerHorizontally,
                             widthConstraint])
        
        plusButton.addTarget(self, action: #selector(showRadialMenue), for: .touchUpInside)
    }
    private func showCompassBar() {
        view.addSubview(compassBar)
        compassBar.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: compassBar, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 25)
        let centerHorizontally = NSLayoutConstraint(item: compassBar, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: compassBar, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.6, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: compassBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        
        view.addConstraints([topConstraint,
                             centerHorizontally,
                             widthConstraint])
        compassBar.addConstraint(heightConstraint)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    @objc private func showRadialMenue() {
        // Hide Plus Button
        plusButton.interfaceHidden = true
        hidePlusButton()
        
        view.addSubview(radialMenue)
        radialMenue.delegate = self
        radialMenue.translatesAutoresizingMaskIntoConstraints = false
        radialMenue.backgroundColor = UIColor.clear
        radialMenue.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        let centerVertically = NSLayoutConstraint(item: radialMenue, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: radialMenue, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        
        let aspectRatio = NSLayoutConstraint(item: radialMenue, attribute: .width, relatedBy: .equal, toItem: radialMenue, attribute: .height, multiplier: 1, constant: 0)
        radialMenue.addConstraint(aspectRatio)
        
        if view.traitCollection.horizontalSizeClass == .compact {
            let widthConstraint = NSLayoutConstraint(item: radialMenue, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.5, constant: 0)
            view.addConstraint(widthConstraint)
        } else if view.traitCollection.horizontalSizeClass == .regular {
            let widthConstraint = NSLayoutConstraint(item: radialMenue, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.35, constant: 0)
            view.addConstraint(widthConstraint)
        }
        
        view.addConstraints([centerVertically,
                             centerHorizontally])
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: ButtonsAnimationDuration) {
            self.radialMenue.transform = CGAffineTransform.identity
        }
    }
    func hidePlusButton() {
        DispatchQueue.main.async {
            guard !self.plusButton.isHidden else { return }
            
            self.plusButton.isUserInteractionEnabled = false
            
            UIView.animate(withDuration: ButtonsAnimationDuration, animations: {
                self.plusButton.transform = CGAffineTransform.init(scaleX: 0, y: 0)
            }, completion: ({ (succeed) in
                if succeed == true {
                    self.plusButton.isHidden = true
                }
            }))
        }
    }
    func unhidePlusButton() {
        DispatchQueue.main.async {
            guard self.plusButton.isHidden && !self.plusButton.interfaceHidden else { return }
            
            self.plusButton.isHidden = false
            UIView.animate(withDuration: ButtonsAnimationDuration, animations: {
                self.plusButton.transform = CGAffineTransform.identity
            }) { (succeed) in
                if succeed == true {
                    self.plusButton.isUserInteractionEnabled = true
                }
            }
        }
    }
    func hidePortalDock() {
        optionsDock?.hide()
        optionsDock?.removeFromSuperview()
        optionsDock = nil
        
        portalDecorationOK?.removeFromSuperview()
        portalDecorationReject?.removeFromSuperview()
        portalDecorationsView?.removeFromSuperview()
        
        if let preview = portal?.decorationModelPreview {
            preview.removeFromParentNode()
            portal?.decorationModelPreview = nil
        }
        
    }
    func showStickyIcons() {
        let iconsView = UIView()
        iconsView.translatesAutoresizingMaskIntoConstraints = false
        iconsView.backgroundColor = UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 0.6)
        view.addSubview(iconsView)
        iconsView.layer.cornerRadius = 10.0
        
        /// Add constraints for the view
        let centerIconsViewHorizontally = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: iconsView, attribute: .centerX, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: iconsView, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: -10)
        let widthConstraint = NSLayoutConstraint(item: iconsView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.55, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: iconsView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
        
        view.addConstraints([centerIconsViewHorizontally, bottomConstraint, widthConstraint])
        iconsView.addConstraint(heightConstraint)
        
        /// microphone icon
        let microphonIcon = UIButton()
        microphonIcon.setImage(UIImage(named: "addVoice")!, for: .normal)
        microphonIcon.addTarget(self, action: #selector(microphoneTapped), for: .touchUpInside)
        microphonIcon.translatesAutoresizingMaskIntoConstraints = false
        iconsView.addSubview(microphonIcon)
        
        let microphoneCenterHorizontally = NSLayoutConstraint(item: iconsView, attribute: .centerX, relatedBy: .equal, toItem: microphonIcon, attribute: .centerX, multiplier: 1, constant: 0)
        let microphoneeAspectRatio = NSLayoutConstraint(item: microphonIcon, attribute: .width, relatedBy: .equal, toItem: microphonIcon, attribute: .height, multiplier: 1, constant: 0)
        let microphoneeCenterVertically = NSLayoutConstraint(item: iconsView, attribute: .centerY, relatedBy: .equal, toItem: microphonIcon, attribute: .centerY, multiplier: 1, constant: 0)
        let microphoneHeightConstraint = NSLayoutConstraint(item: microphonIcon, attribute: .height, relatedBy: .equal, toItem: iconsView, attribute: .height, multiplier: 0.8, constant: 0)
        
        microphonIcon.addConstraint(microphoneeAspectRatio)
        iconsView.addConstraints([microphoneeCenterVertically, microphoneCenterHorizontally, microphoneHeightConstraint])
        
        /// Sticky Note Icon
        let stickyNoteIcon = UIButton()
        stickyNoteIcon.setImage(UIImage(named: "addStickyNote")!, for: .normal)
        stickyNoteIcon.addTarget(self, action: #selector(stickyTapped), for: .touchUpInside)
        stickyNoteIcon.translatesAutoresizingMaskIntoConstraints = false
        iconsView.addSubview(stickyNoteIcon)
        
        let stickyNoteAspectRatio = NSLayoutConstraint(item: stickyNoteIcon, attribute: .width, relatedBy: .equal, toItem: stickyNoteIcon, attribute: .height, multiplier: 1, constant: 0)
        stickyNoteIcon.addConstraint(stickyNoteAspectRatio)
        
        let stickyNoteCenterVertically = NSLayoutConstraint(item: iconsView, attribute: .centerY, relatedBy: .equal, toItem: stickyNoteIcon, attribute: .centerY, multiplier: 1, constant: 0)
        let stickyNoteHeightConstraint = NSLayoutConstraint(item: stickyNoteIcon, attribute: .height, relatedBy: .equal, toItem: iconsView, attribute: .height, multiplier: 0.8, constant: 0)
        let stickyNoteTrailingConstraint = NSLayoutConstraint(item: stickyNoteIcon, attribute: .trailing, relatedBy: .equal, toItem: microphonIcon, attribute: .leading, multiplier: 1, constant: -10)
        iconsView.addConstraints([stickyNoteCenterVertically, stickyNoteHeightConstraint, stickyNoteTrailingConstraint])
        
        /// Add photo Icon
        let addPhotoIcon = UIButton()
        addPhotoIcon.setImage(UIImage(named: "addPhoto")!, for: .normal)
        addPhotoIcon.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        addPhotoIcon.translatesAutoresizingMaskIntoConstraints = false
        iconsView.addSubview(addPhotoIcon)
        
        let addPhotoAspectRatio = NSLayoutConstraint(item: addPhotoIcon, attribute: .width, relatedBy: .equal, toItem: addPhotoIcon, attribute: .height, multiplier: 1, constant: 0)
        addPhotoIcon.addConstraint(addPhotoAspectRatio)
        
        let addPhotoCenterVertically = NSLayoutConstraint(item: addPhotoIcon, attribute: .centerY, relatedBy: .equal, toItem: iconsView, attribute: .centerY, multiplier: 1, constant: 0)
        let addPhotoHeightConsraint = NSLayoutConstraint(item: addPhotoIcon, attribute: .height, relatedBy: .equal, toItem: iconsView, attribute: .height, multiplier: 0.8, constant: 0)
        let addPhotoLeadingConstraint = NSLayoutConstraint(item: addPhotoIcon, attribute: .leading, relatedBy: .equal, toItem: microphonIcon, attribute: .trailing, multiplier: 1, constant: 10)
        
        iconsView.addConstraints([addPhotoCenterVertically, addPhotoHeightConsraint, addPhotoLeadingConstraint])
        
        iconsView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        self.stickyIconsView = iconsView
        
        /// Show indicator at the center of the view
        let indicatorView = PinboardIndicatorView()
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = UIColor.clear
        view.addSubview(indicatorView)
        
        let indicatorViewCenterHorizontally = NSLayoutConstraint(item: sceneView, attribute: .centerX, relatedBy: .equal, toItem: indicatorView, attribute: .centerX, multiplier: 1, constant: 0)
        let indicatorViewCenterVertically = NSLayoutConstraint(item: sceneView, attribute: .centerY, relatedBy: .equal, toItem: indicatorView, attribute: .centerY, multiplier: 1, constant: 0)
        let indicatorViewWidthConstraint = NSLayoutConstraint(item: indicatorView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 10)
        let indicatorViewHeightConstraint = NSLayoutConstraint(item: indicatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 10)
        
        indicatorView.addConstraints([indicatorViewWidthConstraint, indicatorViewHeightConstraint])
        
        view.addConstraints([indicatorViewCenterVertically, indicatorViewCenterHorizontally])
        
        indicatorView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        self.boardIndicatorView = indicatorView
    }
    
    func showStickyRecycleIcon () {
        let iconsView = UIView()
        iconsView.translatesAutoresizingMaskIntoConstraints = false
        iconsView.backgroundColor = UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 0.6)
        view.addSubview(iconsView)
        iconsView.layer.cornerRadius = 10.0
        
        /// Add constraints for the view
        let centerIconsViewHorizontally = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: iconsView, attribute: .centerX, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: iconsView, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: -10)
        let widthConstraint = NSLayoutConstraint(item: iconsView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.2, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: iconsView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
        
        view.addConstraints([centerIconsViewHorizontally, bottomConstraint, widthConstraint])
        iconsView.addConstraint(heightConstraint)
        
        // Add RecycleBin icon
        let recycleBin = UIButton()
        recycleBin.setImage(UIImage(named: "StickyRecycle")!, for: .normal)
        recycleBin.addTarget(self, action: #selector(deleteStickyTapped), for: .touchUpInside)
        recycleBin.translatesAutoresizingMaskIntoConstraints = false
        iconsView.addSubview(recycleBin)
        
        /// Add Constraints
        let centerBinHorizontally = NSLayoutConstraint(item: recycleBin, attribute: .centerX, relatedBy: .equal, toItem: iconsView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerBinVertically = NSLayoutConstraint(item: recycleBin, attribute: .centerY, relatedBy: .equal, toItem: iconsView, attribute: .centerY, multiplier: 1, constant: 0)
        let binHeightConstraint = NSLayoutConstraint(item: recycleBin, attribute: .height, relatedBy: .equal, toItem: iconsView, attribute: .height, multiplier: 0.8, constant: 0)
        let binAspectRatioConstraint = NSLayoutConstraint(item: recycleBin, attribute: .width, relatedBy: .equal, toItem: recycleBin, attribute: .height, multiplier: 1, constant: 0)
        
        iconsView.addConstraints([centerBinHorizontally, centerBinVertically, binHeightConstraint])
        recycleBin.addConstraint(binAspectRatioConstraint)
        
        iconsView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        self.stickyRecycleView = iconsView
    }
    func getStickyLocalTransform() {
        /// store the tapped location
        // Get the position on temple where it was tapped
        let options: [SCNHitTestOption: Any] = [SCNHitTestOption.categoryBitMask: NodeCategories.pinBoard.rawValue]
        let hitTestResult = sceneView.hitTest(screenCenter, options: options)
        if let hitResult = hitTestResult.first {
            guard hitResult.node.categoryBitMask == NodeCategories.pinBoard.rawValue else { return }
            
            self.stickyTempLocalPos = hitResult.localCoordinates
            self.stickyTempEulerAngles = hitResult.node.eulerAngles
            self.stickyHitResult = hitResult
        }
    }
    @objc func deleteStickyTapped() {
        guard stickyHitResult != nil, stickyHitResult?.node.name != nil else { return }
        let nodeName = stickyHitResult!.node.name
        let category = NodeCategories.init(rawValue: stickyHitResult!.node.categoryBitMask)!
        
        switch appMode {
        case .normal:
            switch category {
            case .pinPhoto:
                if let pinPhoto = publicPinBoard.first?.pinPhotos[nodeName!] {
                    pinPhoto.discard() { (succeed) in
                        if succeed == true {
                            self.publicPinBoard.first?.pinPhotos.removeValue(forKey: nodeName!)
                            pinPhoto.deleteFromDB(for: self.currentVenue!, id: nodeName!)
                        }
                    }
                }
            case .stickyNote:
                if let stickyNote = publicPinBoard.first?.stickyNotes[nodeName!] {
                    stickyNote.discard(for: currentVenue!) { (succeed) in
                        if succeed {
                            self.publicPinBoard.first?.stickyNotes[nodeName!] = nil
                        }
                    }
                }
            case .voiceBadge:
                if let voiceBadge = publicPinBoard.first?.voiceBadges[nodeName!] {
                    voiceBadge.discard() { (succeed) in
                        if succeed == true {
                            self.publicPinBoard.first?.voiceBadges.removeValue(forKey: nodeName!)
                            voiceBadge.deleteFromDB(for: self.currentVenue!, id: nodeName!)
                        }
                    }
                }
            default:
                break
            }
        case .pinBoard:
            switch category {
            case .pinPhoto:
                if let pinPhoto = personalPinBoard?.pinPhotos[nodeName!] {
                    pinPhoto.discard() { (succeed) in
                        if succeed == true {
                            self.personalPinBoard?.pinPhotos.removeValue(forKey: nodeName!)
                            pinPhoto.deleteFromDB(for: PFUser.current()!, id: nodeName!)
                        }
                    }
                }
            case .stickyNote:
                if let stickyNote = self.personalPinBoard?.stickyNotes[nodeName!] {
                    stickyNote.discard(for: PFUser.current()!) { succeed in
                        if succeed {
                            self.personalPinBoard?.stickyNotes[nodeName!] = nil
                        }
                    }
                    
                }
            case .voiceBadge:
                if let voiceBadge = personalPinBoard?.voiceBadges[nodeName!] {
                    voiceBadge.discard() { (succeed) in
                        if succeed == true {
                            self.personalPinBoard?.voiceBadges.removeValue(forKey: nodeName!)
                            voiceBadge.deleteFromDB(for: PFUser.current()!, id: nodeName!)
                        }
                    }
                }
            default:
                break
            }
        case .portal:
            switch category {
            case .pinPhoto:
                if let pinPhoto = self.portal?.pinBoard?.pinPhotos[nodeName!] {
                    pinPhoto.discard() { (succeed) in
                        if succeed == true {
                            self.portal?.pinBoard?.pinPhotos.removeValue(forKey: nodeName!)
                            pinPhoto.deleteFromDB(for: PFUser.current()!, id: nodeName!)
                        }
                    }
                }
            case .stickyNote:
                if let stickyNote = self.portal?.pinBoard?.stickyNotes[nodeName!] {
                    stickyNote.discard(for: PFUser.current()!) { (succeed) in
                        if succeed {
                            self.portal?.pinBoard?.stickyNotes[nodeName!] = nil
                        }
                    }
                }
            case .voiceBadge:
                if let voiceBadge = self.portal?.pinBoard?.voiceBadges[nodeName!] {
                    voiceBadge.discard() { (succeed) in
                        if succeed == true {
                            self.portal?.pinBoard?.voiceBadges.removeValue(forKey: nodeName!)
                            voiceBadge.deleteFromDB(for: PFUser.current()!, id: nodeName!)
                        }
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }
    @objc func stickyTapped() {
        getStickyLocalTransform()
        
        /// Show a prompt for text input
        let stickyPrompt = UIView()
        stickyPrompt.backgroundColor = UIColor.clear
        stickyPrompt.tag = MainView.stickyPrompt.rawValue
        stickyPrompt.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stickyPrompt)
        
        let centerHorizontally = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: stickyPrompt, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: stickyPrompt, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: stickyPrompt, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: stickyPrompt, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.8, constant: 0)
        
        view.addConstraints([centerHorizontally, centerVertically, widthConstraint, heightConstraint])
        
        /// Add the sticky png on top
        let stickyImage = UIImageView(image: UIImage(named: "StickyNote")!)
        stickyImage.isUserInteractionEnabled = true
        stickyImage.translatesAutoresizingMaskIntoConstraints = false
        stickyImage.tag = 0
        stickyPrompt.addSubview(stickyImage)
        
        let stickyImageCenterHorizontally = NSLayoutConstraint(item: stickyPrompt, attribute: .centerX, relatedBy: .equal, toItem: stickyImage, attribute: .centerX, multiplier: 1, constant: 0)
        let stickyImageTopConstraint = NSLayoutConstraint(item: stickyImage, attribute: .top, relatedBy: .equal, toItem: stickyPrompt, attribute: .top, multiplier: 1, constant: -2)
        let stickyImageAspectRatio = NSLayoutConstraint(item: stickyImage, attribute: .width, relatedBy: .equal, toItem: stickyImage, attribute: .height, multiplier: 1, constant: 0)
        let stickyImageHeightConstraint = NSLayoutConstraint(item: stickyImage, attribute: .height, relatedBy: .equal, toItem: stickyPrompt, attribute: .height, multiplier: 0.6, constant: 0)
        
        stickyPrompt.addConstraints([stickyImageCenterHorizontally, stickyImageTopConstraint, stickyImageHeightConstraint])
        stickyImage.addConstraint(stickyImageAspectRatio)
        
        /// Add text input over stickyImage
        let note = UITextView()
        note.tag = 0
        note.backgroundColor = UIColor.clear
        note.translatesAutoresizingMaskIntoConstraints = false
        stickyImage.addSubview(note)
        
        let noteTopConstraint = NSLayoutConstraint(item: stickyImage, attribute: .top, relatedBy: .equal, toItem: note, attribute: .top, multiplier: 1, constant: -20)
        let noteLeadingConstraint = NSLayoutConstraint(item: stickyImage, attribute: .leading, relatedBy: .equal, toItem: note, attribute: .leading, multiplier: 1, constant: -20)
        let noteTrailingConstraint = NSLayoutConstraint(item: stickyImage, attribute: .trailing, relatedBy: .equal, toItem: note, attribute: .trailing, multiplier: 1, constant: 25)
        let noteBottomConstraint = NSLayoutConstraint(item: stickyImage, attribute: .bottom, relatedBy: .equal, toItem: note, attribute: .bottom, multiplier: 1, constant: 25)
        
        stickyImage.addConstraints([noteTopConstraint, noteLeadingConstraint, noteTrailingConstraint, noteBottomConstraint])
        note.font = UIFont(name: "SavoyeLetPlain", size: 40)
        note.textAlignment = .left
        note.layoutIfNeeded()
        note.setNeedsLayout()
        note.becomeFirstResponder()
        stickyNote = note
        
        /// Add submit button
        let submitButton = UIButton()
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = UIColor.green
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        stickyPrompt.addSubview(submitButton)
        submitButton.titleEdgeInsets = UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1)
        submitButton.setTitleColor(UIColor.white, for: .normal)
        submitButton.layer.cornerRadius = 5.0
        submitButton.addTarget(self, action: #selector(submitStickyNote), for: .touchUpInside)
        
        let submitCenterHorrizontally = NSLayoutConstraint(item: submitButton, attribute: .centerX, relatedBy: .equal, toItem: stickyPrompt, attribute: .centerX, multiplier: 1.5, constant: 0)
        let submitTopConstraint = NSLayoutConstraint(item: submitButton, attribute: .top, relatedBy: .equal, toItem: stickyImage, attribute: .bottom, multiplier: 1, constant: 2)
        let submitWidthConstraint = NSLayoutConstraint(item: submitButton, attribute: .width, relatedBy: .equal, toItem: stickyImage, attribute: .width, multiplier: 0.3, constant: 0)
        let submitHeightConstraint = NSLayoutConstraint(item: submitButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 45)
        
        stickyPrompt.addConstraints([submitCenterHorrizontally, submitTopConstraint, submitWidthConstraint])
        submitButton.addConstraint(submitHeightConstraint)
        
        /// Add a Discard button
        let discardButton = UIButton()
        discardButton.setTitle("Discard", for: .normal)
        discardButton.backgroundColor = UIColor.red
        discardButton.translatesAutoresizingMaskIntoConstraints = false
        stickyPrompt.addSubview(discardButton)
        discardButton.titleEdgeInsets = UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1)
        discardButton.setTitleColor(UIColor.white, for: .normal)
        discardButton.layer.cornerRadius = 5.0
        
        discardButton.addTarget(self, action: #selector(discardStickyPrompt), for: .touchUpInside)
        
        let discardCenterHorrizontally = NSLayoutConstraint(item: discardButton, attribute: .centerX, relatedBy: .equal, toItem: stickyPrompt, attribute: .centerX, multiplier: 0.5, constant: 0)
        let discardTopConstraint = NSLayoutConstraint(item: discardButton, attribute: .top, relatedBy: .equal, toItem: stickyImage, attribute: .bottom, multiplier: 1, constant: 2)
        let discardWidthConstraint = NSLayoutConstraint(item: discardButton, attribute: .width, relatedBy: .equal, toItem: stickyImage, attribute: .width, multiplier: 0.3, constant: 0)
        let discardHeightConstraint = NSLayoutConstraint(item: discardButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 45)
        
        stickyPrompt.addConstraints([discardCenterHorrizontally, discardTopConstraint, discardWidthConstraint])
        discardButton.addConstraint(discardHeightConstraint)
    }
    @objc func discardStickyPrompt() {
        let stickyPrompt = view.viewWithTag(MainView.stickyPrompt.rawValue)
        stickyPrompt?.removeFromSuperview()
        stickyTempLocalPos = nil
        stickyTempEulerAngles = nil
    }
    @objc func submitStickyNote() {
        guard stickyNote != nil, stickyTempLocalPos != nil else { return }
        
        if let text = stickyNote.text, let position = self.stickyTempLocalPos, let hitTestResult = stickyHitResult {
            switch appMode {
            case .normal:
                let stickyNote = StickyNote(text: text, position: SCNVector3Make(position.x, position.y - 0.03, position.z))
                stickyNote.isDeletable = true
                hitTestResult.node.addChildNode(stickyNote.rootNode)
                publicPinBoard.first!.saveToDB(stickyNote)
            case .pinBoard:
                let stickyNote = StickyNote(text: text, position: SCNVector3Make(position.x, position.y - 0.03, position.z), removeShadow: true)
                stickyNote.isDeletable = true
                hitTestResult.node.addChildNode(stickyNote.rootNode)
                personalPinBoard?.saveToDB(stickyNote)
            case .portal:
                let stickyNote = StickyNote(text: text, position: SCNVector3Make(position.x, position.y - 0.03, position.z), removeShadow: true)
                if !portal!.visiting {
                    stickyNote.isDeletable = true
                }
                hitTestResult.node.addChildNode(stickyNote.rootNode)
                portal?.pinBoard?.saveToDB(stickyNote)
            default:
                break
            }
        }
        
        let stickyPrompt = view.viewWithTag(MainView.stickyPrompt.rawValue)
        stickyPrompt?.removeFromSuperview()
    }
    func saveNote(text: String, position: SCNVector3, _ completion: @escaping (_ id: String?) -> Void) {
        if appMode == .portal || appMode == .pinBoard {
            let stickyNoteObject = PFObject(className: "PersonalStickyNotes")
            stickyNoteObject["User"] = PFUser.current()!
            stickyNoteObject["Text"] = text
            stickyNoteObject["Pos"] = NSArray(array: [position.x, position.y, position.z])
            stickyNoteObject.saveInBackground()
        } else if currentVenue != nil {
            let id = currentVenue!.id
            let venueQuery = PFQuery(className: "Venue")
            venueQuery.getObjectInBackground(withId: id) { (object, error) in
                if error == nil {
                    let stickyNotesRelation = object!.relation(forKey: "StickyNotes")
                    
                    /// Create a TempleStickyNote Object
                    let stickyNoteObject = PFObject(className: "TempleStickyNotes")
                    stickyNoteObject["Text"] = text
                    stickyNoteObject["LocalPos"] = NSArray(array: [position.x, position.y, position.z])
                    stickyNoteObject["Author"] = PFUser.current()!
                    
                    stickyNoteObject.saveInBackground { (succeed, error) in
                        if succeed == true {
                            stickyNotesRelation.add(stickyNoteObject)
                            object?.saveInBackground()
                            completion(stickyNoteObject.objectId!)
                        }
                    }
                }
            }
        }
    }
    @objc func microphoneTapped() {
        getStickyLocalTransform()
        
        stopButton.isEnabled = false
        playButton.isEnabled = false
        insertAudio.isEnabled = false
        
        if let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first {
            
            //display the console
            self.audioConsole.transform = CGAffineTransform.identity
            
            let audioFileURL = directoryURL.appendingPathComponent("cassetteRecording.m4a")
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                
                try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
                
                let recorderSetting: [String:Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
            } catch {
                print(error)
            }
            
        } else {
            let alertMessage = UIAlertController(title: "error", message: "Failed to get the document directory of the user. Please try again later.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: {
                // hide the audio console
                
            })
        }
    }
    
    @objc func addPhotoTapped() {
        getStickyLocalTransform()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func personalPinboardIconTapped() {
        guard appMode == .normal else { return }
        
        appMode = .pinBoard
        
        targetingSticky = false
        targetingTemple = false
        
        statusViewController.showMessage("Personal Pinboard - Tap to close", autoHide: false)
        
        personalPinBoard = PersonalPinBoard(user: PFUser.current()!)
        previewNode = PreviewNode(node: personalPinBoard!.rootNode)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.previewNode!)
        }
        removePopUpViews()
        /*
        if let plane = SurfacePlane.planes.sorted(by: { $0.area! > $1.area!}).first {
            let position = plane.position
            
            // Place AR Temple on this plane
            let pinBoard = PersonalPinBoard(user: PFUser.current()!)
            
            pinBoard.rootNode.position = position
            //pinBoard.rootNode.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
            if let yaw = self.session.currentFrame?.camera.eulerAngles.y {
                pinBoard.rootNode.eulerAngles.y = (yaw)
            }
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(pinBoard.rootNode)
            }
        } */
    }
    
    func exitPinboardMode() {
        guard let personalPinBoard = self.personalPinBoard else { return }
        
        personalPinBoard.rootNode.removeFromParentNode()
        self.personalPinBoard = nil
        appMode = .normal
    }
    
    func isStickyDeletable(hitResult: SCNHitTestResult) -> Bool {
        guard stickyHitResult != nil, hitResult.node.name != nil else { return false }
        
        let nodeName = hitResult.node.name
        let category = NodeCategories.init(rawValue: stickyHitResult!.node.categoryBitMask)!
        _ = PFUser.current()!
        
        switch appMode {
        case .normal:
            switch category {
            case .pinPhoto:
                if let pinPhoto = publicPinBoard.first?.pinPhotos[nodeName!] {
                    return pinPhoto.isDeletable
                }
            case .stickyNote:
                if let stickyNote = publicPinBoard.first?.stickyNotes[nodeName!] {
                   return stickyNote.isDeletable
                }
            case .voiceBadge:
                if let voiceBadge = publicPinBoard.first?.voiceBadges[nodeName!] {
                    return voiceBadge.isDeletable
                }
            default:
                return false
            }
        case .pinBoard:
            switch category {
            case .pinPhoto:
                if let pinPhoto = personalPinBoard?.pinPhotos[nodeName!] {
                    return pinPhoto.isDeletable
                }
            case .stickyNote:
                if let stickyNote = personalPinBoard?.stickyNotes[nodeName!] {
                    return stickyNote.isDeletable
                }
            case .voiceBadge:
                if let voiceBadge = personalPinBoard?.voiceBadges[nodeName!] {
                    return voiceBadge.isDeletable
                }
            default:
                return false
            }
        case .portal:
            switch category {
            case .pinPhoto:
                if let pinPhoto = portal?.pinBoard?.pinPhotos[nodeName!] {
                    return pinPhoto.isDeletable
                }
            case .stickyNote:
                if let stickyNote = portal?.pinBoard?.stickyNotes[nodeName!] {
                    return stickyNote.isDeletable
                }
            case .voiceBadge:
                if let voiceBadge = portal?.pinBoard?.voiceBadges[nodeName!] {
                    return voiceBadge.isDeletable
                }
            default:
                return false
            }
        default:
            return false
        }
        return false
    }
    
    func removePopUpViews() {
        
    }
    
    // MARK: - ImagePickerController Delegate
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage {
            let pinPhoto = PinPhoto(image: selectedImage)
            pinPhoto.authorObject = PFUser.current()
            pinPhoto.rootNode.position = SCNVector3Make(self.stickyTempLocalPos!.x, self.stickyTempLocalPos!.y - 0.02, self.stickyTempLocalPos!.z)
            stickyHitResult!.node.addChildNode(pinPhoto.rootNode)
            
            if appMode == .portal || appMode == .pinBoard {
                pinPhoto.saveToDB(for: PFUser.current()!)
                if appMode == .portal, !portal!.visiting {
                    pinPhoto.isDeletable = true
                }
            } else {
                pinPhoto.saveToDB(for: self.currentVenue!)
                pinPhoto.isDeletable = true
            }
            dismiss(animated: true, completion: nil)
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.stickyTempLocalPos = nil
        self.stickyTempEulerAngles = nil
        self.stickyHitResult = nil
    }
}
