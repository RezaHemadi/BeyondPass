//
//  Brick.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/20/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Brick: Model {
    
    let brickScale = float3(0.01, 0.01, 0.01)
    
    static var isBrickContactSoundPlaying: Bool = false
    
    override init?(url: URL) {
        
        super.init(url: url)
        load()
        /*
        if let brickNode = self.childNodes.first {
            // adjust the pivot of the brick
            brickNode.simdScale = self.brickScale
            
            let (min, max) = brickNode.boundingBox
            
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z
            
            let buttom = SCNVector3Make(dx, dy, dz)
            
            let globalButtom = brickNode.convertPosition(buttom, to: self)
            
            brickNode.position = globalButtom
            
            //enablePhysics(brickNode)
            
            
            brickNode.categoryBitMask = NodeCategories.brick.rawValue
        }
 */
    }
 
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enablePhysics(_ node: SCNNode) {
        
        // Create a geometry representing the brick geometry
        let boxGeometry = SCNBox(width: 19.991, height: 11.012, length: 4.84, chamferRadius: 0)
        
        // Create a temp node to extract it's transform
        let tempNode = SCNNode()
        tempNode.simdTransform.translation = float3(0, 0, 0.03)
        
        // Create a transformation for the shape
        let shapeTransform = tempNode.transform
        let shapeTransformValue = NSValue.init(scnMatrix4: shapeTransform)
        
        let scale = NSValue.init(scnVector3: SCNVector3.init(0.01, 0.01, 0.01))
        let options: [SCNPhysicsShape.Option: Any] = [.scale : scale]
        let boxPhysicsShape = SCNPhysicsShape(geometry: boxGeometry, options: options)
        let overalPhysicsShape = SCNPhysicsShape(shapes: [boxPhysicsShape], transforms: [shapeTransformValue])
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: overalPhysicsShape)
        
        // configure physical characteristics
        physicsBody.mass = 5
        physicsBody.allowsResting = false
        physicsBody.friction = 1
        physicsBody.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody.contactTestBitMask = BodyType.sandbox.rawValue
        
        node.physicsBody = physicsBody
    }
}

extension Brick {
    
    static func playBrickContactSound(brick: SCNNode) {
        guard !isBrickContactSoundPlaying else { return }
        
        let brickContactAudioSource = SCNAudioSource(named: "art.scnassets/Blue Brick/BrickDrop.wav")!
        let brickContactAudioPlayer = SCNAudioPlayer(source: brickContactAudioSource)
        brickContactAudioPlayer.willStartPlayback = { self.isBrickContactSoundPlaying = true }
        brickContactAudioPlayer.didFinishPlayback = { self.isBrickContactSoundPlaying = false }
        brick.addAudioPlayer(brickContactAudioPlayer)
    }
}
