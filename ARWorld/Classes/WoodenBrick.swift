//
//  WoodenBrick.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/5/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class WoodenBrick: SCNReferenceNode {
    
    // MARK: - Properties
    
    let url = Bundle.main.url(forResource: "WoodenBrick", withExtension: "scn", subdirectory: "art.scnassets/WoodenBrick")!
    
    init() {
        super.init(url: url)!
        loadingPolicy = .onDemand
        
        loadModel { (succeed) in
            DispatchQueue.global(qos: .userInitiated).async {
                self.adjustChildNodes()
                self.enablePhysics()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The Model is Z-up so it needs to be rotated 90 degrees
    func adjustChildNodes() {
        let brick = childNode(withName: "brick", recursively: true)!
        brick.eulerAngles = SCNVector3Make(-.pi / 2, 0, 0)
        
        let (min, max) = boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        
        brick.position = SCNVector3Make(-dx, -dy, -dz)
        brick.geometry?.firstMaterial?.shininess = 0.1
        brick.geometry?.firstMaterial?.roughness.contents = 0.9
    }
    
    func loadModel(_ completion: @escaping (_ succeed: Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.load()
            completion(true)
        }
    }
    
    func enablePhysics() {
        let (min, max) = boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        
        let boxShape = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0)
        
        let shape = SCNPhysicsShape(geometry: boxShape, options: nil)
        
        let transform = SCNMatrix4MakeTranslation(dx, dy, dz)
        let transformValue = NSValue.init(scnMatrix4: transform)
        let finalShape = SCNPhysicsShape(shapes: [shape], transforms: [transformValue])
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: finalShape)
        physicsBody.mass = 2.0
        physicsBody.friction = 1.0
        physicsBody.rollingFriction = 1.0
        physicsBody.restitution = 0.0
        self.physicsBody = physicsBody
    }
}
