//
//  MainViewController+CassetteViewerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension MainViewController: CassetteViewerDelegate {
    func addCassette(_ cassette: Cassette, for viewer: CassetteViewer) {
        let position = getPosition(userLocation: self.location, userHeading: self.userHeading, to: cassette.location)
        self.updateQueue.async {
            self.sceneView.addInfrontOfCamera(node: cassette, at: position)
            // Create a new anchor with the object's current transform and add it to the session
            let newAnchor = ARAnchor(transform: cassette.simdWorldTransform)
            cassette.anchor = newAnchor
            self.session.add(anchor: newAnchor)
        }
    }
}
