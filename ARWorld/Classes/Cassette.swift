//
//  Cassette.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class Cassette: SCNNode {
    // MARK: - Properties
    
    var location: CLLocation
    
    var geoPoint: PFGeoPoint
    
    var data: Data?
    
    var file: PFFileObject?
    
    var author: PFUser
    
    var isModelLoaded: Bool = false
    
    private var cassetteNode: SCNNode?
    
    var id: String?
    
    var dataLoaded: Bool = false
    
    var savedInDB: Bool
    
    var anchor: ARAnchor?
    
    // MARK: - Initializers
    
    init(location: CLLocation, author: PFUser) {
        savedInDB = false
        self.location = location
        geoPoint = PFGeoPoint(location: location)
        self.author = author
        super.init()
        categoryBitMask = NodeCategories.cassette.rawValue
        
        let cassetteURL = Bundle.main.url(forResource: "Cassette", withExtension: "scn", subdirectory: "art.scnassets")!
        let cassetteReferenceNode = SCNReferenceNode(url: cassetteURL)!
        
        DispatchQueue.main.async {
            cassetteReferenceNode.load()
            self.cassetteNode = cassetteReferenceNode.childNodes.first!
            self.cassetteNode!.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
            self.cassetteNode!.scale = SCNVector3Make(0.01, 0.01, 0.01)
            self.cassetteNode!.categoryBitMask = NodeCategories.cassette.rawValue
            self.addChildNode(self.cassetteNode!)
            self.adjustPivot(to: .center)
            self.isModelLoaded = true
        }
    }
    
    init(cassetteObject: PFObject) {
        savedInDB = true
        author = cassetteObject["addedBy"] as! PFUser
        let audio = cassetteObject["audio"] as! PFFileObject
        geoPoint = cassetteObject["location"] as! PFGeoPoint
        location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        id = cassetteObject.objectId!
        file = audio
        
        super.init()
        categoryBitMask = NodeCategories.cassette.rawValue
        name = cassetteObject.objectId
        
        let cassetteURL = Bundle.main.url(forResource: "Cassette", withExtension: "scn", subdirectory: "art.scnassets")!
        let cassetteReferenceNode = SCNReferenceNode(url: cassetteURL)!
        
        DispatchQueue.main.async {
            cassetteReferenceNode.load()
            self.cassetteNode = cassetteReferenceNode.childNodes.first!
            self.cassetteNode!.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
            self.cassetteNode!.scale = SCNVector3Make(0.007, 0.007, 0.007)
            self.cassetteNode!.categoryBitMask = NodeCategories.cassette.rawValue
            self.cassetteNode!.name = cassetteObject.objectId
            self.addChildNode(self.cassetteNode!)
            self.adjustPivot(to: .center)
            self.isModelLoaded = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Database
    
    func loadData(_ completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard file != nil else { return }
        
        DispatchQueue.global(qos: .background).async {
            do {
            let fileData = try self.file!.getData()
            self.data = fileData
            self.dataLoaded = true
            completion(fileData, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func saveToDB(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        let cassetteObject = PFObject(className: "Cassette")
        cassetteObject["addedBy"] = author
        cassetteObject["audio"] = PFFileObject(data: data!)
        cassetteObject["location"] = geoPoint
        
        cassetteObject.saveInBackground {
            (succeed, error) in
            if succeed == true {
                self.savedInDB = true
                self.id = cassetteObject.objectId
                self.name = cassetteObject.objectId
                self.cassetteNode?.name = cassetteObject.objectId
                completion(true, nil)
            } else {
                completion(succeed, error)
            }
        }
    }
}
