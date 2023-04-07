//
//  UserBanner+StatusBox.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension UserBanner {
    
    class StatusBox: SCNNode {
        
        var status: FollowStatus? {
            didSet {
                guard oldValue != status, status != nil else { return }
                print("status changed")
                self.textNode?.removeFromParentNode()
                switch status! {
                case .following:
                    textGeometry = SCNText(string: "Following", extrusionDepth: 1.0)
                case .notFollowing:
                    textGeometry = SCNText(string: "Follow", extrusionDepth: 1.0)
                case .requested:
                    textGeometry = SCNText(string: "Requested", extrusionDepth: 1.0)
                    
                default:
                    break
                }
                self.textNode = SCNNode(geometry: textGeometry)
                self.textNode?.scale = SCNVector3Make(0.1, 0.1, 0.1)
                self.textNode?.adjustPivot(to: .center)
                DispatchQueue.main.async {
                    self.addChildNode(self.textNode!)
                }
            }
        }
        var id: String
        var boxNode: SCNNode
        var textGeometry: SCNText?
        var textNode: SCNNode?
        
        // MARK: - Initialization
        
        init(id: String) {
            self.id = id
            
            let boxGeometry = SCNBox(width: 4, height: 2, length: 2, chamferRadius: 0.3)
            boxGeometry.firstMaterial?.diffuse.contents = UIColor.green
            boxGeometry.firstMaterial?.transparency = 0.5
            boxGeometry.firstMaterial?.lightingModel = .physicallyBased
            boxGeometry.firstMaterial?.emission.contents = UIColor.green
            boxGeometry.firstMaterial?.metalness.contents = 1.0
            boxNode = SCNNode(geometry: boxGeometry)
            boxNode.adjustPivot(to: .center)
            boxNode.name = id
            
            super.init()
            
            addChildNode(boxNode)
            
            addStatus()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Follow Status indicator
        func addStatus() {
            // Fetch Status
            let query = PFUser.query()!
            query.getObjectInBackground(withId: id) {
                (object, error) in
                if error == nil {
                    PFUser.current()!.followStatus(to: object as! PFUser) {
                        (status, error) in
                        if error == nil {
                            switch status! {
                            case .notFollowing:
                                self.textGeometry = SCNText(string: "Follow",
                                                       extrusionDepth: 1)
                                self.boxNode.categoryBitMask = NodeCategories.follow.rawValue
                                
                            case .following:
                                self.textGeometry = SCNText(string: "Following",
                                                       extrusionDepth: 1)
                                
                            case .requested:
                                self.textGeometry = SCNText(string: "Requested",
                                                       extrusionDepth: 1)
                            case .currentUser:
                                break
                                
                            }
                            
                            if let textGeometry = self.textGeometry {
                                textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: 40, height: 20)
                                textGeometry.font = UIFont(name: "Futura", size: 10)
                                textGeometry.isWrapped = true
                                textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
                                textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
                                textGeometry.firstMaterial?.diffuse.contents = UIColor.white
                                textGeometry.firstMaterial?.isDoubleSided = true
                                textGeometry.firstMaterial?.lightingModel = .physicallyBased
                                textGeometry.firstMaterial?.metalness.contents = 0.8
                                textGeometry.firstMaterial?.shininess = 1.0
                                textGeometry.firstMaterial?.emission.contents = UIColor.white
                                textGeometry.chamferRadius = CGFloat(0)
                                
                                self.textNode = SCNNode(geometry: textGeometry)
                                self.textNode?.scale = SCNVector3Make(0.1, 0.1, 0.1)
                                self.textNode?.adjustPivot(to: .center)
                                DispatchQueue.main.async {
                                    self.addChildNode(self.textNode!)
                                }
                            }
                        } else {
                            print(error)
                        }
                    }
                }
            }
        }
    }
}
