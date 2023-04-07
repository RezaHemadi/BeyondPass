//
//  Ball.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/21/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Ball: SCNNode {
    
    let radius: CGFloat = 0.05
    
    var ballKickAudioSource: SCNAudioSource
    var ballKickAudioPlayer: SCNAudioPlayer
    
    override init() {
        
        ballKickAudioSource = SCNAudioSource(named: "art.scnassets/BallKick.wav")!
        ballKickAudioPlayer = SCNAudioPlayer(source: ballKickAudioSource)
        
        super.init()
        
        
        let sphereGeometry = SCNSphere(radius: self.radius)
            
        self.categoryBitMask = NodeCategories.ball.rawValue
            
        let diffuseURL = Bundle.main.url(forResource: "Hexagon-Diffuse", withExtension: "jpg", subdirectory: "art.scnassets/Robot/HexagonTexture")!
        let normalURL = Bundle.main.url(forResource: "Hexagon-normal", withExtension: "jpg", subdirectory: "art.scnassets/Robot/HexagonTexture")!
            
        let diffuse = try! UIImage(data: Data.init(contentsOf: diffuseURL))
        let normal = try! UIImage(data: Data.init(contentsOf: normalURL))
            
        sphereGeometry.firstMaterial?.diffuse.contents = diffuse
        sphereGeometry.firstMaterial?.normal.contents = normal
        sphereGeometry.firstMaterial?.lightingModel = .physicallyBased
            
            
            
        self.geometry = sphereGeometry
            
        self.simdPosition = float3(0, 0, -0.2)
            
        // Physics
        let ballShape = SCNPhysicsShape(geometry: sphereGeometry, options: [:])
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: ballShape)
        self.physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        self.physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    func playKickSound() {
        addAudioPlayer(ballKickAudioPlayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
