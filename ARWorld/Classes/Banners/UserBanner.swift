//
//  UserBanner.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class UserBanner: SCNNode {
    
    // MARK: - Properties
    let id: String
    
    var childNode = SCNNode()
    
    var isTargeted: Bool = false {
        didSet {
            guard oldValue != isTargeted else { return }
            if isTargeted {
                makeBigger()
            } else {
                normalSize()
            }
        }
    }
    
    var visitPortalBoxPosition: SCNVector3 {
        let (min, max) = photoPlane.presentation.boundingBox
        let x = max.x
        let y = min.y
        
        return SCNVector3Make(x, y, 0)
    }
    var statusBoxPosition: SCNVector3 {
        let (min, max) = photoPlane.presentation.boundingBox
        let x = min.x
        let y = max.y
        
        return SCNVector3.init(x, y, 0)
    }
    
    var giftBoxPosition: SCNVector3 {
        let max = photoPlane.presentation.boundingBox.max
        
        return SCNVector3.init(max.x, max.y, 0)
    }
    
    var tempScale: SCNVector3!
    
    var location: CLLocation
    
    // MARK: - Visual Elements
    let photoPlane: PhotoPlane
    var statusBox: StatusBox
    var giftBox: GiftBox
    var visitPortal: VisitPortalBox
    
    // MARK: - Initialization
    init(id: String, location: CLLocation) {
        photoPlane = PhotoPlane(id: id)
        statusBox = StatusBox(id: id)
        giftBox = GiftBox(id: id)
        visitPortal = VisitPortalBox(id: id)
        
        self.id = id
        self.location = location
        
        super.init()
        addChildNode(childNode)
        childNode.addChildNode(photoPlane)
        
        // Set Billboard Constraints
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
    }
    
    func makeBigger() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            self.statusBox.position = self.statusBoxPosition
            self.childNode.addChildNode(self.statusBox)
            
            self.giftBox.position = self.giftBoxPosition
            self.childNode.addChildNode(self.giftBox)
            
            self.visitPortal.position = self.visitPortalBoxPosition
            self.childNode.addChildNode(self.visitPortal)
        }
        tempScale = childNode.scale
        childNode.scale = SCNVector3Make(childNode.scale.x * 2, childNode.scale.y * 2, childNode.scale.z * 2)
        
        SCNTransaction.commit()
    }
    
    func normalSize() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            self.statusBox.removeFromParentNode()
            self.giftBox.removeFromParentNode()
            self.visitPortal.removeFromParentNode()
        }
        
        childNode.scale = tempScale
        
        SCNTransaction.commit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
