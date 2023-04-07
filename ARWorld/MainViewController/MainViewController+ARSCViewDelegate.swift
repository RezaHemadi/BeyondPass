//
//  MainViewController+ARSCViewDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import ARKit

extension MainViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if let treasure = treasureManager?.activeTreasure, treasure.refNode.isHidden { 
            if let cameraNode = sceneView.pointOfView {
                let localPos = cameraNode.convertPosition(treasureManager!.activeTreasure!.refNode.position, from: sceneView.scene.rootNode)
                let distance = positionToDistance(localPos)
                if distance < 10 {
                    treasureManager!.activeTreasure!.refNode.isHidden = false
                    treasureManager!.activeTreasure!.playTreasureAvailableSound()
                }
            }
        }
        switch appMode {
        case .normal:
            // Hit test
            let stickyHitTestResults = sceneView.hitTest(screenCenter, options: nil)
            
            if let first = stickyHitTestResults.first {
                lastHitTest = first
                let bitMask = first.node.categoryBitMask
                if bitMask == NodeCategories.stickyNote.rawValue || bitMask == NodeCategories.voiceBadge.rawValue || bitMask == NodeCategories.pinPhoto.rawValue {
                    targetingSticky = true
                    targetingTemple = false
                    targetingVerticalPlane = false
                    userBannerViewer?.displayedBanners.forEach({$0.isTargeted = false})
                    stickyHitResult = first
                    break
                } else if bitMask == NodeCategories.surfacePlane.rawValue {
                    targetingSticky = false
                    userBannerViewer?.displayedBanners.forEach({$0.isTargeted = false})
                    let surfacePlane = first.node as! SurfacePlane
                    if surfacePlane.alignment! == .vertical {
                        targetingVerticalPlane = true
                    } else {
                        targetingVerticalPlane = false
                    }
                } else if bitMask == NodeCategories.profilePic.rawValue {
                    if let userBanner = userBannerViewer?.displayedBanners.first(where: { $0.id == first.node.name }) {
                        userBanner.isTargeted = true
                    }
                } else {
                    targetingSticky = false
                    targetingVerticalPlane = false
                    userBannerViewer?.displayedBanners.forEach({$0.isTargeted = false})
                }
            } else {
                targetingSticky = false
                targetingVerticalPlane = false
                userBannerViewer?.displayedBanners.forEach({$0.isTargeted = false})
            }
            
            let options: [SCNHitTestOption: Any] = [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.categoryBitMask: NodeCategories.pinBoard.rawValue, SCNHitTestOption.backFaceCulling: true, SCNHitTestOption.searchMode: SCNHitTestSearchMode.closest.rawValue]
            let hitTestResults = sceneView.hitTest(screenCenter, options: options)
            let containsBoard = hitTestResults.contains { (result) -> Bool in
                if result.node.name == "Board" {
                    return true
                }
                return false
            }
            if containsBoard {
                targetingTemple = true
            } else {
                targetingTemple = false
            }
        case .portal:
            if let pointOfView = sceneView.pointOfView, let treasureController = portal?.treasureController, treasureController.shouldHitTest {
                guard let frame = self.session.currentFrame else {
                    break
                }
                
                let cameraPos = frame.camera.transform.translation
                
                // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
                let positionVec = float3(x: Float(screenCenter.x), y: Float(screenCenter.y), z: 1.0)
                let screenPosOnFarClippingPlane = sceneView.unprojectPoint(positionVec)
                
                let rayDirection = screenPosOnFarClippingPlane - cameraPos
                /*
                let initPoint = SCNVector3Make(0, 0, 0)
                let finalPoint = SCNVector3Make(0, 0, -5)
                */
                let worldInit = SCNVector3Make(cameraPos.x, cameraPos.y, cameraPos.z)
                let worldFinal = SCNVector3Make(rayDirection.x, rayDirection.y, rayDirection.z)
 
                let options: [SCNPhysicsWorld.TestOption: Any] = [SCNPhysicsWorld.TestOption.searchMode: SCNPhysicsWorld.TestSearchMode.closest]
                let physicsTestResults = sceneView.scene.physicsWorld.rayTestWithSegment(from: worldInit, to: worldFinal, options: options)
                print("\(physicsTestResults)")
                treasureController.lastHitTest = physicsTestResults
 
            }
            
            // Hit test against sticky notes
            let stickyHitTestResults = sceneView.hitTest(screenCenter, options: nil)
            
            if let first = stickyHitTestResults.first {
                lastHitTest = first
                let bitMask = first.node.categoryBitMask
                if bitMask == NodeCategories.stickyNote.rawValue || bitMask == NodeCategories.voiceBadge.rawValue || bitMask == NodeCategories.pinPhoto.rawValue {
                    targetingSticky = true
                    targetingTemple = false
                    stickyHitResult = first
                    break
                } else {
                    targetingSticky = false
                }
            }
            
            let options: [SCNHitTestOption: Any] = [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.categoryBitMask: NodeCategories.pinBoard.rawValue, SCNHitTestOption.backFaceCulling: true, SCNHitTestOption.searchMode: SCNHitTestSearchMode.closest.rawValue]
            let hitTestResults = sceneView.hitTest(screenCenter, options: options)
            let containsBoard = hitTestResults.contains { (result) -> Bool in
                if result.node.name == "Board" {
                    return true
                }
                return false
            }
            if containsBoard {
                targetingTemple = true
            } else {
                targetingTemple = false
            }
        case .pinBoard:
            if let previewNode = previewNode {
                // Update preview node
                if appMode == .pinBoard {
                    let (worldPosition, planeAnchor, hitAplane) = worldPositionFromScreenPosition(screenCenter, in: sceneView, objectPos: personalPinBoard?.rootNode.simdPosition)
                    if let planeAnchor = planeAnchor {
                        previewNode.removeFromParentNode()
                        
                        guard let cameraTransform = session.currentFrame?.camera.transform, let personalPinboard = self.personalPinBoard else { return }
                        
                        self.setNewVirtualObjectToAnchor(personalPinboard.rootNode, to: planeAnchor, cameraTransform: cameraTransform)
                        
                        updateQueue.async {
                            self.sceneView.scene.rootNode.addChildNode(personalPinboard.rootNode)
                            self.previewNode = nil
                        }
                    } else if let position = worldPosition {
                        previewNode.update(for: position, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
                    }
                }
            } else {
                // Hit test against sticky notes
                let stickyHitTestResults = sceneView.hitTest(screenCenter, options: nil)
                
                if let first = stickyHitTestResults.first {
                    lastHitTest = first
                    let bitMask = first.node.categoryBitMask
                    if bitMask == NodeCategories.stickyNote.rawValue || bitMask == NodeCategories.voiceBadge.rawValue || bitMask == NodeCategories.pinPhoto.rawValue {
                        targetingSticky = true
                        targetingTemple = false
                        stickyHitResult = first
                        break
                    } else {
                        targetingSticky = false
                    }
                }
                
                let options: [SCNHitTestOption: Any] = [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.categoryBitMask: NodeCategories.pinBoard.rawValue, SCNHitTestOption.backFaceCulling: true, SCNHitTestOption.searchMode: SCNHitTestSearchMode.closest.rawValue]
                let hitTestResults = sceneView.hitTest(screenCenter, options: options)
                let containsBoard = hitTestResults.contains { (result) -> Bool in
                    if result.node.name == "Board" {
                        return true
                    }
                    return false
                }
                if containsBoard {
                    targetingTemple = true
                } else {
                    targetingTemple = false
                }
            }
        default:
            break
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if !(anchor is ARPlaneAnchor) {
            return
        }
        
        // Add a plane corresponding to this anchor
        if shouldDetectPlanes, let planeAnchor = anchor as? ARPlaneAnchor {
            DispatchQueue.main.async {
                let plane = SurfacePlane(anchor: planeAnchor, using: node, enablePhysics: true, grid: false)
                self.sceneView.scene.rootNode.addChildNode(plane)
                SurfacePlane.planes.append(plane)
            }
        }
        
        self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
        self.statusViewController.showMessage("SURFACE DETECTED")
        
        updateQueue.async {
            for object in self.modelLoader.loadedObjects {
                object.adjustOntoPlaneAnchor(anchor as! ARPlaneAnchor, using: node)
            }
            
            // Show Graffities in the queue if any
            for (id, object) in self.graffitiesToBeDisplayed {
                if let verticalPlane = SurfacePlane.planes.sorted(by: { $0.area! > $1.area!} ).first(where: {$0.planeAnchor?.alignment == .vertical && !$0.isGraffiti} ) {
                    let graffiti = Graffiti(verticalPlane, object: object)
                    self.sceneView.graffitis[verticalPlane.planeAnchor!.identifier] = graffiti
                    self.graffitiLoader?.delegateDisplayedItem(withID: id)
                    self.graffitiesToBeDisplayed[id] = nil
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if shouldDetectPlanes, let planeAnchor = anchor as? ARPlaneAnchor {
            // Update existing planes transforms
            DispatchQueue.main.async {
                if let plane = SurfacePlane.planes.first(where: {$0.planeAnchor == planeAnchor }) {
                    plane.updateTransform(anchor: anchor, using: node)
                    SurfacePlane.mergePlanes()
                    //SurfacePlane.generateInfinitePlane()
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let pointOfView = sceneView.pointOfView, !sprayCan.isAdded {
            pointOfView.addChildNode(sprayCan)
            sprayCan.isAdded = true
        }
        
        if let lightEstimate = session.currentFrame?.lightEstimate {
            sceneView.updateDirectionalLighting(intensity: lightEstimate.ambientIntensity)
        } else {
            sceneView.updateDirectionalLighting(intensity: 1000)
        }
        
        //self.modelInteraction.updateObjectToCurrentTrackingPosition()
        
        /// Portal Mode
        DispatchQueue.main.async {
            if self.appMode == .portal {
                
                if self.portal!.state == .preview && self.portal!.preview != nil {
                    self.updatePortalPreview()
                } else if self.portal!.dartboard != nil && self.portal!.state == .placed {
                    // Show Portal Dock if inside portal
                    if self.optionsDock == nil && self.portal!.user.isEqual(PFUser.current()!) {
                        /// Check if the user is inside the portal
                        if self.isCameraInsidePortal() && !self.portal!.visiting {
                            self.showPortalDock()
                        }
                    } else {
                        if !self.isCameraInsidePortal() {
                            /// Hide Portal Dock and any costumization views
                            self.hidePortalDock()
                        } else {
                            /// Check if portal is in decorating mode
                            if self.portal!.state == .decorating && self.portal!.decorationModelPreview != nil {
                                print("updating decoration preview")
                                let hitTest = self.sceneView.hitTest(self.screenCenter, options: nil)
                                print("\(hitTest)")
                                if let floorHit = hitTest.first(where: { $0.node.name == "floor" }) {
                                    let position = floorHit.worldCoordinates
                                    self.portal!.decorationModelPreview!.update(for: float3(position.x, position.y, position.z), planeAnchor: nil, camera: self.session.currentFrame?.camera)
                                    self.portal!.decorationModelPreview?.simdEulerAngles.y = self.sceneView.session.currentFrame!.camera.eulerAngles.y
                                }
                            }
                        }
                    }
                    
                    // check if screen center is targeting dartboard
                    let options: [SCNHitTestOption: Any] = [SCNHitTestOption.boundingBoxOnly: true]
                    let hitTestResult = self.sceneView.hitTest(self.screenCenter, options: options)
                    let containsDartboard = hitTestResult.contains {
                        (result: SCNHitTestResult) -> Bool in
                        if result.node.categoryBitMask == NodeCategories.dartboard.rawValue || result.node.categoryBitMask == NodeCategories.dart1.rawValue {
                            return true
                        }
                        return false
                    }
                    if containsDartboard {
                        self.portal!.dartboard.dartboardFocused()
                    } else {
                        self.portal!.dartboard.dartboardUnfocused()
                    }
                }
            }
        }
        
        
        DispatchQueue.main.async {
            
            if self.focusSquare != nil {
                self.updateFocusSquare()
            }
            
            
        }
        
        if needPlane {
            if let plane = SurfacePlane.planes.sorted(by: {$0.area! > $1.area!}).first {
                if plane.area! > 0.5 {
                    if let yaw = session.currentFrame?.camera.eulerAngles.y {
                        statusViewController.hide()
                        needPlane = false
                        DispatchQueue.main.async {
                            self.story?.delegateFoundPlane(plane: plane, yaw: yaw)
                        }
                    }
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) { /*
        // update sandbox mode time watcher
        
        if appMode == .sandbox {
            if let sandboxTimeWatcher = self.sandboxTimeWatcher {
                sandboxTimeWatcher.updateTime(with: time)
            } else {
                sandboxTimeWatcher = TimeWatcher(type: .sandbox, initialTime: time)
                sandboxTimeWatcher!.tag = 0
                sandboxTimeWatcher!.delegate = self
            }
        } 
  */  }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
            
            self.blurEffectView.layer.opacity = 1.0
        case .normal:
            if appMode == .normal {
                
            }
            UIView.animate(withDuration: 3, animations: {
                self.blurEffectView.layer.opacity = 0.0
            })
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
 
            // Unhide content after successful relocalization.
            modelLoader.loadedObjects.forEach { $0.isHidden = false }
        }
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Hide content before going into the background.
        modelLoader.loadedObjects.forEach { $0.isHidden = true }
        hideInterruptedNodes()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return false
    }
    func updatePortalPreview() {
        guard portal != nil, portal?.preview != nil, session.currentFrame?.camera != nil else { return }
        
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, in: sceneView, objectPos: self.portal!.preview!.simdPosition)
        if let planeAnchor = planeAnchor, let portal = self.portal, let preview = self.portal?.preview, let cameraTransform = self.session.currentFrame?.camera.transform {
            // Set the portal final node
            DispatchQueue.main.async {
                self.setNewVirtualObjectToAnchor(preview, to: planeAnchor, cameraTransform: cameraTransform)
                portal.openingNode = preview.clone()
                let nodeWithGeometry = portal.openingNode?.childNode(withName: "Opening", recursively: true)!
                nodeWithGeometry?.renderingOrder = 300
                portal.openingNode?.transform = preview.transform
                portal.openingNode?.opacity = 1.0
                self.sceneView.scene.rootNode.replaceChildNode(preview, with: portal.openingNode!)
                portal.preview = nil
                let extraNode = portal.openingNode?.childNode(withName: "back", recursively: true)
                
                portal.state = .animatingDoor
                
                // Add an invisible plane to cover portal animation
                let plane = SCNPlane(width: 1.43, height: 6.117)
                plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.01)
                let planeNode = SCNNode(geometry: plane)
                planeNode.eulerAngles.y = portal.openingNode!.eulerAngles.y
                planeNode.simdPosition = portal.openingNode!.simdConvertPosition(float3(0, 0.1, +0.3), to: self.sceneView.scene.rootNode) + float3(0, -3.0585, 0)
                //planeNode.simdPosition = planeAnchor.center
                planeNode.renderingOrder = 20
                self.sceneView.scene.rootNode.addChildNode(planeNode)
                
                // Set up portal
                portal.setupPortal() { succeed in
                    if succeed! {
                        let position = portal.openingNode!.simdConvertPosition(float3(0.2, 0, +0.1), to: self.sceneView.scene.rootNode)
                        portal.portalNode!.eulerAngles.y = portal.openingNode!.eulerAngles.y
                        portal.portalNode!.simdPosition = position + float3(0, -6.117, 0)
                        
                        self.sceneView.scene.rootNode.addChildNode(portal.portalNode!)
                        portal.state = .placed
                        extraNode?.removeFromParentNode()
                        
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 6.0
                        
                        SCNTransaction.completionBlock = { portal.animationComplete(); portal.state = .placed; portal.dartboard.gameDelegate = self; planeNode.removeFromParentNode(); self.trophyController.loadTrophies({ (trophies) in
                            portal.loadTrophies(trophies: trophies!, { (succeed) in
                                
                            })
                        }) }
                        
                        portal.portalNode!.simdPosition += float3(0, 6.117, 0)
                        
                        SCNTransaction.commit()
                    }
                }
            }
            
            
            /*
            guard let cameraTransform = self.sceneView.session.currentFrame?.camera.transform else { return }
            self.setNewVirtualObjectToAnchor(portal!.portalNode, to: planeAnchor, cameraTransform: cameraTransform)
            DispatchQueue.global(qos: .userInteractive).async {
                self.sceneView.scene.rootNode.addChildNode(self.portal!.portalNode)
                self.portal!.state = .placed
                self.portal!.dartboard.gameDelegate = self
            } */
        } else {
            // update the preview position
            if let position = worldPosition {
                self.portal!.preview!.update(for: position, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
            }
        }
    }
    
    private func showPortalDock() {
        DispatchQueue.main.async {
            let portalDock = PortalDock()
            portalDock.collapse()
            portalDock.portalDockDelegate = self
            portalDock.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(portalDock)
            self.optionsDock = portalDock
        }
    }
    
    private func setNewVirtualObjectToAnchor(_ object: SCNNode, to anchor: ARAnchor, cameraTransform: matrix_float4x4) {
        let cameraWorldPosition = cameraTransform.translation
        var cameraToPosition = anchor.transform.translation - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }
        
        object.simdPosition = cameraWorldPosition + cameraToPosition
        if let camera = sceneView.pointOfView {
            object.eulerAngles = SCNVector3Make(0, camera.eulerAngles.y, 0)
        }
    }
    
    private func hideInterruptedNodes() {
        for node in sceneView.scene.rootNode.childNodes {
            if !node.isHidden {
                node.isHidden = true
                sceneView.interruptedNodes.append(node)
            }
        }
    }
    private func unhideInterruptedNodes() {
        for node in sceneView.interruptedNodes {
            node.isHidden = false
        }
        sceneView.interruptedNodes.removeAll()
    }
    private func isCameraInsidePortal() -> Bool {
        guard let portal = self.portal, let camera = self.sceneView.session.currentFrame?.camera else { return false }
        
        let portalNode = portal.portalNode!
        let cameraPosition = camera.transform.translation
        
        let localPosition = portalNode.convertPosition(SCNVector3Make(cameraPosition.x, cameraPosition.y, cameraPosition.z), from: self.sceneView.scene.rootNode)
        
        return portal.contains(position: localPosition)
    }
}

