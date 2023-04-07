//
//  buttom.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/27/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
func buttom(_ node: SCNNode) {
    let (min, max) = node.boundingBox
    let dx = min.x + 0.5 * (max.x - min.x)
    let dy = min.y
    let dz = min.z + 0.5 * (max.z - min.z)
    node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
}
