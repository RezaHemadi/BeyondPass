//
//  Cube.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Cube: SCNNode {
    let width: CGFloat = 0.06
    let height: CGFloat = 0.15
    
    let cubeGeometry: SCNBox
    
    override init() {
        cubeGeometry = SCNBox(width: width, height: height, length: width, chamferRadius: 0)
        
        super.init()
        
        geometry = cubeGeometry
        
        categoryBitMask = NodeCategories.cube.rawValue
        let normalImageURL = Bundle.main.url(forResource: "NormalMapWeatherWOod", withExtension: "jpg", subdirectory: "art.scnassets/WoodenBrick")!
        let normalImageData = try! Data.init(contentsOf: normalImageURL)
        let normalMapImage = UIImage(data: normalImageData)
        
        // set the material for the geometry
        geometry?.firstMaterial?.diffuse.contents = UIImage(named: "CylinderMaterial")!
        geometry?.firstMaterial?.normal.contents = normalMapImage
        geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometry?.firstMaterial?.roughness.contents = 1.0
        geometry?.firstMaterial?.shininess = 0.0
        
        // place the pivot at the bottom of the geometry
        let (min, max) = boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        
        pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        // physics
        let shapeTransformMatrix = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
        let shapeTransformValue = NSValue.init(scnMatrix4: shapeTransformMatrix)
        
        let cubeShape = SCNPhysicsShape(geometry: cubeGeometry, options: [:])
        let overallShape = SCNPhysicsShape(shapes: [cubeShape], transforms: [shapeTransformValue])
        
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: overallShape)
        physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
