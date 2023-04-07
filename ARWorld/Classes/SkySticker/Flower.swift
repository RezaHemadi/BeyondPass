//
//  Flower.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension SkySticker {
    class Flower: SCNNode {
        // MARK: - Properties
        var anchor: ARAnchor?
        
        var isLoaded: Bool = false {
            didSet {
                let (min, max) = boundingBox
                let dx = min.x + 0.5 * (max.x - min.x)
                let dy = min.y + 0.5 * (max.y - min.y)
                let dz = min.z + 0.5 * (max.z - min.z)
                
                pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                scale = SCNVector3Make(0.001, 0.001, 0.001)
            }
        }
        
        override init() {
            super.init()
            
            let url = Bundle.main.url(forResource: "FlowerOutdoor", withExtension: "scn", subdirectory: "art.scnassets/Flower/Outdoor")!
            let referenceNode = SCNReferenceNode(url: url)!
            
            DispatchQueue.global(qos: .userInitiated).async {
                referenceNode.load()
                referenceNode.eulerAngles = SCNVector3Make(-.pi / 2, 0, 0)
                self.addChildNode(referenceNode)
                self.isLoaded = true
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}
