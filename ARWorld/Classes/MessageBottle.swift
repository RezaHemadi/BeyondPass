//
//  MessageBottle.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/25/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

class MessageBottle: SCNNode {
    
    var message: String!
    var owner: PFObject!
    
    init(message: String, by: PFObject) {
        
        super.init()
        
        self.message = message
        self.owner = by
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        let node = try! nodeForScene("Messegebox/MesegeBox.DAE")
        node.categoryBitMask = NodeCategories.messageBottle.rawValue
        node.scale = SCNVector3.init(0.02, 0.02, 0.02)
        buttom(node)
        self.addChildNode(node)
    }
    
    func updateID(id: String) {
        
        let childNodes = self.childNodes
        
        for node in childNodes {
            node.name = id
        }
    }
    
    func displayUserInfo() {
        
        if let owner = self.owner {
            
            owner.fetchInBackground {
                (object: PFObject?, error: Error?) -> Void in
                
                if let owner = object {
                    
                    let profilePic = owner["profilePic"] as? PFFileObject
                    
                    if let profilePic = profilePic {
                        
                        profilePic.getDataInBackground {
                            (data: Data?, error: Error?) -> Void in
                            
                            if let imageData = data {
                                
                                let userPlane = SCNPlane(width: 0.5, height: 0.5)
                                userPlane.firstMaterial?.diffuse.contents = UIImage(data: imageData)
                                
                                let billboardConstraint = SCNBillboardConstraint()
                                billboardConstraint.freeAxes = SCNBillboardAxis.Y
                                
                                userPlane.cornerRadius = 0.05
                                
                                let userPlaneNode = SCNNode(geometry: userPlane)
                                userPlaneNode.constraints = [billboardConstraint]
                                
                                userPlaneNode.position = SCNVector3Make(0, 200, 0)
                                
                                userPlaneNode.name = owner.objectId
                                userPlaneNode.categoryBitMask = NodeCategories.profilePic.rawValue
                                
                                if let root = self.childNode(withName: "root", recursively: true) {
                                    
                                    root.addChildNode(userPlaneNode)
                                    print("user plane displayed")
                                }
                            } else if let error = error {
                                print(error)
                            }
                        }
                        
                    } else {
                        
                        // user has no profile pic. display a default photo instead
                        
                    }
                } else if let error = error {
                    
                    print(error)
                }
            }
        }
    }
}
