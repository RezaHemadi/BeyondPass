//
//  PinPhoto.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/22/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class PinPhoto {
    
    var rootNode: SCNReferenceNode
    
    var authorObject: PFUser?
    
    var isDeletable: Bool = false
    
    private var photoNode: SCNNode? {
        didSet {
            setPhotoMaterial()
        }
    }
    
    private var frameNode: SCNNode?
    
    var image: UIImage
    
    init(image: UIImage, inPortal: Bool = false) {
        self.image = image
        
        let url = Bundle.main.url(forResource: "photowithPin", withExtension: "scn", subdirectory: "art.scnassets/PinBoardPublic")!
        self.rootNode = SCNReferenceNode(url: url)!
        self.rootNode.loadingPolicy = .onDemand
        self.rootNode.scale = SCNVector3Make(0.4, 0.4, 0.4)
        DispatchQueue.global(qos: .background).async {
            self.rootNode.load()
            
            self.photoNode = self.rootNode.childNode(withName: "Photo", recursively: true)!
            self.frameNode = self.rootNode.childNode(withName: "Frame", recursively: true)!
            
            self.photoNode!.categoryBitMask = NodeCategories.pinPhoto.rawValue
            self.frameNode!.categoryBitMask = NodeCategories.pinPhoto.rawValue
            
            if inPortal {
                self.photoNode!.renderingOrder = 200
                self.frameNode?.renderingOrder = 200
                let brep = self.rootNode.childNode(withName: "Brep", recursively: true)!
                brep.renderingOrder = 200
            }
        }
    }
    
    init(image: UIImage, id: String, author: PFUser, inPortal: Bool = false) {
        self.image = image
        self.authorObject = author
        
        let url = Bundle.main.url(forResource: "photowithPin", withExtension: "scn", subdirectory: "art.scnassets/PinBoardPublic")!
        self.rootNode = SCNReferenceNode(url: url)!
        self.rootNode.loadingPolicy = .onDemand
        self.rootNode.scale = SCNVector3Make(0.4, 0.4, 0.4)
        DispatchQueue.global(qos: .background).async {
            self.rootNode.load()
            
            self.photoNode = self.rootNode.childNode(withName: "Photo", recursively: true)!
            self.frameNode = self.rootNode.childNode(withName: "Frame", recursively: true)!
            
            self.photoNode!.categoryBitMask = NodeCategories.pinPhoto.rawValue
            self.frameNode!.categoryBitMask = NodeCategories.pinPhoto.rawValue
            self.photoNode!.name = id
            self.frameNode!.name = id
            
            if inPortal {
                self.photoNode!.renderingOrder = 200
                self.frameNode?.renderingOrder = 200
                let brep = self.rootNode.childNode(withName: "Brep", recursively: true)!
                brep.renderingOrder = 200
            }
        }
    }
    
    private func setPhotoMaterial() {
        self.photoNode?.geometry?.firstMaterial?.diffuse.contents = self.image
    }
    
    func saveToDB(for venue: Venue) {
        DispatchQueue.global(qos: .background).async {
            do {
                let resizedImage = resizeImage(image: self.image, targetSize: CGSize(width: 1024, height: 1024))
                let imageData = resizedImage.pngData()!
                
                let photoObject = PFObject(className: "PinPhoto")
                photoObject["Author"] = PFUser.current()!
                photoObject["Pos"] = NSArray(array: [self.rootNode.position.x, self.rootNode.position.y, self.rootNode.position.z])
                photoObject["Image"] = PFFileObject(data: imageData)
                try photoObject.save()
                
                let venueQuery = PFQuery(className: "Venue")
                let venueObject = try venueQuery.getObjectWithId(venue.id)
                let photosRelation = venueObject.relation(forKey: "Photos")
                photosRelation.add(photoObject)
                try venueObject.save()
                self.frameNode?.name = photoObject.objectId
                self.photoNode?.name = photoObject.objectId
            } catch {
                
            }
        }
    }
    func saveToDB(for user: PFUser) {
        DispatchQueue.global(qos: .background).async {
            let resizedImage = resizeImage(image: self.image, targetSize: CGSize(width: 1024, height: 1024))
            let imageData = resizedImage.pngData()!
            
            let personalPinPhotoObject = PFObject(className: "PersonalPinPhoto")
            personalPinPhotoObject["User"] = user
            personalPinPhotoObject["Image"] = PFFileObject(data: imageData)
            personalPinPhotoObject["Pos"] = NSArray(array: [self.rootNode.position.x, self.rootNode.position.y, self.rootNode.position.z])
            personalPinPhotoObject.saveInBackground() { (succeed, error) in
                if error == nil {
                    if succeed == true {
                        self.photoNode?.name = personalPinPhotoObject.objectId
                        self.frameNode?.name = personalPinPhotoObject.objectId
                    }
                }
            }
        }
    }
    func discard(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        let fadeAction = SCNAction.fadeOut(duration: 0.3)
        rootNode.runAction(fadeAction, completionHandler: { self.rootNode.removeFromParentNode(); completion(true) } )
    }
    
    func deleteFromDB(for user: PFUser, id: String) {
        DispatchQueue.global(qos: .background).async {
            let personalPinPhotoQuery = PFQuery(className: "PersonalPinPhoto")
            personalPinPhotoQuery.getObjectInBackground(withId: id) { (pinPhotoObject, error) in
                if error == nil {
                    pinPhotoObject!.deleteInBackground()
                }
            }
        }
    }
    
    func deleteFromDB(for venue: Venue, id: String) {
        let venueQuery = PFQuery(className: "Venue")
        venueQuery.getObjectInBackground(withId: venue.id) { (venueObject, error) in
            if error == nil {
                let photosRelation = venueObject!.relation(forKey: "Photos")
                let photosQuery = photosRelation.query()
                photosQuery.getObjectInBackground(withId: id) { (pinPhotoObject, error) in
                    if error == nil {
                        photosRelation.remove(pinPhotoObject!)
                        pinPhotoObject!.deleteInBackground()
                    }
                }
            }
        }
    }
}
