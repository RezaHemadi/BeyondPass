//
//  TreasureController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/31/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class TreasureController: TreasureDelegate {
        
        // MARK: - Properties
        var lastHitTest: [SCNHitTestResult]? {
            didSet {
                guard lastHitTest != nil, oldValue != lastHitTest else { return }
                analyzeHitTestResult(lastHitTest!)
            }
        }
        
        private var treasure: [String: TreasureController.Treasure] = [:] // holds new treasure that is not yet placed in portal
        
        private var quantity: [TreasureController.Treasure: Int] = [:] // quantity of each treasure
        
        private var indexedTreasure: [Treasure] = []
        
        private var nodePlacementTreasure: Treasure?
        
        private var addedTreasure: [Treasure] = []
        
        private var collectedTreasureObject: [Treasure: PFObject] = [:]
        
        var shouldHitTest: Bool
        
        var delegate: TreasureControllerDelegate?
        
        var previewNode: PreviewNode?
        
        private var shouldUpdatePreviewNode: Bool = false
        
        // MARK: - Initialization
        
        private var user: PFUser
        
        init(user: PFUser) {
            self.user = user
            shouldHitTest = false
            
            fetchCollectedTreasure()
        }
        
        /// Fetch collected treasure
        private func fetchCollectedTreasure() {
            let collectedTreasureQuery = PFQuery(className: "CollectedTreasure")
            collectedTreasureQuery.whereKey("User", equalTo: user)
            collectedTreasureQuery.includeKey("Treasure")
            collectedTreasureQuery.findObjectsInBackground { (objects, error) in
                if error == nil {
                    if objects!.count == 0 { self.delegate?.treasureController(self, didFinishFetchingItems: [:])}
                    for object in objects! {
                        let treasureObject = object["Treasure"] as! PFObject
                        let quantity = object["Quantity"] as! NSNumber
                        
                        let treasure = Treasure(object: treasureObject)
                        treasure.delegate = self
                        self.collectedTreasureObject[treasure] = object
                        self.quantity[treasure] = quantity.intValue
                        self.treasure[treasureObject.objectId!] = treasure
                        self.indexedTreasure.append(treasure)
                        if objects!.index(of: object) == objects!.count - 1 {
                            // fetching is complete
                            self.delegate?.treasureController(self, didFinishFetchingItems: self.treasure)
                        }
                        
                    }
                } 
            }
        }
        
        // MARK: - Methods
        
        private func loadPlacedTreasure() {
            for (treasure, object) in self.collectedTreasureObject {
                let transformRelation = object.relation(forKey: "PortalTransform")
                let transformsQuery = transformRelation.query()
                transformsQuery.findObjectsInBackground() { objects, error in
                    if error == nil {
                        for object in objects! {
                            let transformArray = object["Transform"] as! NSArray
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
                            treasure.model.simdTransform = transformMatrix
                            self.delegate?.addNode(treasure.model, for: self, { (succeed) in
                                self.addedTreasure.append(treasure)
                            })
                        }
                    }
                }
            }
        }
        
        private func analyzeHitTestResult(_ hitTestResult: [SCNHitTestResult]) {
            if let validResult = validateHitTestResult(hitTestResult) {
                delegate?.updatePreview(of: self.previewNode!, for: self, using: validResult)
            }
        }
        
        private func validateHitTestResult(_ hitTestResult: [SCNHitTestResult]) -> SCNHitTestResult? {
            // Validate hit test here
            return hitTestResult.first
            /*
            if let result = hitTestResult.first(where: { $0.node.categoryBitMask == NodeCategories.portalTreasure.rawValue }) {
                print("Targeting Treasure")
                return result
            }
            if let floorResult = hitTestResult.first(where: { $0.node.categoryBitMask == NodeCategories.portalFloor.rawValue }) {
                print("Targeting Floor")
                return floorResult
            }
            return nil */
        }

        private func showPreview(of treasure: Treasure) {
            DispatchQueue.global(qos: .userInteractive).async {
                self.previewNode = PreviewNode(node: treasure.model)
                self.delegate?.addNode(self.previewNode!, for: self, { succeed in
                    self.shouldUpdatePreviewNode = true
                })
            }
        }
        func saveTreasureTransform(_ treasure: ARPortal.TreasureController.Treasure, transform: simd_float4x4) {
            let transformArray = NSArray(array: [transform.columns.0.x,
                                                 transform.columns.0.y,
                                                 transform.columns.0.z,
                                                 transform.columns.0.w,
                                                 transform.columns.1.x,
                                                 transform.columns.1.y,
                                                 transform.columns.1.z,
                                                 transform.columns.1.w,
                                                 transform.columns.2.x,
                                                 transform.columns.2.y,
                                                 transform.columns.2.z,
                                                 transform.columns.2.w,
                                                 transform.columns.3.x,
                                                 transform.columns.3.y,
                                                 transform.columns.3.z,
                                                 transform.columns.3.w])
            
            let portalTreasureTransformObject = PFObject(className: "PortalTreasureTransform")
            portalTreasureTransformObject["Transform"] = transformArray
            portalTreasureTransformObject.saveInBackground { succeed, error in
                if error == nil {
                    if let collectedTreasureObject = self.collectedTreasureObject[treasure] {
                        let transformsRelation = collectedTreasureObject.relation(forKey: "PortalTransform")
                        transformsRelation.add(portalTreasureTransformObject)
                        collectedTreasureObject.incrementKey("Quantity", byAmount: NSNumber.init(value: -1))
                        collectedTreasureObject.saveInBackground()
                    }
                }
            }
        }
        
        func endNodePlacementMode() {
            shouldHitTest = false
            lastHitTest = nil
            nodePlacementTreasure = nil
            previewNode?.removeFromParentNode()
            previewNode = nil
        }
        
        func treasure(_ treasure: ARPortal.TreasureController.Treasure, didFinishLoadingModel: Bool) {
            if let object = self.collectedTreasureObject[treasure] {
                let transformRelation = object.relation(forKey: "PortalTransform")
                let transformsQuery = transformRelation.query()
                transformsQuery.findObjectsInBackground() { objects, error in
                    if error == nil {
                        for object in objects! {
                            let transformArray = object["Transform"] as! NSArray
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
                            let copy = treasure.copyOfModelWithPhysics()
                            copy.simdTransform = transformMatrix
                            copy.physicsBody?.resetTransform()
                            self.delegate?.addNode(copy, for: self, { (succeed) in
                                
                            })
                        }
                    }
                }
            }
        }
    }
}
extension ARPortal.TreasureController {
    class Treasure: Hashable {
        var hashValue: Int
        
