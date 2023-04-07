//
//  Utilities.swift
//  ARWorld
//
//  Created by Reza Hemadi on 2/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

// MARK: - SCNNode extensions

extension SCNNode {
    
    enum Side {
        case floor
        case roof
        case center
    }
    
    enum Explosive {
        case grenade
    }
    
    
    
    func adjustPivot(to: SCNNode.Side) {
        var (min, max) = self.boundingBox
        
        var dx: Float
        var dy: Float
        var dz: Float
        
        switch to {
        case .center:
            dx = min.x + 0.5 * (max.x - min.x)
            dy = min.y + 0.5 * (max.y - min.y)
            dz = min.z + 0.5 * (max.z - min.z)
            
        case .floor:
            dx = min.x + 0.5 * (max.x - min.x)
            dy = min.y
            dz = min.z + 0.5 * (max.z - min.z)
            
        case .roof:
            dx = min.x + 0.5 * (max.x - min.x)
            dy = min.y + 0.5 * (max.y - min.y)
            dz = max.z
        }
        self.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
    
    func setTransform(_ newTransform: float4x4,
                      relativeTo cameraTransform: float4x4) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newTransform.translation - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(positionOffsetFromCamera) > 10 {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        
        /*
         Compute the average distance of the object from the camera over the last ten
         updates. Notice that the distance is applied to the vector from
         the camera to the content, so it affects only the percieved distance to the
         object. Averaging does _not_ make the content "lag".
         */
        simdPosition = cameraWorldPosition + positionOffsetFromCamera
    }
}

// MARK: - Collection extentions

extension Array where Iterator.Element == float3 {
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension RangeReplaceableCollection  {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - float4x4 extenstions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: float3 {
        get {
            let translation = columns.3
            return float3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = float4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }
    
    /**
     Factors out the orientation component of the transform.
    */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

// MARK: - Math

func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
    
    let direction = simd_normalize(direction)
    
    // Special case handling: Check if the ray is horizontal az well.
    if direction.y == 0 {
        if rayOrigin.y == planeY {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.else
            return rayOrigin
        } else {
            // The ray is parallel to the plane and never intersects.
            return nil
        }
    }
    
    // The distance from the ray's origin to the intersection point on the plane is:
    //  (pointOnPlane - rayOrigin) dot planeNormal
    // --------------------------------------------
    //          direction dot planeNormal
    
    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    let dist = (planeY - rayOrigin.y) / direction.y
    
    // Do not return intersection behind the ray's origin.
    if dist < 0 {
        return nil
    }
    
    // Return the intersection point.
    return rayOrigin + (direction * dist)
}

func worldPositionFromScreenPosition(_ position: CGPoint,
                                     in sceneView: ARSCNView,
                                     objectPos: float3?,
                                     infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
    
    // -----------------------------------------------------------------------------------
    //1. Always do a hit test against existing plane anchors first.
    //  (If any such anchors exist & only within their extents.)
    
    let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
    
    if let result = planeHitTestResults.first {
        
        let planeHitTestPosition = result.worldTransform.translation
        let planeAnchor = result.anchor
        
        // Return immediately - this is the best possible outcome.
        return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
    }
    
    // ------------------------------------------------------------------------------------
    // 2. collect moreinformation about the environment by hit testing against
    //    the feture point cloud, but do not return the result yet.
    
    var featureHitTestPosition: float3?
    var highQualityFeatureHitTestResult = false
    
    let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleinDegress: 18, minDistance: 0.2, maxDistance: 2.0)
    
    if !highQualityfeatureHitTestResults.isEmpty {
        let result = highQualityfeatureHitTestResults[0]
        featureHitTestPosition = result.position
        highQualityFeatureHitTestResult = true
    }
    
    // ---------------------------------------------------------------------------------------
    // 3. If desired or necessaty (no good featuer hit test result): Hit test
    //    against an infinite, horizontal plane (ignoring the real world).
    
    if infinitePlane || !highQualityFeatureHitTestResult {
        
        if let pointOnPlane = objectPos {
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
    }
    
    // -----------------------------------------------------------------------------------------
    // 4. If available, return the result of the hit test against high quality
    //    features if the hit tests against infinite planes were skipped or no
    //    infinite plane was hit.
    
    if highQualityFeatureHitTestResult {
        return (featureHitTestPosition, nil, false)
    }
    
    // ------------------------------------------------------------------------------------------
    // 5. As a last resort, perform a second, unfiltered hit test against features.
    //    If there are no features in the scene, the result returned here will be nil.
    
    let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
    if !unfilteredFeatureHitTestResults.isEmpty {
        let result = unfilteredFeatureHitTestResults[0]
        return (result.position, nil, false)
    }
    
    return (nil, nil, false)
}

func setNewVirtualObjectPosition(_ object: SCNNode, to pos: float3, cameraTransform: matrix_float4x4) {
    let cameraWorldPos = cameraTransform.translation
    var cameraToPosition = pos - cameraWorldPos
    
    // Limit the distance of the object from the camera to a maximum of 10 meters.
    if simd_length(cameraToPosition) > 10 {
        cameraToPosition = simd_normalize(cameraToPosition)
        cameraToPosition *= 10
    }
    
    object.simdPosition = cameraWorldPos + cameraToPosition
}

// MARK: - Parse

extension PFUser {
    func createDefaultInventory() {
        let inventory = PFObject(className: "Inventory")
        inventory["User"] = self
        let items = inventory.relation(forKey: "Items")
        
        let batteryObject = PFObject(withoutDataWithClassName: "Models", objectId: "uaLJUHgkFX")
        let inventoryItem = PFObject(className: "InventoryItem")
        inventoryItem["Model"] = batteryObject
        inventoryItem["Quantity"] = 1
        inventoryItem.saveInBackground { (succeed, error) in
            if error == nil {
                items.add(inventoryItem)
                inventory.saveInBackground()
            }
        }
    }
    func followStatus(to: PFUser, _ completion: @escaping (_ status: FollowStatus?, _ error: Error?) -> Void) -> Void {
        /*
        // check if the current user is following
        let followingRelation = self["Following"] as! PFRelation
        let followingQuery = followingRelation.query()
        followingQuery.whereKey("objectId", equalTo: to.objectId!)
        followingQuery.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let error = error {
                completion(nil, error)
            }
            else if let _ = objects?.first {
                completion(FollowStatus.following, nil)
            } else {
                // check if follow request is sent
                let followRequestQuery = PFQuery(className: "FollowRequest")
                followRequestQuery.whereKey("from", equalTo: self)
                followRequestQuery.findObjectsInBackground {
                    (followRequests: [PFObject]?, error: Error?) -> Void in
                    if let followRequests = followRequests {
                        for followRequest in followRequests {
                            if (followRequest["status"] as! String) == "pending" {
                                let requestedUser = followRequest["to"] as! PFUser
                                if requestedUser.objectId! == to.objectId! {
                                    completion(FollowStatus.requested, nil)
                                    return
                                }
                            }
                        }
                        completion(FollowStatus.notFollowing, nil)
                    } else if let error = error {
                        completion(nil, error)
                    }
                }
            }
        }
 */
    }
    func award(model: PFObject, amount: Int, _ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        // Check if this model is already in this users inventory items
        let inventoryQuery = PFQuery(className: "Inventory")
        inventoryQuery.whereKey("User", equalTo: self)
        inventoryQuery.findObjectsInBackground {
            (objects, error) -> Void in
            if error == nil {
                let inventory = objects!.first!
                let items = objects!.first!.relation(forKey: "Items")
                let itemsQuery = items.query()
                itemsQuery.whereKey("Model", equalTo: model)
                itemsQuery.findObjectsInBackground {
                    (objects, error) in
                    if error == nil {
                        if !objects!.isEmpty {
                            // User already has this model in his inventory, add amount to quantity
                            let existingQuantity = objects!.first!["Quantity"] as! Int
                            objects!.first!["Quantity"] = existingQuantity + amount
                            objects!.first!.saveInBackground() {
                                (succeed, error) in
                                
                                completion(succeed, error)
                            }
                        } else {
                            // User does not have this model in his inventory, create new inventory item for this user
                            let inventoryItem = PFObject(className: "InventoryItem")
                            inventoryItem["Model"] = model
                            inventoryItem["Quantity"] = amount
                            inventoryItem.saveInBackground {
                                (succeed, error) in
                                if error == nil {
                                    items.add(inventoryItem)
                                    inventory.saveInBackground() {
                                        (succeed, error) in
                                        
                                        completion(succeed, error)
                                    }
                                } else {
                                    completion(nil, error)
                                }
                            }
                        }
                    } else {
                        completion(nil, error)
                    }
                }
            } else {
                completion(nil, error)
            }
        }
    }
    func subtractInventory(item: PFObject, amount: Int, completion: @escaping (_ succeed: Bool, _ error: Error?) -> Void = { (_, _) in } ) {
        let initialAmount = item["Quantity"] as! Int
        
        guard amount <= initialAmount else { return }
        
        item["Quantity"] = initialAmount - amount
        
        item.saveInBackground() {
            (succeed, error) in
            completion(succeed, error)
        }
    }
}
