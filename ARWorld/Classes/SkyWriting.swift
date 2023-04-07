//
//  SkyWriting.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class SkyWriting: SCNNode {
    
    // MARK: - Configuration
    
    let color = UIColor(red: 72/255.0, green: 112/255.0, blue: 242/255.0, alpha: 1)
    let font = UIFont(name: "HelveticaNeue", size: 20)
    let InitialScale = SCNVector3Make(0.01, 0.01, 0.01)
    let extrusionDepth: CGFloat = 8.0
    
    // MARK: - Properties
    
    var text: String
    var textNode: SCNNode
    var textGeometry: SCNText
    var author: PFUser
    /// id is the object id of the skywriting object stored in the db
    var id: String?
    var location: CLLocation
    var geoPoint: PFGeoPoint
    var savedInDB: Bool = false
    var anchor: ARAnchor?
    
    // MARK: - Initialization
    
    init(_ text: String, author: PFUser, location: CLLocation) {
        self.location = location
        self.geoPoint = PFGeoPoint(location: location)
        self.text = text
        self.author = author
        textGeometry = SCNText(string: text, extrusionDepth: extrusionDepth)
        
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.chamferRadius = 50
        textGeometry.font = font
        textNode = SCNNode(geometry: textGeometry)
        textNode.categoryBitMask = NodeCategories.skyWriting.rawValue
        
        super.init()
        addChildNode(textNode)
        
        adjustPivot(to: .center)
        scale = InitialScale
        categoryBitMask = NodeCategories.skyWriting.rawValue
        setupMaterial()
    }
    init(textObject: PFObject) {
        savedInDB = true
        text = textObject["value"] as! String
        geoPoint = textObject["location"] as! PFGeoPoint
        location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        author = textObject["user"] as! PFUser
        self.id = textObject.objectId!
        
        textGeometry = SCNText(string: text, extrusionDepth: extrusionDepth)
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.chamferRadius = 5.0
        textGeometry.font = font
        textNode = SCNNode(geometry: textGeometry)
        textNode.adjustPivot(to: .center)
        textNode.categoryBitMask = NodeCategories.skyWriting.rawValue
        
        super.init()
        addChildNode(textNode)
        adjustPivot(to: .center)
        scale = InitialScale
        categoryBitMask = NodeCategories.skyWriting.rawValue
        setupMaterial()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Database
    
    func saveInDataBase(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        let skyWritingObject = PFObject(className: "text")
        skyWritingObject["value"] = text
        skyWritingObject["location"] = geoPoint
        skyWritingObject["user"] = author
        skyWritingObject.saveInBackground {
            (succeed: Bool?, error: Error?) -> Void in
            if succeed == true {
                self.id = skyWritingObject.objectId!
                self.name = skyWritingObject.objectId!
                self.savedInDB = true
                completion(succeed, error)
            } else if let error = error {
                completion(succeed, error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func setupMaterial() {
        textGeometry.firstMaterial?.diffuse.contents = color
        textGeometry.firstMaterial?.lightingModel = .physicallyBased
        textGeometry.firstMaterial?.shininess = 1.0
        textGeometry.firstMaterial?.metalness.contents = 0.5
        textGeometry.firstMaterial?.roughness.contents = 0.3
    }
}
