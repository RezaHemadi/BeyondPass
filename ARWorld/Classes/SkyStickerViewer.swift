//
//  SkyStickerViewer.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class SkyStickerViewer {
    // MARK: - Configuration
    
    let radius = SKYSTICKERFETCHINGRADIUS
    
    // MARK: - Properties
    
    var location: CLLocation {
        willSet {
            geoPoint = PFGeoPoint(location: newValue)
        }
        didSet {
            guard !isUpdating && location.distance(from: lastUpdateLocation) > 5 else { return }
            
            isUpdating = true
            updateSkyStickers()
            lastUpdateLocation = location
        }
    }
    
    var geoPoint: PFGeoPoint
    
    var lastUpdateLocation: CLLocation
    
    var isUpdating: Bool = true {
        didSet {
            if isUpdating {
                print("Sky Sticker Viewer began updating.")
            } else {
                print("Sky Sticker update done.")
            }
        }
    }
    
    var addedObjects: [SkySticker] = [] {
        didSet {
            print("Sky Sticker added objects: \(addedObjects.count)")
        }
    }
    
    var skyStickerViewerDelegate: SkyStickerViewerDelegate?
    
    // MARK: - Initializers
    
    init(location: CLLocation) {
        self.location = location
        geoPoint = PFGeoPoint(location: location)
        lastUpdateLocation = location
        isUpdating = true
        updateSkyStickers()
    }
    
    private func fetchObjects(_ completion: @escaping (_ objects: [PFObject]?, _ error: Error?) -> Void ) {
        let query = PFQuery(className: "SkySticker")
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: radius / 1000)
        query.findObjectsInBackground { (objects, error) in
            completion(objects, error)
        }
    }
    
    private func updateSkyStickers(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void = {(succeed, error) in} ) {
        fetchObjects { (objects, error) in
            if let skyStickers = objects {
                
                skyStickers.forEach { (object) in
                    if !self.isAddedBefore(object: object) {
                        
                        let skySticker = SkySticker(object: object)
                        self.skyStickerViewerDelegate?.addSkySticker(skySticker, for: self)
                        self.addedObjects.append(skySticker)
                    } else {
                        print("Sky sticker added before.")
                    }
                }
                
                /*
                let newSkyStickers = skyStickers.filter { (skySticker) -> Bool in
                    for addedSkySticker in self.addedObjects {
                        if addedSkySticker.savedInDB {
                            if addedSkySticker.id! == skySticker.objectId! {
                                let modelName = addedSkySticker.model?.getName()
                                print("Sky sticker \(modelName) added before.")
                                return false
                            }
                        }
                    }
                    return true
                }
 
                for newSkySticker in newSkyStickers {
                    let skySticker = SkySticker(object: newSkySticker)
                    self.skyStickerViewerDelegate?.addSkySticker(skySticker, for: self)
                    self.addedObjects.append(skySticker)
                }
 */
                self.isUpdating = false
                completion(true, nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    private func removeRedundantObjects(fetchedObjects: [PFObject]) {
        let redundantObjects = addedObjects.filter { (skySticker) -> Bool in
            guard skySticker.savedInDB else { return false }
            
            for fetchedObject in fetchedObjects {
                if fetchedObject.objectId! == skySticker.id! {
                    return false
                }
            }
            return true
        }
        for redundantObject in redundantObjects {
            redundantObject.node.removeFromParentNode()
            let index = addedObjects.index { (skySticker) -> Bool in
                if skySticker.id == redundantObject.id {
                    return true
                }
                return false
            }
            if index != nil {
                addedObjects.remove(at: index!)
            }
        }
    }
    private func isAddedBefore(object: PFObject) -> Bool {
        let objectId = object.objectId!
        
        let isAdded = addedObjects.contains { (skySticker) -> Bool in
            if (!skySticker.savedInDB || skySticker.id! == objectId) {
                return true
            }
            return false
        }
        
        return isAdded
    }
}
protocol SkyStickerViewerDelegate {
    func addSkySticker(_ skySticker: SkySticker, for viewer: SkyStickerViewer)
}
