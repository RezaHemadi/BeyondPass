//
//  MainViewController+UserBannerViewerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/9/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: UserBannerViewerDelegate {
    // MARK: - Adding and Removing User Banners
    
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldDisplay banner: UserBanner) -> Bool {
        guard let _ = sceneView.pointOfView, let heading = self.userHeading, appMode == .normal else { return false }
        
        let bannerPosition = getPosition(userLocation: self.location, userHeading: heading, to: banner.location)
        updateQueue.async {
            self.sceneView.addInfrontOfCamera(node: banner, at: bannerPosition)
        }
        /*
        
        let bannerPosition = getPosition(userLocation: self.location, userHeading: heading, to: banner.location)

        let currentNode = camera.clone()
        currentNode.eulerAngles = SCNVector3Make(0, camera.eulerAngles.y, 0)
        let position = currentNode.convertPosition(bannerPosition, to: sceneView.scene.rootNode)
        let simdPosition = float3(position.x, position.y, position.z)
        
        // closest banner should not be closer than 20 meterss
        if simd_length(simdPosition) < 20 {
            // Normalize position to 20 meters
            let normalizedPosition = simd_normalize(simdPosition)
            banner.simdPosition = 20 * normalizedPosition
        } else {
            banner.simdPosition = simdPosition
        }
        
        banner.simdScale = userBannerScale(location: banner.location)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(banner)
        }
        */
        // Add A marker to compass
        let bearing = bearingToLocationDegrees(userLocation: self.location, destinationLocation: banner.location)
        let normalizedBearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
        
        let marker = CompassMarker(bearing: normalizedBearing, style: .user)
        compassBar.markers[banner.id] = marker
        
        return true
    }
    
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldRemove banner: UserBanner) {
        banner.removeFromParentNode()
        compassBar.markers[banner.id] = nil
    }
    
    // MARK: - Updating Banners
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldUpdate banner: UserBanner) {
        guard let _ = sceneView.pointOfView, let heading = self.userHeading, appMode == .normal else { return }
        
        let bannerPosition = getPosition(userLocation: self.location, userHeading: heading, to: banner.location)
        
        updateQueue.async {
            banner.position = bannerPosition
        }
        
        /*
        let currentNode = camera.clone()
        currentNode.eulerAngles = SCNVector3Make(0, camera.eulerAngles.y, 0)
        let position = currentNode.convertPosition(bannerPosition, to: sceneView.scene.rootNode)
        let simdPosition = float3(position.x, position.y, position.z)
        
        // closest banner should not be closer than 20 meterss
        
        if simd_length(simdPosition) < 20 {
            // Normalize position to 20 meters
            let normalizedPosition = simd_normalize(simdPosition)
            banner.simdPosition = 20 * normalizedPosition
        } else {
            banner.simdPosition = simdPosition
        } */
        
        banner.childNode.simdScale = userBannerScale(location: banner.location)
        
        let bearing = bearingToLocationDegrees(userLocation: self.location, destinationLocation: banner.location)
        let normalizedBearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
        if let marker = compassBar.markers[banner.id] {
            marker.bearing = normalizedBearing
        }
    }
    
    // MARK: - Helper Methods
    func userBannerScale(location: CLLocation) -> float3 {
        let distance = self.location.distance(from: location)
        
        let factor = Float(( 0.01 * distance) + 0.02)
        
        return float3(factor, factor, factor)
    }
}
