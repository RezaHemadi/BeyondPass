//
//  Treasure.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//
//  A treasure instance is created once it is determined where to show it and what the treasure model is

import Foundation

class Treasure {
    
    // MARK: - Properties
    
    var id: String // id of the treasure in "Treasure" table
    
    var location: CLLocation?
    
    var name: String? // The name of the treasure
    
    var image: UIImage? // The image of the treasure
    
    private var treasureObject: PFObject?
    
    var refNode: SCNNode = SCNNode()
    
    var isCollected: Bool = false
    
    var availableAudioPlayer: SCNAudioPlayer?
    
    // MARK: - Initialization
    
    init(id: String) {
        self.id = id
        refNode.isHidden = true
        refNode.categoryBitMask = NodeCategories.treasure.rawValue
        bounce()
    }
    
    // MARK: - Database
    
    func loadModel(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        let treasureQuery = PFQuery(className: "Treasure")
        treasureQuery.getObjectInBackground(withId: id) { (object, error) in
            if error == nil {
                if let treasureObject = object {
                    
                    self.treasureObject = object
                    
                    self.loadImage()
                    
                    self.name = treasureObject["Name"] as! String
                    
                    let modelRef = treasureObject["Model"] as! PFObject
                    modelRef.fetchIfNeededInBackground { (object, error) in
                        if error == nil {
                            if let model = object {
                                let data = model["Data"] as! PFFileObject
                                let texturesRelation = model.relation(forKey: "Textures")
                                
                                data.getDataInBackground { (sceneData, error) in
                                    if error == nil {
                                        if let sceneData = sceneData {
                                            let sceneSource = SCNSceneSource(data: sceneData, options: nil)!
                                            let scene = try! sceneSource.scene(options: nil)
                                            
                                            for node in scene.rootNode.childNodes {
                                                node.categoryBitMask = NodeCategories.treasure.rawValue
                                                self.refNode.addChildNode(node)
                                            }
                                            
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
                                                            let targetNode = self.refNode.childNode(withName: nodeName, recursively: true)!
                                                            
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
                                                        self.refNode.isHidden = false
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
    
    private func loadImage() {
        if let treasure = self.treasureObject {
            if let imageFile = treasure["Image"] as? PFFileObject {
                imageFile.getDataInBackground { (data, error) in
                    if error == nil {
                        if let imageData = data {
                            self.image = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
    
    func saveInDB(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        guard let currentUser = PFUser.current(), let location = self.location, let treasureObject = self.treasureObject else { return }
        
        /// Check if the user has collected this treasure before
        let collectedTreasureQuery = PFQuery(className: "CollectedTreasure")
        collectedTreasureQuery.whereKey("User", equalTo: currentUser)
        collectedTreasureQuery.whereKey("Treasure", equalTo: treasureObject)
        collectedTreasureQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                if let collectedTreasureObject = objects?.first {
                    /// The user has collected this treasure before
                    /// Increment the "Quantity" field for this treasure
                    collectedTreasureObject.incrementKey("Quantity")
                    
                    /// Add current location to the relation of collected locations
                    let locationsRelation = collectedTreasureObject.relation(forKey: "Locations")
                    
                    /// Create a CollectedTreasuresLocation object and add it to the relation
                    let collectedTreasureLocationObject = PFObject(className: "CollectedTreasureLocations")
                    collectedTreasureLocationObject["Location"] = PFGeoPoint(location: location)
                    collectedTreasureLocationObject.saveInBackground { (succeed, error) in
                        if error == nil {
                            if succeed == true {
                                /// add this object to the relation
                                locationsRelation.add(collectedTreasureLocationObject)
                                
                                /// save the collectedTreasureObject
                                collectedTreasureObject.saveInBackground { (succeed, error) in
                                    if error == nil {
                                        if succeed == true {
                                            completion(true, nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } else {
                    /// The user is collecting this treasure for the first time
                    /// Create a record in the "CollectedTreasure" class
                    let collectedTreasure = PFObject(className: "CollectedTreasure")
                    collectedTreasure["User"] = currentUser
                    collectedTreasure["Treasure"] = treasureObject
                    collectedTreasure["Quantity"] = 1
                    
                    let locationsRelation = collectedTreasure.relation(forKey: "Locations")
                    
                    /// Create a collectedTreasureLocation record
                    let collectedTreasureLocationObject = PFObject(className: "CollectedTreasureLocations")
                    collectedTreasureLocationObject["Location"] = PFGeoPoint(location: location)
                    collectedTreasureLocationObject.saveInBackground { (succeed, error) in
                        if error == nil {
                            if succeed == true {
                                locationsRelation.add(collectedTreasureLocationObject)
                                
                                collectedTreasure.saveInBackground { (succeed, error) in
                                    if error == nil {
                                        if succeed == true {
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
    // MARK: - Actions
    
    func playTreasureAvailableSound() {
        let url = Bundle.main.url(forResource: "TreasureAvailable", withExtension: "mp3", subdirectory: "art.scnassets/TreasureSounds")!
        let audioSource = SCNAudioSource(url: url)!
        audioSource.loops = true
        self.availableAudioPlayer = SCNAudioPlayer(source: audioSource)
        refNode.addAudioPlayer(self.availableAudioPlayer!)
    }
    
    func stopTreasureAvailableSound() {
        refNode.removeAudioPlayer(availableAudioPlayer!)
        availableAudioPlayer = nil
    }
    
    func playTreasureCollectSound() {
        let url = Bundle.main.url(forResource: "TreasureCollect", withExtension: "wav", subdirectory: "art.scnassets/TreasureSounds")!
        let audioSource = SCNAudioSource(url: url)!
        let soundAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        refNode.runAction(soundAction)
    }
    
    func fade(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        let fadeAction = SCNAction.fadeOpacity(to: 0, duration: 0.3)
        refNode.runAction(fadeAction) {
            self.refNode.removeFromParentNode()
            completion(true)
        }
    }
    private func bounce() {
        let upAction = SCNAction.move(by: SCNVector3Make(0, 0.07, 0), duration: 0.5)
        let downAction = SCNAction.move(by: SCNVector3Make(0, -0.07, 0), duration: 0.5)
        let secAction = SCNAction.sequence([upAction, downAction])
        let bounceAction = SCNAction.repeatForever(secAction)
        
        refNode.runAction(bounceAction)
    }
}
