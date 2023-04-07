//
//  Trophy.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Trophy: SCNNode {
    
    // MARK: - Properties
    var owner: PFUser
    
    var model: PFObject
    
    var thumb: UIImage?
    
    init(object: PFObject) {
        self.model = object["Model"] as! PFObject
        self.owner = object["Owner"] as! PFUser
        
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadModel(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        model.fetchIfNeededInBackground { (object, error) in
            if error == nil {
                if let model = object {
                    let dataFile = self.model["Data"] as! PFFileObject
                    dataFile.getDataInBackground { (data, error) in
                        if error == nil {
                            if let modelData = data {
                                let sceneSource = SCNSceneSource(data: modelData, options: nil)
                                let scene = sceneSource?.scene(options: nil)
                                if let scene = scene {
                                    scene.rootNode.childNodes.forEach( {self.addChildNode($0)} )
                                    completion(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadImage(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        model.fetchIfNeededInBackground { (object, error) in
            if error == nil {
                if let model = object {
                    let image = model["Thumb"] as! PFFileObject
                    image.getDataInBackground { (data, error) in
                        if error == nil {
                            if let imageData = data {
                                let image = UIImage(data: imageData)
                                completion(image, nil)
                            }
                        } else if let error = error {
                            completion(nil, error)
                        }
                    }
                }
            }
        }
    }
}
