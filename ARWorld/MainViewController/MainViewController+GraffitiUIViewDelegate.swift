//
//  MainViewController+GraffitiUIViewDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: GraffitiUIDelegate {
    func graffitiUI(_ graffitiUI: GraffitiUIView, didBeginTouch: Bool) {
        if didBeginTouch, let lastHitTestResult = lastHitTest {
            // Create a graffiti instance
            sceneView.createGraffiti(lastHitTestResult, usingColor: sprayCan.color, at: self.location)
        }
    }
    func graffitiUI(_ graffitiUI: GraffitiUIView, didContinueSpraying: Bool) {
        if didContinueSpraying, let lastHitTestResult = lastHitTest {
            sceneView.updateGraffiti(lastHitTestResult, usingColor: sprayCan.color)
            sprayCan.playSpraySound()
        }
    }
    func graffitiUI(_ graffitiUI: GraffitiUIView, didFinishSpraying: Bool) {
        if didFinishSpraying, let lastHitTestResult = lastHitTest {
            sceneView.stopSpraying(lastHitTestResult)
        }
    }
}
