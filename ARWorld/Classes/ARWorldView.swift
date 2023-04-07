//
//  ARWorldView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class ARWorldView: ARSCNView {
    
    // MARK: - Properties
    
    var interruptedNodes: [SCNNode] = []
    
    var graffitis: [UUID: Graffiti] = [:]
    
    // MARK: Position Testing
    
    /// Hit tests against the 'sceneView' to find an object at the provided point.
    func virtualObject(at point: CGPoint) -> Model? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.flatMap { result in
            return Model.existingObjectContainingNode(result.node)
        }.first
    }
    
    func modelHitTest(_ point: CGPoint) -> SCNHitTestResult? {
        var results: SCNHitTestResult?
        
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        let result = hitTestResults.lazy.flatMap { result in
            return Model.existingObjectContainingNode(result.node)
        }.first
        
        if result != nil {
            results = hitTestResults.first
        }
        
        return results
    }
    
    func modelHitTestWithPhysics(_ point: CGPoint) -> SCNHitTestResult? {
        guard let frame = session.currentFrame else { return nil }
        
        let cameraPos = frame.camera.transform.translation
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = float3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = unprojectPoint(positionVec)
        
        let rayDirection = screenPosOnFarClippingPlane - cameraPos
        
        let worldInit = SCNVector3Make(cameraPos.x, cameraPos.y, cameraPos.z)
        let worldFinal = SCNVector3Make(rayDirection.x, rayDirection.y, rayDirection.z)
        
        let options: [SCNPhysicsWorld.TestOption: Any] = [SCNPhysicsWorld.TestOption.searchMode: SCNPhysicsWorld.TestSearchMode.closest]
        let physicsTestResults = scene.physicsWorld.rayTestWithSegment(from: worldInit, to: worldFinal, options: options)
        
        return physicsTestResults.first
    }
    
    func surfacePlaneHitTest(_ point: CGPoint) -> SCNHitTestResult? {
        var result: SCNHitTestResult?
        
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        if hitTestResults.first?.node.categoryBitMask == NodeCategories.surfacePlane.rawValue {
            result = hitTestResults.first
        }
        
        return result
    }
    
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal, .vertical]) -> ARHitTestResult? {
        
        // Perform the hit test.
        let results = hitTest(point, types:
        [.existingPlaneUsingGeometry, .estimatedVerticalPlane, .estimatedHorizontalPlane])
        
        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }), let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
            return existingPlaneUsingGeometryResult
        }
        
        if infinitePlane {
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            let infinitePlaneResults = hitTest(point, types: .existingPlane)
            
            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                    if planeAnchor.alignment == .vertical {
                        // Return the first vertical plane hit test result.
                        return infinitePlaneResult
                    } else {
                        // For horizontal planes we only want to return a hit test result
                        // if it is close to the current object's position.
                        if let objectY = objectPosition?.y {
                            let planeY = infinitePlaneResult.worldTransform.translation.y
                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                                return infinitePlaneResult
                            }
                        } else {
                            return infinitePlaneResult
                        }
                    }
                }
            }
        }
        
        // 3. As a final fallback, check for a result on estimated planes.
        let vResult = results.first(where: { $0.type == .estimatedVerticalPlane })
        let hResult = results.first(where: { $0.type == .estimatedHorizontalPlane })
        switch (allowedAlignments.contains(.horizontal), allowedAlignments.contains(.vertical)) {
        case (true, false):
            return hResult
        case (false, true):
            // Allow fallback to horizontal because we assume that objects meant for vertical placement
            // (like a picture) can always be placed on a horizontal surface, too.
            return vResult ?? hResult
        case (true, true):
            if hResult != nil && vResult != nil {
                return hResult!.distance < vResult!.distance ? hResult! : vResult!
            } else {
                return hResult ?? vResult
            }
        default:
            return nil
        }
    }
    
    func updatePreviewNode(_ previewNode: PreviewNode, parent parentNode: SCNNode?, for hitTestResult: SCNHitTestResult) {
        
        var position: SCNVector3?
        
        if let parentNode = parentNode {
            position = parentNode.convertPosition(hitTestResult.localCoordinates, from: hitTestResult.node)
        } else {
            position = hitTestResult.worldCoordinates
        }
        //previewNode.position = SCNVector3Make(position!.x, position!.y, position!.z)
        previewNode.update(for: float3(position!.x, position!.y, position!.z), planeAnchor: nil, camera: self.session.currentFrame?.camera)
    }
    
    // - MARK: Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for object: Model) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: newAnchor)
    }
    
    // MARK: - Lighting
    var lightingRootNode: SCNNode? {
        return scene.rootNode.childNode(withName: "lightingRootNode", recursively: true)
    }
    
    func setupDirectionalLighting() {
        guard self.lightingRootNode == nil else { return }
        
        // Add directional lighting for dynamic highlights
        // in addition to environment based lighting
        guard let lightingScene = SCNScene(named: "lighting.scn", inDirectory: "art.scnassets", options: nil) else { return }
        
        let lightingRootNode = SCNNode()
        lightingRootNode.name = "lightingRootNode"
        
        for node in lightingScene.rootNode.childNodes where node.light != nil {
            lightingRootNode.addChildNode(node)
        }
        
        DispatchQueue.main.async {
            self.scene.rootNode.addChildNode(lightingRootNode)
        }
    }
    
    func updateDirectionalLighting(intensity: CGFloat) {
        guard let lightingRootNode = self.lightingRootNode else { return }
        
        DispatchQueue.main.async {
            for node in lightingRootNode.childNodes {
                node.light?.intensity = intensity
            }
        }
    }
    
    func addInfrontOfCamera(node: SCNNode, at position: SCNVector3) {
        guard let camera = session.currentFrame?.camera else { return }
        
        let translation = camera.transform.translation
        let yaw = camera.eulerAngles.y
        
        let tempNode = SCNNode()
        tempNode.simdPosition = translation
        tempNode.eulerAngles = SCNVector3Make(0, yaw, 0)
        
        scene.rootNode.addChildNode(tempNode)
        
        node.position = tempNode.convertPosition(position, to: scene.rootNode)
        node.eulerAngles = SCNVector3Make(0, yaw, 0)
        
        scene.rootNode.addChildNode(node)
        
        tempNode.removeFromParentNode()
    }
}

