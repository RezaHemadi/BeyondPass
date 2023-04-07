//
//  center.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/15/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
func center(node: SCNNode) {
    let center = node.boundingSphere.center
    /*
    let dx = min.x + 0.5 * (max.x - min.x)
    let dy = min.y + 0.5 * (max.y - min.y)
    let dz = min.z + 0.5 * (max.z - min.z)
 */
    node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
}
