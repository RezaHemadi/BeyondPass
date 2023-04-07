//
//  UserBanner+GiftBox.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/10/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension UserBanner {
    
    class GiftBox: SCNNode {
        
        // MARK: - Properties
        let id: String
        private let textGeometry = SCNText(string: "Gift", extrusionDepth: 1.0)
        private let boxGeometry = SCNBox(width: 4, height: 2, length: 2, chamferRadius: 0.3)
        private let boxNode: SCNNode
        private let textNode: SCNNode
        
        // MARK: - Initialization
        init(id: String) {
            self.id = id
            
            // Setup Box
            boxNode = SCNNode(geometry: boxGeometry)
            boxGeometry.firstMaterial?.diffuse.contents = UIColor.yellow
            boxGeometry.firstMaterial?.transparency = 0.5
            boxGeometry.firstMaterial?.lightingModel = .physicallyBased
            boxGeometry.firstMaterial?.emission.contents = UIColor.yellow
            boxGeometry.firstMaterial?.metalness.contents = 1.0
            boxNode.adjustPivot(to: .center)
            boxNode.name = id
            boxNode.categoryBitMask = NodeCategories.giftBox.rawValue
            
            
            // Setup Text
            textGeometry.containerFrame = CGRect(x: 0, y: 0, width: 40, height: 20)
            textGeometry.font = UIFont(name: "Futura", size: 15)
            textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
            textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.isDoubleSided = true
            textGeometry.firstMaterial?.lightingModel = .physicallyBased
            textGeometry.firstMaterial?.metalness.contents = 0.8
            textGeometry.firstMaterial?.shininess = 1.0
            textGeometry.firstMaterial?.emission.contents = UIColor.white
            textGeometry.chamferRadius = CGFloat(5)
            textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
            textNode.adjustPivot(to: .center)
            
            super.init()
            
            // Add Child Nodes
            DispatchQueue.global(qos: .background).async {
                self.addChildNode(self.boxNode)
                self.addChildNode(self.textNode)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
