//
//  Pyramid.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Pyramid: SCNNode {
    
    let width: CGFloat = 0.06
    let height: CGFloat = 0.15
    
    var pyramidGeometry: SCNPyramid
    
    override init() {
        pyramidGeometry = SCNPyramid(width: width, height: height, length: width)
        
        super.init()
        
        geometry = pyramidGeometry
        
        categoryBitMask = NodeCategories.pyramid.rawValue
        let normalImageURL = Bundle.main.url(forResource: "NormalMapWeatherWOod", withExtension: "jpg", subdirectory: "art.scnassets/WoodenBrick")!
        let normalImageData = try! Data.init(contentsOf: normalImageURL)
        let normalMapImage = UIImage(data: normalImageData)
        
        // material for the geometry
        geometry?.firstMaterial?.diffuse.contents = UIImage(named: "PyramidMaterial")
        geometry?.firstMaterial?.normal.contents = normalMapImage
        geometry?.firstMaterial?.lightingModel = .physicallyBased
        geometry?.firstMaterial?.roughness.contents = 1.0
        geometry?.firstMaterial?.shininess = 0.0
        
        // adjust pivot to the bottom of the geometry
        let (min, max) = boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y
        let dz = min.z + 0.5 * (max.z - min.z)
        
        pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        // physics
        let shapeTransform = SCNMatrix4MakeTranslation(-dx, -dy, -dz)
        let shapeTransformValue = NSValue.init(scnMatrix4: shapeTransform)
        
        let pyramidShape = SCNPhysicsShape(geometry: pyramidGeometry, options: [:])
        let overallShape = SCNPhysicsShape(shapes: [pyramidShape], transforms: [shapeTransformValue])
        
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: overallShape)
        physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
