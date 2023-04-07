//
//  nodeForScene.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/20/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation

func nodeForScene(_ name: String) throws -> SCNNode {
    let scene = SCNScene(named: "art.scnassets/\(name)")
    if let scene = scene {
        return scene.rootNode.childNode(withName: "root", recursively: true)!
    } else {
        throw AssetsError.noSuchFile
    }
}
