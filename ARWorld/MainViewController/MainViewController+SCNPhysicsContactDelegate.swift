//
//  MainViewController+SCNPhysicsContactDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        switch appMode {
        case .portal:
            switch portal!.dartboard.gameState {
            case .throwingDart:
                if let dart = contact.nodeA as? Dart {
                    dartHit(dart)
                } else if let dart = contact.nodeB as? Dart {
                    dartHit(dart)
                }
            default:
                break
            }
        case .sandbox:
            break
        default:
            break
        }
        let nodeACategory = NodeCategories.init(rawValue: contact.nodeA.categoryBitMask)!
        let nodeBCategory = NodeCategories.init(rawValue: contact.nodeB.categoryBitMask)!
        
        switch nodeACategory {
        case .brick:
            switch nodeBCategory {
            case .brick:
                Brick.playBrickContactSound(brick: contact.nodeA)
            case .surfacePlane:
                Brick.playBrickContactSound(brick: contact.nodeA)
            default:
                break
            }
        default:
            break
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
    private func dartHit(_ dart: Dart) {
        guard !dart.isHit else { return }
        dart.isHit = true
        DispatchQueue.main.async {
            self.currentDartGame?.playHitSound()
            
            let transform = dart.presentation.transform
            let rootTransform = self.sceneView.pointOfView!.convertTransform(transform, to: self.sceneView.scene.rootNode)
            dart.removeFromParentNode()
            let stoppedDart = Dart(type: dart.variant)!
            stoppedDart.loadModel() {
                (succeed, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        stoppedDart.transform = rootTransform
                        self.sceneView.scene.rootNode.addChildNode(stoppedDart)
                    }
                }
            }
        }
    }
}
