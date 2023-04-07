//
//  ARPortal+TreasureControllerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/31/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal: TreasureControllerDelegate {
    func addTreasure(_ treasure: ARPortal.TreasureController.Treasure, for controller: ARPortal.TreasureController, _ completion: @escaping () -> ()) {
        
    }
    
    func addNode(_ node: SCNNode, for treasureController: ARPortal.TreasureController, _ completion: @escaping (_ succeed: Bool) -> () ) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.portalNode.addChildNode(node)
            completion(true)
        }
    }
    
    func updatePreview(of previewNode: PreviewNode, for treasureController: ARPortal.TreasureController, using hitTest: SCNHitTestResult) {
        delegate?.updatePreview(for: previewNode, for: self, parentNode: self.portalNode!, using: hitTest)
    }
    
    func treasureController(_ treasureController: ARPortal.TreasureController, didFinishFetchingItems items: [String : ARPortal.TreasureController.Treasure]) {
        treasurePlacementView?.reloadData()
    }
    
    func treasureControllerDidStartNodePlacement(_ treasureController: ARPortal.TreasureController, for: ARPortal.TreasureController.Treasure) {
        
        
    }
    
    func treasureControllerDidEndNodePlacement(_ treasureController: ARPortal.TreasureController, for: ARPortal.TreasureController.Treasure) {
        
    }
    
}
