//
//  MainViewController+InventoryDockDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: InventoryDockDelegate {
    func inventoryDock(_ dock: InventoryDock, didSelectThrowable item: AnyObject) {
        // check if the throwable item is a ball
        if let ball = item as? Ball, let camera = self.sceneView.pointOfView {
            // throw the ball from the center of the screen with a force applied
            camera.addChildNode(ball)
            
            // Add the ball the sandboxNodes array
            sandboxNodes?.append(ball)
            
            // detemine the direction of the force to be applied to the ball
            let localForceDirection = SCNVector3.init(0, 0, -5)
            let worldForceDirection = camera.convertVector(localForceDirection, to: sceneView.scene.rootNode)
            
            ball.physicsBody?.applyForce(worldForceDirection, asImpulse: true)
            
            // Play Ball kick sound
            ball.playKickSound()
            
        } else if let grenade = item as? Grenade, let camera = self.sceneView.pointOfView {
            // throw the ball from the center of the screen with a force applied
            let grenadeCopy = grenade.copy() as! Grenade
            camera.addChildNode(grenadeCopy)
            
            // Add the grenade to the sandboxNodes array
            sandboxNodes?.append(grenadeCopy)
            
            // detemine the direction of the force to be applied to the ball
            let localForceDirection = SCNVector3.init(0, 0, -15)
            let worldForceDirection = camera.convertVector(localForceDirection, to: sceneView.scene.rootNode)
            
            grenadeCopy.playSound()
            
            let when = DispatchTime.now()
            
            DispatchQueue.main.asyncAfter(deadline: when + 0.4) {
                grenadeCopy.grenadeNode?.physicsBody?.isAffectedByGravity = true
                grenadeCopy.grenadeNode?.physicsBody?.applyForce(worldForceDirection, asImpulse: true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: when + 1.7) {
                self.explode(grenade: grenadeCopy)
            }
        }
    }
    
    func dockDidCollapse(_ dock: OptionsDock) {
        if dock is InventoryDock {
            focusSquare?.hide()
        }
    }
    
    func dockDidExpand(_ dock: OptionsDock) {
        if dock is InventoryDock {
            focusSquare?.unhide()
        }
    }
    
    func inventoryDock(_ dock: InventoryDock, didSelectItem item: InventoryItem.Shape) {
        // Lock the surface plane
   /*     if let hitTest = sceneView.modelHitTestWithPhysics(screenCenter) {
            if let surfacePlane = hitTest.node as? SurfacePlane {
                surfacePlane.locked = true
            }
        } */
        
        switch item {
        case .complex(let model):
            DispatchQueue.main.async {
                let copy = model.copy() as! Model
                self.placeVirtualObject(copy)
                self.sandboxNodes?.append(copy)
            }
        case .simple(let node):
            DispatchQueue.main.async {
                let copy = node.copy() as! SCNNode
                self.placeNode(copy)
                self.sandboxNodes?.append(copy)
            }
        }
    }
    
    
    func placeVirtualObject(_ virtualObject: Model) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquareAlignment = focusSquare?.recentFocusSquareAlignments.last,
            focusSquare?.state != .initializing else {
                return
        }
        
        // The focus square transform may contain a scale component, so reset scale to 1
        if let focusSquare = self.focusSquare {
            
            let focusSquareScaleInverse = 1.0 / (focusSquare.simdScale.x)
            let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
            let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
            
            virtualObject.setTransform(focusSquareTransformWithoutScale,
                                       relativeTo: cameraTransform,
                                       smoothMovement: false,
                                       alignment: focusSquareAlignment,
                                       allowAnimation: false)
        }
        
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            //self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
    }
    func placeNode(_ node: SCNNode) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            focusSquare?.state != .initializing else {
                return
        }
        
        // The focus square transform may contain a scale component, so reset scale to 1
        if let focusSquare = self.focusSquare {
            
            
            let focusSquareScaleInverse = 1.0 / (focusSquare.simdScale.x)
            let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
            let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
            
            node.setTransform(focusSquareTransformWithoutScale,
                              relativeTo: cameraTransform)
 
            if let camera = sceneView.pointOfView {
                node.eulerAngles.y = camera.eulerAngles.y
            }
        }
        
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(node)
            //self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
    }
    
    func explode (grenade: Grenade) {
        // find all the nodes in 5 meters perimeter
        var nearNodes = sceneView.scene.rootNode.childNodes {
            (node: SCNNode, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            stop.pointee = false
            
            if simd_length(grenade.grenadeNode!.presentation.simdWorldPosition - node.presentation.simdWorldPosition) < 3 {
                if node == grenade { return false }
                return true
            }
            return false
        }
        
        nearNodes = nearNodes.map {
            (node) -> SCNNode in
            if let referenceNode = node as? SCNReferenceNode {
                return referenceNode.childNodes.first!
            } else {
                return node
            }
        }
        
        // Add fire
        let explosionFire = SCNParticleSystem(named: "ExplosionFire", inDirectory: nil)!
        let fireNode = SCNNode()
        fireNode.transform = grenade.grenadeNode!.presentation.worldTransform
        sceneView.scene.rootNode.addChildNode(fireNode)
        fireNode.addParticleSystem(explosionFire)
        
        //grenade.removeFromParentNode()
        
        var explosionDict = [SCNPhysicsBody: SCNVector3]()
        
        for node in nearNodes {
        
            // check if node has physicsBody
            guard node.physicsBody != nil else { continue }
            
            // calculate the appropriate force for each node
            let translationVector = node.presentation.simdWorldPosition - grenade.presentation.simdWorldPosition
            
            // normalize translationVector
            let forceDirection = simd_normalize(translationVector)
            
            // calculate the strength of the force
            let distance = simd_length(translationVector)
            let mass = Float(node.physicsBody!.mass)
            let strength: Float = 1000 / (distance * distance * mass)
            
            // calculate thee force vector
            let forceVector = forceDirection * strength
            
            explosionDict[node.physicsBody!] = SCNVector3.init(forceVector.x, forceVector.y, forceVector.z)
        }
        
        for (physicsBody, vector) in explosionDict {
            updateQueue.async {
                physicsBody.applyForce(vector, asImpulse: true)
            }
        }
        
        // add flames to the surface plane
        // find the plane with the closest center to the fire node
        var closestPlane = SurfacePlane.planes.first!
        var distanceVector = sceneView.scene.rootNode.convertPosition(fireNode.position, to: SurfacePlane.planes.first!)
        var distance = sqrt(distanceVector.x * distanceVector.x + distanceVector.y * distanceVector.y + distanceVector.z + distanceVector.z)
        
        for plane in SurfacePlane.planes {
            let tempDistanceVector = sceneView.scene.rootNode.convertPosition(fireNode.position, to: plane)
            let tempDistance = sqrt(tempDistanceVector.x * tempDistanceVector.x + tempDistanceVector.y * tempDistanceVector.y + tempDistanceVector.z * tempDistanceVector.z)
            
            if tempDistance < distance {
                closestPlane = plane
                distanceVector = tempDistanceVector
                distance = tempDistance
            }
        }
        let surfacePlaneFlame = SCNParticleSystem(named: "SurfacePlaneFlame", inDirectory: nil)!
        closestPlane.addParticleSystem(surfacePlaneFlame)
    }
}
