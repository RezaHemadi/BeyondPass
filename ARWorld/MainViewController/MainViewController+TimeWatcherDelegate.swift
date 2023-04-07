//
//  MainViewController+TimeWatcherDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension MainViewController: TimeWatcherDelegate {
    
    // MARK: - Delegate functions
    func timeWatcherShouldTrigger(_ timeWatcher: TimeWatcher, at time: TimeInterval) {
        if timeWatcher.tag == 0 {
            guard let camera = sceneView.session.currentFrame?.camera else { return }
            // sandbox timer; clean up extra nodes
            guard sandboxNodes != nil else { return }
            
            var tempNode: SCNNode?
            
            for node in sandboxNodes! {
                if node is SCNReferenceNode {
                    tempNode = node.childNodes.first!
                } else {
                    tempNode = node
                }
                
                if isFallen(node: tempNode!, camera: camera) {
                    // remove node from scene
                    DispatchQueue.main.async {
                        node.removeFromParentNode()
                        let index = self.sandboxNodes?.index(of: node)
                        self.sandboxNodes?.remove(at: index!)
                    }
                }
            }
        }
    }
    
    func isFallen(node: SCNNode, camera: ARCamera) -> Bool {
        let cameraElevation = camera.transform.translation.y
        let nodeElevation = node.presentation.simdWorldPosition.y
        
        if (nodeElevation - cameraElevation) < -20 {
            return true
        }
        
        return false
    }
}
