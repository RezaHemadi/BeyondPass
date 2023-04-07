//
//  Dragon.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit
extension SkySticker {
    class Dragon: SCNNode {
        // MARK: - Properties
        var anchor: ARAnchor?
        var isLoaded: Bool = false {
            didSet {
                let (min, max) = boundingBox
                let dx = min.x + 0.5 * (max.x - min.x)
                let dy = min.y + 0.5 * (max.y - min.y)
                let dz = min.z + 0.5 * (max.z - min.z)
                
                pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                scale = SCNVector3Make(0.005, 0.005, 0.005)
            }
        }
        
        override init() {
            super.init()
            
            let url = Bundle.main.url(forResource: "Dragon", withExtension: "dae", subdirectory: "art.scnassets")!
            let referenceNode = SCNReferenceNode(url: url)!
            
            DispatchQueue.global(qos: .userInitiated).async {
                referenceNode.load()
                let cubeNode = referenceNode.childNode(withName: "Cube", recursively: true)!
                cubeNode.geometry?.materials.forEach( { $0.lightingModel = .physicallyBased })
                self.addChildNode(referenceNode)
                self.isLoaded = true
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
