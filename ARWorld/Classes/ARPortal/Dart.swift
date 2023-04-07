//
//  Dart.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import CoreMotion

class Dart: SCNReferenceNode {
    
    // MARK: - Types
    
    enum Variant {
        case right
        case left
    }
    
    enum State {
        case resting
        case preparedForThrow
        case flying
    }
    
    // MARK: - Properties
    
    let variant: Variant
    var isHit: Bool = false
    var state: State = .resting {
        didSet {
            switch state {
            case .resting:
                break
            case .preparedForThrow:
                break
            case .flying:
                break
            }
        }
    }
    
    // MARK: - Initialization
    
    init?(type: Variant) {
        var url: URL!
        var category: Int!
        variant = type
        switch type {
        case .right:
            url = Bundle.main.url(forResource: "Dart1", withExtension: "scn", subdirectory: "art.scnassets/Portal")
            category = NodeCategories.dart1.rawValue
        case .left:
            url = Bundle.main.url(forResource: "Dart2", withExtension: "scn", subdirectory: "art.scnassets/Portal")
            category = NodeCategories.dart2.rawValue
        }
        super.init(url: url!)
        self.loadingPolicy = .onDemand
        categoryBitMask = category
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadModel(completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.load()
            let root = self.childNode(withName: "root", recursively: true)!
            for node in root.childNodes {
               // node.renderingOrder = 200
            }
            completion(true, nil)
        }
    }
    func enablePhysics() {
        let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox]
        let physicsShape = SCNPhysicsShape(node: self, options: options)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = true
        physicsBody.mass = 0.3
        physicsBody.categoryBitMask = BodyType.portal.rawValue
        physicsBody.contactTestBitMask = BodyType.portal.rawValue
        self.physicsBody = physicsBody
    }
}
