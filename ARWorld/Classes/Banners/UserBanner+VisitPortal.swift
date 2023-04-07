//
//  UserBanner+VisitPortal.swift
//  ARWorld
//
//  Created by Reza Hemadi on 6/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension UserBanner {
    class VisitPortalBox: SCNNode {
        // MARK: - Properties
        
        let id: String
        private let textGeometry = SCNText(string: "Visit Portal", extrusionDepth: 1)
        private let boxGeometry = SCNBox(width: 8, height: 4, length: 4, chamferRadius: 0.6)
        private let boxNode: SCNNode
        private let textNode: SCNNode
        
        // MARK: - Initialization
        
        init(id: String) {
            self.id = id
            
            // Set up box
            boxNode = SCNNode(geometry: boxGeometry)
            boxGeometry.firstMaterial?.diffuse.contents = UIColor(red: 183/255.0, green: 161/255.0, blue: 33/255.0, alpha: 0.5)
            boxGeometry.firstMaterial?.transparency = 0.5
            boxGeometry.firstMaterial?.lightingModel = .physicallyBased
            boxGeometry.firstMaterial?.emission.contents = UIColor(red: 183/255.0, green: 161/255.0, blue: 33/255.0, alpha: 0.5)
            boxGeometry.firstMaterial?.metalness.contents = 1.0
            boxNode.adjustPivot(to: .center)
            boxNode.name = id
            boxNode.categoryBitMask = NodeCategories.visitPortal.rawValue
            
            // Setup Text
            textGeometry.containerFrame = CGRect(x: 0, y: 0, width: 80, height: 40)
            textGeometry.font = UIFont(name: "Futura", size: 16)
            textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
            textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.isDoubleSided = true
            textGeometry.firstMaterial?.lightingModel = .physicallyBased
            textGeometry.firstMaterial?.metalness.contents = 0.8
            textGeometry.firstMaterial?.shininess = 1.0
            textGeometry.chamferRadius = CGFloat(0)
            textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
            textNode.adjustPivot(to: .center)
            
            super.init()
            
            // Add Child Nodes
            DispatchQueue.global(qos: .background).async {
                self.addChildNode(self.boxNode)
                self.addChildNode(self.textNode)
            }
            
            scale = SCNVector3Make(0.5, 0.5, 0.5)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
