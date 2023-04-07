//
//  Grenade.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/24/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Grenade: Model {
    let url = Bundle.main.url(forResource: "Grenade", withExtension: "scn", subdirectory: "art.scnassets/Explosive")!
    
    var grenadeNode: SCNNode?
    
    var grenadeSoundSource: SCNAudioSource
    var grenadeAudioPlayer: SCNAudioPlayer
    
    init() {
        
        grenadeSoundSource = SCNAudioSource(named: "art.scnassets/Explosive/GrenadeThrowSound.wav")!
        grenadeAudioPlayer = SCNAudioPlayer(source: grenadeSoundSource)
        
        super.init(url: url)!
        
        load()
        
        if let grenadeNode = childNodes.first {
            self.grenadeNode = grenadeNode
            // adjust the pivot of the grenadeNode
            let (min, max) = grenadeNode.boundingBox
            
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z
            
            grenadeNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            
            grenadeNode.simdEulerAngles = float3(-(.pi / 2), 0, 0)
            
            grenadeNode.simdScale = float3(0.005, 0.005, 0.005)
            
            grenadeNode.categoryBitMask = NodeCategories.grenade.rawValue
            
            // configure physics
            let shapeScaleVector = SCNVector3.init(0.01, 0.01, 0.01)
            let shapeScaleValue = NSValue.init(scnVector3: shapeScaleVector)
            let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull,
                                                          SCNPhysicsShape.Option.scale: shapeScaleValue]
            let grenadeGeometry = grenadeNode.geometry!
            let grenadeShape = SCNPhysicsShape(geometry: grenadeGeometry, options: options)
            
            let grenadeShapeTransform = SCNMatrix4MakeTranslation(-dx * 0.005, -dy * 0.005, -dz * 0.005)
            let grenadeShapeTransformValue = NSValue.init(scnMatrix4: grenadeShapeTransform)
            
            let grenadeOverallShape = SCNPhysicsShape(shapes: [grenadeShape], transforms: [grenadeShapeTransformValue])
            
            grenadeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: grenadeOverallShape)
            grenadeNode.physicsBody?.mass = 5
            grenadeNode.physicsBody?.allowsResting = false
            grenadeNode.physicsBody?.friction = 1000
            grenadeNode.physicsBody?.rollingFriction = 300
            grenadeNode.physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
            grenadeNode.physicsBody?.isAffectedByGravity = false
        }
    }
    
    func playSound() {
        grenadeNode!.addAudioPlayer(grenadeAudioPlayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
