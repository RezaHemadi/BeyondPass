//
//  UserBanner+PhotoPlane.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension UserBanner {
    class PhotoPlane: SCNNode {
        // MARK: - Properties
        var image: UIImage?
        let plane = SCNPlane(width: 10, height: 10)
        let planeNode: SCNNode
        let id: String
        
        // MARK: - Initialization
        init(id: String) {
            self.id = id
            plane.cornerRadius = 5
            
            // set up plane
            planeNode = SCNNode(geometry: plane)
            planeNode.categoryBitMask = NodeCategories.profilePic.rawValue
            planeNode.name = id
            
            super.init()
            
            addChildNode(planeNode)
            
            // Fetch Image
            fetchImage()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Fetching Image
        
        private func fetchImage() {
            DispatchQueue.main.async {
                let query = PFUser.query()
                let user = try! query!.getObjectWithId(self.id)
                if let imageFile = user["profilePic"] as? PFFileObject {
                    let imageData = try! imageFile.getData()
                    let image = UIImage(data: imageData)
                    self.plane.firstMaterial?.diffuse.contents = image
                    self.plane.firstMaterial?.lightingModel = .physicallyBased
                    self.plane.firstMaterial?.metalness.contents = 0.8
                    self.plane.firstMaterial?.roughness.contents = 0.4
                    //self.plane.firstMaterial?.emission.contents = image
                }
            }
        }
    }
}
