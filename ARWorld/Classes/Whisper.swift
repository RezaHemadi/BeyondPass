//
//  Whisper.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

class Whisper {
    var node = SCNNode()
    var id: String!
    var user: PFObject!
    var text = "Whisper"
    var position: SCNVector3!
    var scalingFactor: Double!
    
    init(forUser: PFObject, forObject: PFObject, scalingFactor: Double = 1) {
        self.user = forUser
        self.id = forObject.objectId
        self.scalingFactor = scalingFactor
        self.node.categoryBitMask = NodeCategories.whisper.rawValue
        self.node.name = forObject.objectId
        
        setupPlane()
        setupUser()
    }
    
    func setupPlane() {
        let billBoardConstraint = SCNBillboardConstraint()
        billBoardConstraint.freeAxes = SCNBillboardAxis.Y
        let plane = SCNPlane(width: CGFloat(self.scalingFactor * 20), height: CGFloat(self.scalingFactor * 10))
        plane.cornerRadius = CGFloat(scalingFactor)
        plane.firstMaterial?.diffuse.contents = UIColor(red:0.27, green:0.60, blue:0.89, alpha:1.0)
        
        self.node = SCNNode(geometry: plane)
        self.node.constraints = [billBoardConstraint]
        
        let text = self.text
        let textGeometry = SCNText(string: text,
                                   extrusionDepth: 1)
        textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 10.0)
        textGeometry.font = UIFont(name: "Futura", size: 2.0)
        textGeometry.isWrapped = true
        textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.chamferRadius = CGFloat(0.2)
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3Make(Float(self.scalingFactor), Float(self.scalingFactor), Float(self.scalingFactor))
        
        center(node: textNode)
        textNode.position = SCNVector3Make(0, 0, 0.5)
        self.node.addChildNode(textNode)
    }
    
    func setupUser() {
        self.user.fetchInBackground {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                let imageData = user["profilePic"] as! PFFileObject
                imageData.getDataInBackground {
                    (data: Data?, error: Error?) -> Void in
                    if let data = data {
                        let profilePic = UIImage(data: data)
                        let plane = SCNPlane(width: CGFloat(self.scalingFactor * 20), height: CGFloat(self.scalingFactor * 20))
                        plane.firstMaterial?.diffuse.contents = profilePic
                        plane.cornerRadius = CGFloat(self.scalingFactor * 10)
                        let planeNode = SCNNode(geometry: plane)
                        let parentNode = self.node
                        let (_, max) = parentNode.boundingBox
                        buttom(planeNode)
                        planeNode.position = max
                        planeNode.categoryBitMask = NodeCategories.profilePic.rawValue
                        planeNode.name = user.objectId
                        self.node.addChildNode(planeNode)
                    }
                }
            }
        }
    }
}

