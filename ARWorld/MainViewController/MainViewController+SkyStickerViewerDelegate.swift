//
//  MainViewController+SkyStickerViewerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension MainViewController: SkyStickerViewerDelegate {
    func addSkySticker(_ skySticker: SkySticker, for viewer: SkyStickerViewer) {
        let position = getPosition(userLocation: self.location, userHeading: self.userHeading, to: skySticker.location!)
        self.updateQueue.async {
            self.sceneView.addInfrontOfCamera(node: skySticker.node, at: position)
            // Create a new anchor with the object's current transform and add it to the session
            let newAnchor = ARAnchor(transform: skySticker.node.simdWorldTransform)
            self.session.add(anchor: newAnchor)
        }
    }
}
