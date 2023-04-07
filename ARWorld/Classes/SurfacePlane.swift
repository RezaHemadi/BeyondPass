//
//  SurfacePlane.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/26/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

class SurfacePlane: SCNNode {
    
    // width is x; height is z
    
    // MARK: - Properties
    
    var planeGeometry: SCNPlane?
    
    var alignment: ARPlaneAnchor.Alignment?
    
    var rotationAngle: Float?
    
    var isAnimating: Bool = false
    
    var locked: Bool = false
    
    var isGraffiti: Bool = false
    
    // planes corresponding anchor
    var planeAnchor: ARPlaneAnchor?
    
    // MARK: - Computed Properties
    
    var area: Float? {
        get {
            var area: Float?
            let width = planeGeometry?.width
            let height = planeGeometry?.height
            
            if width != nil && height != nil {
                area = Float(width!) * Float(height!)
            }
            
            return area
        }
    }
    
    var longLength: Float? {
        get {
            guard planeGeometry != nil else { return nil }
            
            let width = Float(planeGeometry!.width)
            let height = Float(planeGeometry!.height)
            
            if width > height {
                return width
            } else {
                return height
            }
        }
    }
    
    var shortLength: Float? {
        get {
            guard planeGeometry != nil else { return nil }
            
            let width = Float(planeGeometry!.width)
            let height = Float(planeGeometry!.height)
            
            if width < height {
                return width
            } else {
                return height
            }
        }
    }
    
    var minWorldPosition: float3 {
        get {
            let simdMin = float3(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z)
            return simdWorldPosition + simdMin
        }
    }
    
    var maxWorldPosition: float3 {
        get {
            let simdMax = float3(boundingBox.max.x, boundingBox.max.y, boundingBox.max.z)
            return simdWorldPosition + simdMax
        }
    }
    
    // MARK: - Initialization
    
    init(anchor: ARPlaneAnchor, using node: SCNNode, enablePhysics: Bool = false, grid: Bool = false) {
        
        super.init()
        
        simdPosition = anchor.center
        
        simdRotation = node.simdRotation
        
        if anchor.alignment == .horizontal {
            let axis = anchor.transform.orientation.axis
            let angle = anchor.transform.orientation.angle
            rotation = SCNQuaternion.init(axis.x, axis.y, axis.z, angle)
            simdEulerAngles += float3( -.pi / 2, 0, 0)
        }
        
        self.alignment = anchor.alignment
        
        planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        self.geometry = planeGeometry
        
        self.planeAnchor = anchor
        
        if grid {
            
            self.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "BrickPattern")
            self.geometry?.firstMaterial?.transparency = 0.5
            self.geometry?.firstMaterial?.isDoubleSided = true
            
        } else {
            self.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
        
        if enablePhysics { enableStaticPhysics() }
        
        categoryBitMask = NodeCategories.surfacePlane.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Physics
    private func enableStaticPhysics() {
        let shape = SCNPhysicsShape(geometry: planeGeometry!, options: [:])
        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        physicsBody?.allowsResting = false
        physicsBody?.friction = 1.0
        physicsBody?.categoryBitMask = BodyType.sandbox.rawValue
        physicsBody?.contactTestBitMask = BodyType.sandbox.rawValue
    }
    
    // MARK: - Transform
    
    func updateTransform(anchor: ARAnchor, using node: SCNNode) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            self.planeAnchor = planeAnchor
            
            if !locked {
                self.planeGeometry?.width = CGFloat(planeAnchor.extent.x)
                self.planeGeometry?.height = CGFloat(planeAnchor.extent.z)
                self.adjustPivot(to: .center)
                
                self.simdTransform.translation = anchor.transform.translation + planeAnchor.center
                
                if alignment! == .horizontal {
                    simdEulerAngles = float3( -(.pi / 2), node.simdEulerAngles.y, 0)
                    
                } else {
                    //simdEulerAngles = float3( 0, node.simdEulerAngles.y, 0)
                    let axis = anchor.transform.orientation.axis
                    let angle = anchor.transform.orientation.angle
                    rotation = SCNQuaternion.init(axis.x, axis.y, axis.z, angle)
                    simdEulerAngles += float3( -.pi / 2, 0, 0)
                }
                
                enableStaticPhysics()
            }
        }
    }
    
    func restoreRealTransform() {
        self.planeGeometry?.width = CGFloat(planeAnchor!.extent.x)
        self.planeGeometry?.height = CGFloat(planeAnchor!.extent.z)
        self.adjustPivot(to: .center)
        
        self.simdTransform.translation = planeAnchor!.transform.translation + planeAnchor!.center
        self.locked = false
        
        enableStaticPhysics()
    }
}

extension SurfacePlane {
    static var planes = [SurfacePlane]()
    
    static var infinitePlane: SurfacePlane?
    
    static func mergePlanes() {
        var availablePlanes = planes
        
        availablePlanes.sort { return $0.area! > $1.area! }
        
        for _ in availablePlanes {
            let loopingPlane = availablePlanes.remove(at: 0)
            
            for tempPlane in availablePlanes {
                if loopingPlane.isEnclosing(tempPlane) {
                    // remove tempPlane from the scene
                    tempPlane.removeFromParentNode()
                    
                    // remove tempPlane from the class planes array
                    let index = self.planes.index(of: tempPlane)
                    self.planes.remove(at: index!)
                }
            }
        }
    }
    
    static func generateInfinitePlane() {
        if let lowest = planes.sorted(by: { $0.position.y < $1.position.y }).first {
            if lowest.isEqual(infinitePlane) {
                return
            } else {
                infinitePlane?.locked = false
                infinitePlane?.restoreRealTransform()
                lowest.locked = true
                infinitePlane = lowest
                infinitePlane?.planeGeometry?.width = 100
                infinitePlane?.planeGeometry?.height = 100
                infinitePlane?.enableStaticPhysics()
            }
        }
    }
        
    // MARK: - Helper Methods
    
    /// determine if two planes completely encircle each other
    private func isEnclosing(_ plane: SurfacePlane) -> Bool {
        
        if (minWorldPosition.x < plane.minWorldPosition.x &&
            minWorldPosition.y < plane.minWorldPosition.y &&
            maxWorldPosition.x > plane.maxWorldPosition.x &&
            maxWorldPosition.y > plane.maxWorldPosition.y) {
            return true
        }
        return false
    }
}

