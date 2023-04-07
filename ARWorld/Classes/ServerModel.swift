//
//  ServerModel.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/30/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import SceneKit
import Parse

class ServerModel {
    
    var name: String!
    var id: String!
    private var imageFile: PFFileObject!
    private var scn: PFFileObject!
    var indoorScale: Float!
    var outdoorScale: Float!
    var context: ObjectContext!
    var image: UIImage!
    
    init(object: PFObject) {
        
        self.name = object["name"] as? String
        self.id = object["id"] as? String
        self.imageFile = object["image"] as? PFFileObject
        self.scn = object["scn"] as? PFFileObject
        self.indoorScale = object["indoorScale"] as? Float
        self.outdoorScale = object["outdoorScale"] as? Float
        
        let contextString = object["context"] as? String
        
        if let contextString = contextString {
            
            if contextString == "indoor" {
                
                self.context = ObjectContext.inside
            } else if contextString == "outdoor" {
                
                self.context = ObjectContext.outside
            } else {
                
                self.context = ObjectContext.both
            }
        }
        
    }
    
    func loadImage(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) -> Void {
        
        if let imageFile = self.imageFile {
            
            imageFile.getDataInBackground {
                (data: Data?, error: Error?) -> Void in
                
                if let error = error {
                    
                    completion(nil, error)
                } else if let imageData = data {
                    
                    self.image = UIImage(data: imageData)
                    completion(UIImage(data: imageData), nil)
                }
            }
        }
    }
    
    func loadNode(_ completion: @escaping (_ node: SCNNode?, _ error: Error?) -> Void) -> Void {
        
        if let scn = self.scn {
            
            let rootNode = SCNNode()
            scn.getDataInBackground {
                (data: Data?, error: Error?) -> Void in
                
                if let modelData = data {
                    
                    let sceneSource = SCNSceneSource(data: modelData, options: [:])
                    let scene = sceneSource?.scene(options: [:])
                    
                    for sceneNode in (scene?.rootNode.childNodes)! {
                        
                        self.loadImage() {
                            (image: UIImage?, error: Error?) -> Void in
                            
                            if let image = image {
                                
                                if let geometry = sceneNode.geometry {
                                    
                                    geometry.firstMaterial?.diffuse.contents = image
                                }
                            }
                        }
                        
                        rootNode.addChildNode(sceneNode)
                    }
                    
                    completion(rootNode, nil)
                } else if let error = error {
                    
                    completion(nil, error)
                }
            }
        }
    }
}
