//
//  MainViewController+ARPortalDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/31/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: ARPortalDelegate {
    func updatePreview(for previewNode: PreviewNode, for portal: ARPortal, parentNode node: SCNNode, using hitTest: SCNHitTestResult) {
        sceneView.updatePreviewNode(previewNode, parent: node, for: hitTest)
    }
}
