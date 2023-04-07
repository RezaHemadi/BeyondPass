//
//  Cone.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Cone: SCNNode {
    let radius: CGFloat = (0.06)
    let height: CGFloat = (0.15)
    
    let coneGeometry: SCNCone
    
    override init() {
        coneGeometry = SCNCone(topRadius: 0, bottomRadius: radius, height: height)
        
        super.init()
        
        geometry = coneGeometry
        
        categoryBitMask = NodeCategories.cone.rawValue
        let normalImageURL = Bundle.main.url(forResource: "NormalMapWeatherWOod", withExtension: "jpg", subdirectory: "art.scnassets/WoodenBrick")!
        let normalImageData = try! Data.init(contentsOf: normalImageURL)
        let normalMapImage = UIImage(data: normalImageData)
        
        // set the material
        geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ConeMaterial")
        geometry?.firstMaterial?.normal.contents = normalMapImage
        geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometry?.firstMaterial?.roughness.contents = 1.0
        geometry?.firstMaterial?.shininess = 0.0
        
        // place the pivot at the bottom of the node
        let (min, max) = boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        
        pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        // configure physics for the current shape
        let bodyTransformMatrix = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
        let bodyTransformValue = NSValue.init(scnMatrix4: bodyTransformMatrix)
        
        let conePhysicsShape = SCNPhysicsShape(geometry: coneGeometry, options: [:])
        let overallPhysicsShape = SCNPhysicsShape(shapes: [conePhysicsShape], transforms: [bodyTransformValue])
        
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: overallPhysicsShape)
        physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
