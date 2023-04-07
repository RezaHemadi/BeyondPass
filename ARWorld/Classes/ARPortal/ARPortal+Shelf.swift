//
//  ARPortal+Shelf.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/21/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class Shelf {
        // MARK: - Properties
        
        var node: SCNNode
        var pipe: SCNNode
        var glass: SCNNode
        var index: Int
        
        var placeHolder: SCNVector3 {
            let (min, max) = glass.boundingBox
            let x = min.x + 0.5 * (max.x - min.x)
            let y = min.y + 0.5 * (max.y - min.y)
            let z = max.z
            
            return glass.convertPosition(SCNVector3Make(x, y, z), to: node)
        }
        
        init(node: SCNNode, index: Int) {
            self.node = node
            self.index = index
            
            pipe = node.childNode(withName: "Pipe", recursively: false)!
            glass = node.childNode(withName: "Shelf", recursively: false)!
        }
    }
}
