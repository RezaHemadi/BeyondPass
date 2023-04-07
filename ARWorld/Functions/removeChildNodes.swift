//
//  removeChildNodes.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/15/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation

func removeChildNodes(_ node: SCNNode) -> Void {
    for node in node.childNodes {
        node.removeFromParentNode()
    }
}
