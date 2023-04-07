//
//  MainViewController+DartGameDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import CoreMotion

extension MainViewController: DartGameDelegate {
    func dartGameDidEnd(_ game: DartGame) {
        game.reticle?.removeFromSuperview()
        currentDartGame = nil
    }
    func dartGame(_ game: DartGame, equippedNewDart dartType: Dart.Variant) {
        DispatchQueue.main.async {
            game.equipDart(variant: dartType)
            game.equippedDart?.transform = self.equippedDartInitialTransform()
            //game.equippedDart?.opacity = 0.6
            game.equippedDart?.loadModel(completion: { (succeed, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        self.sceneView.pointOfView?.addChildNode(game.equippedDart!)
                        let movingAction = SCNAction.move(by: SCNVector3Make(0.1, 0.10, -0.4), duration: 0.5)
                        let rotationAction = SCNAction.rotateTo(x: 50 * .pi / 180, y: 0, z: -45 * .pi / 180, duration: 0.5)
                        let action = SCNAction.group([movingAction, rotationAction])
                        game.equippedDart?.runAction(action)
                    }
                }
            })
        }
    }
    func dartGame(_ game: DartGame, didBeginWith dartType: Dart.Variant) {
        DispatchQueue.main.async {
            self.currentDartGame = game
            game.equipDart(variant: dartType)
            game.equippedDart?.transform = self.equippedDartInitialTransform()
            //game.equippedDart?.opacity = 0.6
            game.equippedDart?.loadModel(completion: { (succeed, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        self.sceneView.pointOfView?.addChildNode(game.equippedDart!)
                        let movingAction = SCNAction.move(by: SCNVector3Make(0.1, 0.10, -0.4), duration: 0.5)
                        let rotationAction = SCNAction.rotateTo(x: 50 * .pi / 180, y: 0, z: -45 * .pi / 180, duration: 0.5)
                        let action = SCNAction.group([movingAction, rotationAction])
                        game.equippedDart?.runAction(action)
                        game.setReticle(self.showDartReticle())
                        game.reticle?.addTarget(self, action: #selector(self.prepareDartThrow(sender:)), for: .touchDown)
                    }
                }
 
            })
        }
        // Start Accelerometer Updates
        self.motionManager.deviceMotionUpdateInterval = 0.001
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (deviceMotion, error) in
            if error == nil {
                let userAcceleration = deviceMotion!.userAcceleration
                guard userAcceleration.z < 0 else { return }
                
                self.deviceMotions.append(deviceMotion!)
            }
        }
    }
    
    private func equippedDartRestingTransform() -> SCNMatrix4 {
        let tempNode = SCNNode()
        tempNode.eulerAngles = SCNVector3Make(50 * .pi / 180, 0, -45 * .pi / 180)
        tempNode.position = SCNVector3Make(0.1, -0.15, -0.5)
        
        return tempNode.transform
    }
    private func equippedDartInitialTransform() -> SCNMatrix4 {
        let tempNode = SCNNode()
        tempNode.position = SCNVector3Make(0, -0.3, -0.1)
        
        return tempNode.transform
    }
    private func showDartReticle() -> DartReticleView {
        let reticle = DartReticleView()
        view.addSubview(reticle)
        reticle.translatesAutoresizingMaskIntoConstraints = false
        
        var widthConstraint: NSLayoutConstraint
        
        let centerVertically = NSLayoutConstraint(item: reticle, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.5, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: reticle, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        
        switch view.traitCollection.horizontalSizeClass {
        case .compact:
            widthConstraint = NSLayoutConstraint(item: reticle, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.3, constant: 0)
        case .regular:
            widthConstraint = NSLayoutConstraint(item: reticle, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.2, constant: 0)
        default:
            widthConstraint = NSLayoutConstraint(item: reticle, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.3, constant: 0)
        }
        let aspectRatio = NSLayoutConstraint(item: reticle, attribute: .width, relatedBy: .equal, toItem: reticle, attribute: .height, multiplier: 1, constant: 0)
        
        reticle.addConstraint(aspectRatio)
        view.addConstraints([centerVertically,
                             centerHorizontally,
                             widthConstraint])
        return reticle
    }
    @objc private func prepareDartThrow(sender: DartReticleView) {
        
        let tempNode = SCNNode()
        tempNode.eulerAngles = SCNVector3Make(110 * .pi / 180, 0, 0)
        let rotation = tempNode.rotation
        let rotationAction = SCNAction.rotate(toAxisAngle: rotation, duration: 0.2)
        let movingAction = SCNAction.move(to: SCNVector3Make(0, 0, -0.3), duration: 0.2)
        let opacityAction = SCNAction.fadeOpacity(to: 1, duration: 0.2)
        let action = SCNAction.group([rotationAction,
                                      movingAction,
                                      opacityAction])
        currentDartGame?.equippedDart?.runAction(action) {
            self.currentDartGame?.equippedDart?.state = .preparedForThrow
            sender.addTarget(self, action: #selector(self.throwDart(sender:)), for: .touchUpInside)
        }
    }
    @objc private func throwDart(sender: DartReticleView) {
        // Process acceleration data
        DispatchQueue.main.async {
            self.currentDartGame?.equippedDart?.removeAllActions()
            let position = self.currentDartGame?.equippedDart?.presentation.position
            
            self.currentDartGame?.equippedDart?.position = position!
            self.currentDartGame?.equippedDart?.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
            
            // Apply force to the dart
            self.currentDartGame?.equippedDart?.enablePhysics()
            
            self.deviceMotions.keepLast(6)
            let highestAcceleration = self.deviceMotions.max { (motion1, motion2) -> Bool in
                let magnitude1 = sqrt(motion1.userAcceleration.x * motion1.userAcceleration.x + motion1.userAcceleration.y * motion1.userAcceleration.y + motion1.userAcceleration.z * motion1.userAcceleration.z)
                let magnitude2 = sqrt(motion2.userAcceleration.x * motion2.userAcceleration.x + motion2.userAcceleration.y * motion2.userAcceleration.y + motion2.userAcceleration.z * motion2.userAcceleration.z)
                
                if magnitude2 > magnitude1 {
                    return true
                }
                return false
            }
            let simdHighestAcceleration = float3(Float(highestAcceleration!.userAcceleration.x), Float(highestAcceleration!.userAcceleration.y), Float(highestAcceleration!.userAcceleration.z))
            let forceVector = float3(0, 0, -simd_length(simdHighestAcceleration))
            
            let rootForce = self.sceneView.pointOfView!.simdConvertVector(forceVector, to: self.sceneView.scene.rootNode)
            self.currentDartGame?.equippedDart?.physicsBody!.applyForce(SCNVector3Make(rootForce.x, rootForce.y, rootForce.z), asImpulse: true)
            self.currentDartGame?.equippedDartThrown()
            self.deviceMotions.removeAll()
        }
    }
}
