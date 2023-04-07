//
//  ARWorldView+Graffiti.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARWorldView {
    func createGraffiti(_ hitTestResult: SCNHitTestResult, usingColor: UIColor, at location: CLLocation) {
            if let surfacePlane = hitTestResult.node as?  SurfacePlane {
                // Check if it is a new graffiti
                if let graffiti = self.graffitis[surfacePlane.planeAnchor!.identifier] {
                    graffiti.movePointer(hitTestResult)
                    return
                }
                
                surfacePlane.locked = true
                let id = surfacePlane.planeAnchor!.identifier
                let graffiti = Graffiti(surfacePlane, color: usingColor, at: location)
                self.graffitis[id] = graffiti
            }
    }
    func updateGraffiti(_ hitTestResult: SCNHitTestResult, usingColor: UIColor) {
        if let surfacePlane = hitTestResult.node as? SurfacePlane {
            if let graffiti = graffitis[surfacePlane.planeAnchor!.identifier] {
                graffiti.currentColor = usingColor
                graffiti.update(for: hitTestResult)
            }
        }
    }
    
    func stopSpraying(_ hitTestResult: SCNHitTestResult) {
        if let surfacePlane = hitTestResult.node as? SurfacePlane {
            if let graffiti = graffitis[surfacePlane.planeAnchor!.identifier] {
                graffiti.stopSpray()
            }
        }
    }
}
