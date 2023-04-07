//
//  ARPortal.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/3/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class ARPortal {
    
    // MARK: - Types
    enum State {
        case preview
        case placed
        case animatingDoor
        case decorating
    }
    
    // MARK: - Properties
    
    var delegate: ARPortalDelegate?
    
    var treasureController: TreasureController?
    
    var treasurePlacementView: TreasurePlacementView!
    
    var anchor: ARAnchor?
    
    var preview: PreviewNode?
    
    var openingNode: SCNNode?
    
    var decorationModelPreview: PreviewNode?
    
    var pinBoard: PortalPinBoard?
    
    var visiting: Bool = false
    
    var user: PFUser
    
    var editingExistingDecorationModel: Bool = false
    
    var editingDecorationID: String?
    
    var editingModel: SCNNode? {
        get {
            if let id = editingDecorationID {
                return decorationModels[id]
            }
            return nil
        }
    }
    
    var currentWallpaper: PFObject? /// A record in the "PurchasedPortalWallpaper" class
    
    var state: State = .preview
    
    var portalNode: SCNNode!
    
    var shelves: [Shelf] = []
    
    var inventoryCount: Int?
    
    var models: [PFObject] = []
    
    var dartboard: Dartboard!
    
    var floor: SCNNode!
    
    var body: SCNNode!
    
    var photoFrame: SCNNode?
    
    var simdWorldTransform: simd_float4x4!
    
    var decorationModels: [String: SCNNode] = [:]
    
    // MARK: - Initialization
    
    init(user: PFUser) {
        self.user = user
    }
    
    func setupPreview(_ completion: @escaping (_ preview: PreviewNode?) -> Void = {_ in} ) {
        let url = Bundle.main.url(forResource: "PortalPreview", withExtension: "scn", subdirectory: "art.scnassets/Portal")!
        let portalPreviewReferenceNode = SCNReferenceNode.init(url: url)!
        
        DispatchQueue.global(qos: .userInteractive).async {
            portalPreviewReferenceNode.load()
            let openingNode = portalPreviewReferenceNode.childNode(withName: "Opening", recursively: true)!
            //openingNode.scale = SCNVector3Make(1., 1, 1)
            let (min, max) = portalPreviewReferenceNode.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y
            let dz = min.z + 0.5 * (max.z - min.z)
            
            openingNode.position = SCNVector3Make(-dx, -dy, -dz)
            let preview = PreviewNode(node: portalPreviewReferenceNode)
            self.preview = preview
            completion(preview)
        }
    }
    
    func setupPortal(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        DispatchQueue.main.async {
            let portalURL = Bundle.main.url(forResource: "Portal", withExtension: "scn", subdirectory: "art.scnassets/Portal")!
            let finalPortalReferenceNode = SCNReferenceNode.init(url: portalURL)!
            
            
            finalPortalReferenceNode.load()
            let tempMax = finalPortalReferenceNode.boundingBox.max
            finalPortalReferenceNode.pivot = SCNMatrix4MakeTranslation(0, 0, tempMax.z)
            self.portalNode = finalPortalReferenceNode
            self.simdWorldTransform = self.portalNode.simdWorldTransform
            
            self.floor = self.portalNode.childNode(withName: "floor", recursively: true)!
            self.floor.categoryBitMask = NodeCategories.portalFloor.rawValue
            self.body = self.portalNode.childNode(withName: "Body", recursively: true)!
            self.body.categoryBitMask = NodeCategories.portal.rawValue
            self.photoFrame = self.portalNode.childNode(withName: "PhotoFrame", recursively: true)!
            
            // Initialize dartboard
            self.dartboard = Dartboard(node: self.portalNode.childNode(withName: "Dartboard", recursively: true)!)
            
            // Position the dartboard so that it's center is 1.73m from the floor
            let (dartboardMin, dartboardMax) = self.dartboard.node.boundingBox
            let dartboardCenterX = dartboardMin.x + 0.5 * (dartboardMax.x - dartboardMin.x)
            let dartboardCenterY = dartboardMin.y + 0.5 * (dartboardMax.y - dartboardMin.y)
            let dartboardCenterZ = dartboardMin.z + 0.5 * (dartboardMax.z - dartboardMin.z)
            let localDartboardCenter = float3(dartboardCenterX, dartboardCenterY, dartboardCenterZ)
            let portalDartboardCenter = self.dartboard.node.simdConvertPosition(localDartboardCenter, to: self.portalNode)
            
            let (floorMin, floorMax) = self.floor.boundingBox
            let floorCenterX = floorMin.x + 0.5 * (floorMax.x - floorMin.x)
            let floorCenterY = floorMin.y + 0.5 * (floorMax.y - floorMin.y)
            let floorCenterZ = floorMin.z + 0.5 * (floorMax.z - floorMin.z)
            let localFloorCenter = float3(floorCenterX, floorCenterY, floorCenterZ)
            let portalFloorCenter = self.floor.simdConvertPosition(localFloorCenter, to: self.portalNode)
            
            /// Adjust the z component of dartboard position so that the it is 1.73 from the floor
            let yTranslation = portalDartboardCenter.y - portalFloorCenter.y
            let requieredTranslation: Float = 1.73
            let translateBy = float3(0, -yTranslation - dartboardCenterZ + 0.341 + requieredTranslation, 0)
            let originalPosition = self.dartboard.node.simdPosition
            self.dartboard.node.simdPosition = originalPosition + translateBy
            
            self.layOche()
            
            for i in 1...12 {
                let shelfNode = self.portalNode.childNode(withName: "Shelf" + String(describing: i), recursively: true)!
                self.shelves.append(Shelf(node: shelfNode, index: i))
            }
            self.floor.physicsBody?.resetTransform()
            // Load user dependant items
            // Set up photo frame
            self.pinBoard = PortalPinBoard(node: self.portalNode.childNode(withName: "Pinboard", recursively: true)!, user: self.user)
            let photoFramePlane = self.photoFrame!.childNode(withName: "Plane", recursively: true)!
            getUserProfilePhoto(self.user, completion: { (image, error) in
                if error == nil {
                    DispatchQueue.global(qos: .userInteractive).async {
                        photoFramePlane.geometry?.firstMaterial?.diffuse.contents = image!
                        photoFramePlane.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeRotation(.pi, 0, 0, 1)
                    }
                }
            })
            //self.loadInventory()
            self.placePortalItems()
            self.loadWallpaper()
            completion(true)
        }
    }
    
    func animationComplete() {
        enableStaticPhysics()
        self.dartboard.enableDartPlanePhysics()
        self.treasureController = TreasureController(user: self.user)
        self.treasureController!.delegate = self
    }
    
    func enableStaticPhysics() {
        
        let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull]
        let physicsShape = SCNPhysicsShape(node: floor, options: options)
        floor.presentation.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        floor.presentation.physicsBody?.friction = 0.8
    }
    
    // MARK: - Closing Portal
    
    func close() {
        floor?.presentation.physicsBody = nil
        portalNode?.removeFromParentNode()
        preview?.removeFromParentNode()
        openingNode?.removeFromParentNode()
    }
    
    // MARK: - Shelves
    private func loadInventory(_ completion: @escaping (_ succeed: Bool?, _ error: Error? ) -> Void = { _, _ in }) {
        let inventoryQuery = PFQuery(className: "Inventory")
        inventoryQuery.whereKey("User", equalTo: user)
        inventoryQuery.getFirstObjectInBackground {
            (object, error) in
            if error == nil {
                let inventoryRelation = object!.relation(forKey: "Items")
                let inventoryItemsQuery = inventoryRelation.query()
                inventoryItemsQuery.findObjectsInBackground {
                    (objects, error) in
                    if error == nil {
                        self.inventoryCount = objects!.count
                        
                        // Fetch the models of the inventory
                        var i: Int = 0
                        for object in objects! {
                            
                            let quantity = object["Quantity"] as! Int
                            if quantity == 0 { continue }
                            
                            let model = object["Model"] as! PFObject
                            self.models.append(model)
                            
                            model.fetchInBackground {
                                (model, error) in
                                if let data = model!["data"] as? PFFileObject {
                                    // Model data is on the server
                                    
                                } else {
                                    // Model is in bundle
                                    let name = model!["Name"] as! String
                                    let directory = model!["Directory"] as! String
                                    
                                    let modelURL = Bundle.main.url(forResource: name, withExtension: "scn", subdirectory: "art.scnassets/" + directory)!
                                    
                                    let modelNode = SCNReferenceNode(url: modelURL)!
                                    modelNode.load()
                                    
                                    let node = modelNode.childNodes.first!
                                    
                                    // Adjust node pivot to buttom
                                    let (min, max) = node.boundingBox
                                    
                                    /// check if model is zUp
                                    let zUp = model!["zUp"] as? Bool
                                    
                                    if zUp == true {
                                        let dx = min.x + 0.5 * (max.x - min.x)
                                        let dy = min.y + 0.5 * (max.y - min.y)
                                        let dz = min.z
                                        
                                        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                                    } else {
                                        let dx = min.x + 0.5 * (max.x - min.x)
                                        let dy = min.y
                                        let dz = min.z + 0.5 * (max.z - min.z)
                                        
                                        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                                    }
                                    
                                    // Place the node in position
                                    let shelfPlaceHolder = self.shelves[i].placeHolder
                                    /// convert placeholder to portal node
                                    node.position = self.shelves[i].node.convertPosition(shelfPlaceHolder, to: self.portalNode)
                                    node.renderingOrder = 200
                                    node.physicsBody = nil
                                    DispatchQueue.global(qos: .userInteractive).async {
                                        self.portalNode.addChildNode(node)
                                    }
                                }
                                i += 1
                            }
                            if objects!.last!.isEqual(object) {
                                completion(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func placePortalItems(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void = { _, _ in }) {
        /// Find the record corresponding to current user in
        /// the "UserPortals" table
        let userPortalQuery = PFQuery(className: "UserPortals")
        userPortalQuery.whereKey("User", equalTo: user)
        userPortalQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
            if error == nil {
                if let userPortal = objects?.first {
                    let modelItems = userPortal.relation(forKey: "ModelItems")
                    let modelItemsQuery = modelItems.query()
                    modelItemsQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                        if error == nil {
                            if let items = objects {
                                let count = items.count
                                var i: Int = 0
                                for item in items {
                                    let transformArray = item["Transform"] as! NSArray
                                    
                                    var transformMatrix = float4x4.init()
                                    
                                    var index = 0
                                    for arrayLiteral in transformArray {
                                        let arrayNumber = arrayLiteral as! NSNumber
                                        
                                        switch index {
                                        case 0:
                                            transformMatrix.columns.0.x = arrayNumber.floatValue
                                        case 1:
                                            transformMatrix.columns.0.y = arrayNumber.floatValue
                                        case 2:
                                            transformMatrix.columns.0.z = arrayNumber.floatValue
                                        case 3:
                                            transformMatrix.columns.0.w = arrayNumber.floatValue
                                        case 4:
                                            transformMatrix.columns.1.x = arrayNumber.floatValue
                                        case 5:
                                            transformMatrix.columns.1.y = arrayNumber.floatValue
                                        case 6:
                                            transformMatrix.columns.1.z = arrayNumber.floatValue
                                        case 7:
                                            transformMatrix.columns.1.w = arrayNumber.floatValue
                                        case 8:
                                            transformMatrix.columns.2.x = arrayNumber.floatValue
                                        case 9:
                                            transformMatrix.columns.2.y = arrayNumber.floatValue
                                        case 10:
                                            transformMatrix.columns.2.z = arrayNumber.floatValue
                                        case 11:
                                            transformMatrix.columns.2.w = arrayNumber.floatValue
                                        case 12:
                                            transformMatrix.columns.3.x = arrayNumber.floatValue
                                        case 13:
                                            transformMatrix.columns.3.y = arrayNumber.floatValue
                                        case 14:
                                            transformMatrix.columns.3.z = arrayNumber.floatValue
                                        case 15:
                                            transformMatrix.columns.3.w = arrayNumber.floatValue
                                        default:
                                            break
                                        }
                                        
                                        index += 1
                                    }
                                    
                                    let decorationModel = item["DecorationModel"] as! PFObject
                                    
                                    /// Find the model to corresponding to this item
                                    decorationModel.fetchIfNeededInBackground { (object: PFObject?, error: Error? ) -> Void in
                                        if error == nil {
                                            if let decorationModel = object {
                                                
                                                let model = decorationModel["Model"] as! PFObject
                                                model.fetchIfNeededInBackground { (object: PFObject?, error: Error? ) -> Void in
                                                    if error == nil {
                                                        if let model = object {
                                                            if let data = model["Data"] as? PFFileObject {
                                                                data.getDataInBackground { (data: Data?, error: Error? ) -> Void in
                                                                    if error == nil {
                                                                        if let modelData = data {
                                                                            let sceneSource = SCNSceneSource(data: modelData, options: nil)!
                                                                            let options: [SCNSceneSource.LoadingOption: Any] = [.flattenScene: true]
                                                                            let scene = sceneSource.scene(options: options)!
                                                                            
                                                                            let modelNode = SCNNode()
                                                                            for node in scene.rootNode.childNodes {
                                                                                DispatchQueue.global(qos: .userInteractive).async {
                                                                                    modelNode.addChildNode(node)
                                                                                }
                                                                                node.renderingOrder = 200
                                                                            }
                                                                            modelNode.renderingOrder = 200
                                                                            modelNode.categoryBitMask = NodeCategories.portalModel.rawValue
                                                                            modelNode.simdTransform = transformMatrix
                                                                            DispatchQueue.global(qos: .userInteractive).async {
                                                                                self.portalNode.addChildNode(modelNode)
                                                                            }
                                                                            self.decorationModels[item.objectId!] = modelNode
                                                                                
                                                                            // Apply Textures to the model
                                                                            let textures = model.relation(forKey: "Textures")
                                                                            let texturesQuery = textures.query()
                                                                            texturesQuery.findObjectsInBackground {
                                                                                (objects, error) in
                                                                                if error == nil {
                                                                                    for object in objects! {
                                                                                        let materialName = object["Name"] as! String
                                                                                        
                                                                                        // Find the node corresponding to this
                                                                                        let targetNode = modelNode.childNode(withName: materialName, recursively: true)!
                                                                                        let materialData = object["Data"] as! PFFileObject
                                                                                        let data = try! materialData.getData()
                                                                                        
                                                                                        if let mode = object["Mode"] as? String {
                                                                                            let textureMode = TextureMode.init(rawValue: mode)!
                                                                                            
                                                                                            switch textureMode {
                                                                                            case .diffuse:
                                                                                                DispatchQueue.global(qos: .background).async {
                                                                                                    targetNode.geometry?.firstMaterial?.diffuse.contents = UIImage(data: data)!
                                                                                                }
                                                                                            case .normal:
                                                                                                DispatchQueue.global(qos: .background).async {
                                                                                                    targetNode.geometry?.firstMaterial?.normal.contents = UIImage(data: data)!
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                let rootNode = modelNode.childNode(withName: "root", recursively: true)!
                                                                                for childNode in rootNode.childNodes {
                                                                                    childNode.name = item.objectId!
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
                                        }
                                    }
                                    i += 1
                                    if i == count {
                                        completion(true, nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // MARK: - Oche
    
    func layOche() {
        let oche = generateOche()
        oche.simdPosition = ochePosition()
        DispatchQueue.global(qos: .userInteractive).async {
            self.portalNode.addChildNode(oche)
        }
    }
    
    private func generateOche() -> SCNNode {
        let width: CGFloat = 0.604
        let lengthToBoard: CGFloat = 2.37
        let height: CGFloat = 2.55
        let carpetColor = UIColor(red: 37/255.0, green: 39/255.0, blue: 40/255.0, alpha: 1)
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = carpetColor
        let carpetNode = SCNNode(geometry: plane)
        carpetNode.eulerAngles = SCNVector3Make(-.pi / 2, .pi / 2, 0)
        
        let box1 = SCNBox(width: width, height: 0.05, length: 0.03, chamferRadius: 0.05)
        let box1Node = SCNNode(geometry: box1)
        box1.firstMaterial?.diffuse.contents = UIColor(red: 232/255.0, green: 221/255.0, blue: 69/255.0, alpha: 1)
        box1Node.simdPosition = float3(0, Float(lengthToBoard - (height / 2)), 0.015)
        DispatchQueue.global(qos: .userInteractive).async {
            carpetNode.addChildNode(box1Node)
        }
        
        carpetNode.renderingOrder = 200
        box1Node.renderingOrder = 200
        
        return carpetNode
    }
    private func ochePosition() -> float3 {
        let (floorMin, floorMax) = self.floor.boundingBox
        let floorCenterX = floorMin.x + 0.5 * (floorMax.x - floorMin.x)
        let floorCenterY = floorMin.y + 0.5 * (floorMax.y - floorMin.y)
        let floorCenterZ = floorMin.z + 0.5 * (floorMax.z - floorMin.z)
        let localFloorCenter = float3(floorCenterX, floorCenterY, floorCenterZ)
        let portalFloorCenter = self.floor.simdConvertPosition(localFloorCenter, to: self.portalNode)
        
        return portalFloorCenter + float3(1.5, 0.02, 0.05)
    }
    
    // MARK: Actions and Animations
    
    func stopAnimations() {
       // punkPit.pauseActions()
    }
    
    func resumeAnimations() {
       // punkPit.resumeActions()
    }
    
    // MARK: - Containment
    
    /// to check if a position in the portalNode local space is inside the portal
    func contains(position: SCNVector3) -> Bool {
        
        /// Position is in local coordinate of portalNode
        let (min, max) = portalNode.boundingBox
        
        if (min.x.isLess(than: position.x) &&
            min.y.isLess(than: position.y) &&
            min.z.isLess(than: position.z) &&
            max.x > position.x &&
            max.y > position.y &&
            max.z > position.z) {
            return true
        }
        return false
    }
    
    // MARK: - Visuals
    
    func setWallpaper(wallpaperData: Data) {
        guard body != nil else { return }
        
        /// Create an image from the data
        let wallpaper = UIImage(data: wallpaperData)!
        DispatchQueue.global(qos: .userInteractive).async {
            self.body.geometry?.firstMaterial?.diffuse.contents = wallpaper
        }
    }
    
    func loadWallpaper(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void = { _, _ in } ) {
        let userPortalQuery = PFQuery(className: "UserPortals")
        userPortalQuery.whereKey("User", equalTo: user)
        userPortalQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let userPortal = objects?.first {
                    /// Check if the userPortal has a "Wallpaper" field set
                    if let purchasedWallpaper = userPortal["Wallpaper"] as? PFObject {
                        purchasedWallpaper.fetchIfNeededInBackground { (object: PFObject?, error: Error?) -> Void in
                            if error == nil {
                                if let purchasedWallpaper = object {
                                    self.currentWallpaper = purchasedWallpaper
                                    let decorationWallpaper = purchasedWallpaper["DecorationWallpaper"] as! PFObject
                                    decorationWallpaper.fetchIfNeededInBackground { (object: PFObject?, error: Error? ) -> Void in
                                        if error == nil {
                                            if let decorationWallpaper = object {
                                                let wallpaperFile = decorationWallpaper["Wallpaper"] as! PFFileObject
                                                wallpaperFile.getDataInBackground { (data: Data?, error: Error?) -> Void in
                                                    if error == nil {
                                                        if let wallpaperData = data {
                                                            self.setWallpaper(wallpaperData: wallpaperData)
                                                            completion(true, nil)
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
                }
            }
        }
    }
    
    func endTreasurePlacementMode() {
        treasurePlacementView.removeFromSuperview()
        treasurePlacementView = nil
        treasureController?.endNodePlacementMode()
    }
    
    func loadTrophies(trophies: [Trophy], _ completion: @escaping (_ succeed: Bool?) -> Void) {
        DispatchQueue.global(qos: .background).async {
             var i: Int = 0
            for trophy in trophies {
                trophy.loadModel({ (succeed) in
                    if succeed == true {
                        let (min, max) = trophy.boundingBox
                        let dx = min.x + 0.5 * (max.x - min.x)
                        let dy = min.y
                        let dz = min.z + 0.5 * (max.z - min.z)
                        
                        trophy.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                        
                        // Place the node in position
                        let shelfPlaceHolder = self.shelves[i].placeHolder
                        /// convert placeholder to portal node
                        trophy.position = self.shelves[i].node.convertPosition(shelfPlaceHolder, to: self.portalNode)
                        trophy.childNodes.forEach( {$0.renderingOrder = 200} )
                        self.portalNode.addChildNode(trophy)
                        
                        i += 1
                    }
                })
            }
        }
    }
}
protocol ARPortalDelegate {
    func updatePreview(for previewNode: PreviewNode, for portal: ARPortal, parentNode node: SCNNode, using hitTest: SCNHitTestResult)
}
