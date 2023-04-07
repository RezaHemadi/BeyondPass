//
//  Battery.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/9/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Battery: Model {
    let url = Bundle.main.url(forResource: "Battery", withExtension: "scn", subdirectory: "art.scnassets/Battery")!
    
    init() {
        super.init(url: url)!
        loadModel()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadModel(_ completion: @escaping (_ succeed: Bool?) -> Void = { _ in } ) {
        DispatchQueue.main.async {
            self.load()
            self.enablePhysics()
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
        self.physicsBody = physicsBody
    }
}
