//
//  MainViewController+GraffitiLoaderDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/30/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: GraffitiLoaderDelegate {
    func createGraffiti(for graffitiLoader: GraffitiLoader, withObject object: PFObject, withID id: String) {
        // Check if theres a vertical surface plane available
        if let verticalPlane = SurfacePlane.planes.sorted(by: { $0.area! > $1.area!} ).first(where: {$0.planeAnchor?.alignment == .vertical && !$0.isGraffiti} ) {
            let graffiti = Graffiti(verticalPlane, object: object)
            graffitiLoader.delegateDisplayedItem(withID: id)
            self.sceneView.graffitis[verticalPlane.planeAnchor!.identifier] = graffiti
        } else {
            /// Add item to a queue
            graffitiesToBeDisplayed[id] = object
        }
    }
}
