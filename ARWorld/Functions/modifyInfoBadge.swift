//
//  modifyInfoBadge.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/15/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation

func modifyInfoBadge(inNode: SCNNode, to: String) throws -> Void {
    // find the text inside the plane
    let nodes = inNode.childNodes
    for childNode in nodes {
        childNode.removeFromParentNode()
    }
    // add the desired text node to inNode
    let textGeometry = SCNText(string: to, extrusionDepth: 0.01)
    textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
    textGeometry.font = UIFont(name: "Futura", size: 2.0)
    textGeometry.isWrapped = true
    textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
    textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
    textGeometry.firstMaterial?.diffuse.contents = UIColor.white
    textGeometry.firstMaterial?.isDoubleSided = true
    textGeometry.chamferRadius = CGFloat(0)
        
    let textNode = SCNNode(geometry: textGeometry)
    textNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
    //textNode.constraints = [billBoardConstraint]
    center(node: textNode)
    textNode.position = SCNVector3Make(0, 0, 0)
    inNode.addChildNode(textNode)
}
