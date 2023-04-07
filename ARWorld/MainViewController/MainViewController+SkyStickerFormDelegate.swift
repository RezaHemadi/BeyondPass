//
//  MainViewController+SkyStickerFormDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

extension MainViewController: SkyStickerFormViewDelegate {
    func skyStickerView(_ viewClosed: SkyStickerFormView) {
        plusButton.interfaceHidden = false
    }
    func skyStickerView(_ view: SkyStickerFormView, didSelect item: SkySticker.Model) {
        let skySticker = SkySticker(location: self.location, author: PFUser.current()!, model: item)
        updateQueue.async {
            self.sceneView.addInfrontOfCamera(node: skySticker.node, at: SCNVector3Make(0, 0, -1))
            self.skyStickerViewer?.addedObjects.append(skySticker)
            // Create a new anchor with the object's current transform and add it to the session
            let newAnchor = ARAnchor(transform: skySticker.node.simdWorldTransform)
            self.session.add(anchor: newAnchor)
            skySticker.saveInDB() { (succeed, error) in
                if error == nil {
                    if succeed == true {
                        self.modifyARCoin(.Object)
                    }
                }
            }
        }
    }
}
