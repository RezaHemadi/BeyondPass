//
//  PreviewNode.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/3/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class PreviewNode: SCNNode {
    
    // Saved positions that help smooth the movement of the preview
    var lastPositionOnPlane: float3?
    var lastPosition: float3?
    
    // Use average of recent positions to avoid jitter
    private var recentPreviewNodePositions: [float3] = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    convenience init(node: SCNNode) {
        self.init()
        opacity = 0.5
        for childNode in node.childNodes {
            if childNode.geometry != nil {
                childNode.categoryBitMask = NodeCategories.preview.rawValue
            }
        }
        addChildNode(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Appearence
    
    func update(for position: float3, planeAnchor: ARPlaneAnchor?, camera: ARCamera?) {
        lastPosition = position
        if planeAnchor != nil {
            lastPositionOnPlane = position
        }
        updateTransform(for: position, camera: camera)
    }
    
    // MARK: - Private
    
    private func updateTransform(for position: float3, camera: ARCamera?) {
        
        // Add to the list of recent positions.
        recentPreviewNodePositions.append(position)
        
        // Remove anything older than the last 8 positions.
        recentPreviewNodePositions.keepLast(8)
        
        // Move to average of recent positions to avoid jitter.
        if let average = recentPreviewNodePositions.average {
            simdPosition = average
        }
        
        // change the rotation of the node
        if let camera = camera {
            eulerAngles.y = camera.eulerAngles.y
        }
    }
}