        static func == (lhs: ARPortal.TreasureController.Treasure, rhs: ARPortal.TreasureController.Treasure) -> Bool {
            if lhs.treasureObject.objectId == rhs.treasureObject.objectId { return true }
            return false
        }
        
        
        // MARK: - Properties
        
        var pivotTranslation: (Float, Float, Float)?
        
        var isAdded: Bool
        
        var imageFile: PFFileObject
        
        var treasureObject: PFObject
        
        var delegate: TreasureDelegate?
        
        var model = SCNNode()
        
        // MARK: - Initialization
        
        init(object: PFObject) {
            imageFile = object["Image"] as! PFFileObject
            isAdded = false
            self.hashValue = object.objectId!.hashValue
            self.treasureObject = object
            self.fetchModel()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Database
        
        private func fetchModel() {
            let model = treasureObject["Model"] as! PFObject
            model.fetchIfNeededInBackground { (object, error) in
                if error == nil {
                    let data = object!["Data"] as! PFFileObject
                    data.getDataInBackground() { sceneData, error in
                        if error == nil {
                            let sceneSource = SCNSceneSource(data: sceneData!, options: nil)!
                            let scene = try! sceneSource.scene(options: nil)
                            for node in scene.rootNode.childNodes {
                                node.renderingOrder = 200
                                node.categoryBitMask = NodeCategories.portalTreasure.rawValue
                                self.model.addChildNode(node)
                            }
                            self.adjustChildNodePositions()
                            //self.setCategoryBitMask()
                        }
                        let texturesRelation = model.relation(forKey: "Textures")
                        // Apply Textures
                        let texturesQuery = texturesRelation.query()
                        texturesQuery.findObjectsInBackground { (objects, error) in
                            if error == nil {
                                if let textureObjects = objects {
                                    for textureObject in textureObjects {
                                        let mode = textureObject["Mode"] as! String
                                        let textureMode = TextureMode.init(rawValue: mode)!
                                        let nodeName = textureObject["Name"] as! String
                                        
                                        // find the node corresponding to this texture
                                        let targetNode = self.model.childNode(withName: nodeName, recursively: true)!
                                        
                                        // load the texture data
                                        let textureData = textureObject["Data"] as! PFFileObject
                                        textureData.getDataInBackground { (data, error) in
                                            if error == nil {
                                                if let textureData = data {
                                                    switch textureMode {
                                                    case .diffuse:
                                                        targetNode.geometry?.firstMaterial?.diffuse.contents = UIImage(data: textureData)
                                                        targetNode.geometry?.firstMaterial?.emission.contents = UIImage(data: textureData)
                                                        targetNode.geometry?.firstMaterial?.shininess = 1.0
                                                    case .normal:
                                                        targetNode.geometry?.firstMaterial?.normal.contents = UIImage(data: textureData)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    self.delegate?.treasure(self, didFinishLoadingModel: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // MARK: - Helper Methods
        
        private func adjustChildNodePositions() {
            
            if treasureObject.objectId == "T7kvSaqXtn" {
                for node in model.childNodes {
                    node.eulerAngles = SCNVector3Make(0, 0, 0)
                    node.scale = SCNVector3Make(0.5, 0.5, 0.5)
                }
            }
            
            let (min, max) = model.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y
            let dz = min.z + 0.5 * (max.z - min.z)
            
            pivotTranslation = (dx, dy, dz)
            
            for node in model.childNodes {
                node.position = SCNVector3Make(node.position.x - dx, node.position.y - dy, node.position.z - dz)
            }
        }
        
        private func setCategoryBitMask() {
            model.enumerateChildNodes { (node, stopPointer) in
                if node.geometry != nil {
                    node.categoryBitMask = NodeCategories.portalTreasure.rawValue
                    print("Setting bit mask")
                }
            }
        }
        
        func enablePhysics() {
            let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
            let physicsShape = SCNPhysicsShape(node: model, options: options)
            let transform = model.transform
            let transformValue = NSValue(scnMatrix4: transform)
            let finalShape = SCNPhysicsShape(shapes: [physicsShape], transforms: [transformValue])
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: finalShape)
            physicsBody.allowsResting = true
            physicsBody.friction = 0.8
            physicsBody.mass = 2
            physicsBody.angularDamping = 1.0
            //physicsBody.damping = 1.0
            model.physicsBody = physicsBody
        }
        
        func copyOfModelWithPhysics() -> SCNNode {
            let copy = model.clone()
            let (min, max) = copy.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z + 0.5 * (max.z - min.z)
            let box = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0)
            let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull]
            let physicsShape = SCNPhysicsShape(geometry: box, options: nil)
            let transform = SCNMatrix4MakeTranslation(dx, dy, dz)
            let transformValue = NSValue(scnMatrix4: transform)
            let finalShape = SCNPhysicsShape(shapes: [physicsShape], transforms: [transformValue])
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: finalShape)
            
            physicsBody.allowsResting = false
            physicsBody.friction = 0.8
            physicsBody.mass = 2
            physicsBody.angularDamping = 1.0
 
            copy.physicsBody = physicsBody
            
            return copy
        }
    }
}
extension ARPortal.TreasureController: TreasurePlacementViewDataSource {
    func itemsCount(_ treasurePlacementView: ARPortal.TreasurePlacementView) -> Int {
        print("Number of treasures to be shown: \(treasure.count)")
        return treasure.count
    }
    
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, countForTreasureAt index: Int) -> Int {
        return quantity[indexedTreasure[index]]!
    }
    
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, imageFileForTreasureAt index: Int) -> PFFileObject {
        return indexedTreasure[index].imageFile
    }
}
extension ARPortal.TreasureController: TreasurePlacementViewDelegate {
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didSelectItemAt index: Int) {
        let treasure = indexedTreasure[index]
        let availableQuantity = quantity[treasure]!
        if availableQuantity > 0 {
            shouldHitTest = true
            treasurePlacementView.collectionView.isUserInteractionEnabled = false
            treasurePlacementView.showNodePlacementUI()
            treasurePlacementView.decrementTreasure(at: index)
            quantity[treasure]! -= 1
            showPreview(of: treasure)
            nodePlacementTreasure = treasure
        }
    }
    
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didCancelNodePlacement: Bool) {
        shouldHitTest = false
        lastHitTest = nil
        treasurePlacementView.collectionView.isUserInteractionEnabled = true
        treasurePlacementView.hideNodePlacementUI()
        quantity[nodePlacementTreasure!]! += 1
        treasurePlacementView.incrementTreasure(at: indexedTreasure.index(of: nodePlacementTreasure!)!)
        nodePlacementTreasure = nil
        previewNode?.removeFromParentNode()
        previewNode = nil
    }
    
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didConfirmNodePlacement: Bool) {
        shouldHitTest = false
        lastHitTest = nil
        let treasureTransform = previewNode!.transform
        saveTreasureTransform(nodePlacementTreasure!, transform: previewNode!.simdTransform)
        previewNode?.removeFromParentNode()
        previewNode = nil
        //nodePlacementTreasure!.model.transform = treasureTransform
        let copy = nodePlacementTreasure!.copyOfModelWithPhysics()
        copy.transform = treasureTransform
        copy.physicsBody?.resetTransform()
        nodePlacementTreasure = nil
        delegate?.addNode(copy, for: self, { (succeed) in
            if succeed {
                DispatchQueue.main.async {
                   treasurePlacementView.collectionView.isUserInteractionEnabled = true
                }
                treasurePlacementView.hideNodePlacementUI()
                /// Store the placed treasure in a dictionary
                //self.addedTreasure.append(self.nodePlacementTreasure!)
            }
        })
    }
}
protocol TreasureControllerDelegate {
    func addTreasure(_ treasure: ARPortal.TreasureController.Treasure, for controller: ARPortal.TreasureController, _ completion: @escaping () -> () )
    func treasureController(_ treasureController: ARPortal.TreasureController, didFinishFetchingItems items: [String: ARPortal.TreasureController.Treasure])
    func treasureControllerDidStartNodePlacement(_ treasureController: ARPortal.TreasureController, for: ARPortal.TreasureController.Treasure)
    func treasureControllerDidEndNodePlacement(_ treasureController: ARPortal.TreasureController, for: ARPortal.TreasureController.Treasure)
    func addNode(_ node: SCNNode, for treasureController: ARPortal.TreasureController, _ completion: @escaping (_ succeed: Bool) -> () )
    func updatePreview(of previewNode: PreviewNode, for treasureController: ARPortal.TreasureController, using hitTest: SCNHitTestResult)
}
protocol TreasureDelegate {
    func treasure(_ treasure: ARPortal.TreasureController.Treasure, didFinishLoadingModel: Bool) -> Void
}
