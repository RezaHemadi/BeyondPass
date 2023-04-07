//
//  Cylinder.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/22/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Cylinder: SCNNode {
    let radius = CGFloat(0.03)
    let height = CGFloat(0.15)
    
    let cylinderGeometry: SCNCylinder
    
    override init() {
        cylinderGeometry = SCNCylinder(radius: radius, height: height)
        
        super.init()
        
        geometry = cylinderGeometry
        
        categoryBitMask = NodeCategories.cylinder.rawValue
        
        let normalImageURL = Bundle.main.url(forResource: "NormalMapWeatherWOod", withExtension: "jpg", subdirectory: "art.scnassets/WoodenBrick")!
        let normalImageData = try! Data.init(contentsOf: normalImageURL)
        let normalMapImage = UIImage(data: normalImageData)
        
        // place material for the geometry
        geometry?.firstMaterial?.diffuse.contents = UIImage(named: "CylinderMaterial")!
        geometry?.firstMaterial?.normal.contents = normalMapImage
        geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometry?.firstMaterial?.roughness.contents = 1.0
        geometry?.firstMaterial?.shininess = 0.0
        
        // Place the pivot at the bottom of the geometry
        let (min, max) = boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        
        pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        // configure physics
        let inversePivotTransform = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
        let bodyTransformValue = NSValue.init(scnMatrix4: inversePivotTransform)
        let cylinderPhysicsShape = SCNPhysicsShape(geometry: cylinderGeometry, options: [:])
        let overalPhysicsShape = SCNPhysicsShape(shapes: [cylinderPhysicsShape], transforms: [bodyTransformValue])
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: overalPhysicsShape)
        physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
