//
//  MainViewController+PortalDecorationViewDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/5/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: PortalDecorationViewDelegate {
    func portalDecorationView(_ view: PortalDecorationsView, didSelect poduct: SKProduct) {
        
    }
    
    func portalDecorationView(_ view: PortalDecorationsView, didSelectModel model: PFObject) {
        /// Show an Activity Indicator untill the model is loaded
        let activityIndicator = UIActivityIndicatorView(style: .large)
        view.addSubview(activityIndicator)
        activityIndicator.frame = view.frame
        activityIndicator.startAnimating()
        
        let portalDecorationModel = model["DecorationModel"] as! PFObject
        portalDecorationModel.fetchIfNeededInBackground {(object: PFObject?, error: Error? ) -> Void in
            if error == nil {
                if let portalModel = object {
                    let model = portalModel["Model"] as! PFObject
                    model.fetchIfNeededInBackground { (object: PFObject?, error: Error? ) -> Void in
                        if error == nil {
                            if let model = object {
                                if let data = model["Data"] as? PFFileObject {
                                    print("loading model.")
                                    data.getDataInBackground {
                                        (modelData, error) in
                                        if error == nil {
                                            
                                            let sceneSource = SCNSceneSource(data: modelData!, options: nil)!
                                            let scene = try! sceneSource.scene(options: nil)
                                            let node = SCNNode()
                                            node.renderingOrder = 200
                                            for childNode in scene.rootNode.childNodes {
                                                node.addChildNode(childNode)
                                                node.renderingOrder = 200
                                            }
                                            
                                            self.portal?.decorationModelPreview = PreviewNode(node: node)
                                            self.portal?.decorationModelPreview?.opacity = 1.0
                                            self.portal?.decorationModelPreview?.renderingOrder = 200
                                            
                                            self.sceneView.addInfrontOfCamera(node: self.portal!.decorationModelPreview!, at: SCNVector3Make(0, 0, -1))
                                            
                                            /// Show Place or Reject indicators
                                            self.showPortalDecorationsUI()
                                            
                                            activityIndicator.stopAnimating()
                                            activityIndicator.removeFromSuperview()
                                            
                                            // Apply Textures to the model
                                            let textures = model.relation(forKey: "Textures")
                                            let texturesQuery = textures.query()
                                            texturesQuery.findObjectsInBackground {
                                                (objects, error) in
                                                if error == nil {
                                                    for object in objects! {
                                                        let materialName = object["Name"] as! String
                                                        
                                                        // Find the node corresponding to this
                                                        let targetNode = self.portal!.decorationModelPreview!.childNode(withName: materialName, recursively: true)!
                                                        let materialData = object["Data"] as! PFFileObject
                                                        let data = try! materialData.getData()
                                                        
                                                        if let mode = object["Mode"] as? String {
                                                            let textureMode = TextureMode.init(rawValue: mode)!
                                                            
                                                            switch textureMode {
                                                            case .diffuse:
                                                                targetNode.geometry?.firstMaterial?.diffuse.contents = UIImage(data: data)!
                                                            case .normal:
                                                                targetNode.geometry?.firstMaterial?.normal.contents = UIImage(data: data)!
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func portalDecorationView(_ view: PortalDecorationsView, didDeselectModel model: PFObject) {
        portalDecorationOK?.removeFromSuperview()
        portalDecorationReject?.removeFromSuperview()
        
        if let preview = portal?.decorationModelPreview {
            preview.removeFromParentNode()
            portal?.decorationModelPreview = nil
        }
    }
    
    func portalDecorationView(_ view: PortalDecorationsView, didSelectWallpaper wallpaper: PFObject) {
        /// wallpaper is a record in the "PurchasedPortalWallpapers" class
        let decorationWallpaper = wallpaper["DecorationWallpaper"] as! PFObject
        decorationWallpaper.fetchInBackground { (object: PFObject?, error: Error? ) -> Void in
            if error == nil {
                if let decorationWallpaper = object {
                    let wallpaperFile = decorationWallpaper["Wallpaper"] as! PFFileObject
                    wallpaperFile.getDataInBackground { (data: Data?, error: Error? ) -> Void in
                        if error == nil {
                            if let wallpaperData = data {
                                self.portal?.setWallpaper(wallpaperData: wallpaperData)
                                self.portal?.currentWallpaper = wallpaper
                                
                                /// Persist the wallpaper in the "UserPortals" class
                                
                                // Check if the user has a record in the "UserPortals" class
                                let userPortalsQuery = PFQuery(className: "UserPortals")
                                userPortalsQuery.whereKey("User", equalTo: PFUser.current()!)
                                userPortalsQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                                    if error == nil {
                                        if let userPortal = objects?.first {
                                            userPortal["Wallpaper"] = wallpaper
                                            userPortal.saveInBackground { (succeed: Bool?, error: Error?) -> Void in
                                                if error == nil {
                                                    if succeed == true {
                                                        
                                                    }
                                                }
                                            }
                                        } else {
                                            /// user does not have a record in user portals; create one
                                            let userPortal = PFObject(className: "UserPortals")
                                            userPortal["User"] = PFUser.current()!
                                            userPortal["Wallpaper"] = wallpaper
                                            
                                            userPortal.saveInBackground { (succeed: Bool?, error: Error? ) -> Void in
                                                if error == nil {
                                                    if succeed == true {
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func showPortalDecorationsUI() {
        /// Show two images for accept or reject
        
        let placeImage = UIImage(named: "Place")!
        let rejectImage = UIImage(named: "Reject")!
        
        /// Add place image to the UI
        let placeImageView = UIImageView()
        placeImageView.image = placeImage
        placeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeImageView)
        placeImageView.isUserInteractionEnabled = true
        let placeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(placePortalDecorationModel))
        placeImageView.addGestureRecognizer(placeTapGestureRecognizer)
        
        /// Add Constraints for the place image view
        let placeBottomConstraint = NSLayoutConstraint(item: placeImageView, attribute: .bottom, relatedBy: .equal, toItem: portalDecorationsView!, attribute: .top, multiplier: 1, constant: -5)
        let placeAspectRatio = NSLayoutConstraint(item: placeImageView, attribute: .width, relatedBy: .equal, toItem: placeImageView, attribute: .height, multiplier: 1, constant: 0)
        let placeCenterHorizontally = NSLayoutConstraint(item: placeImageView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.3, constant: 0)
        
        placeImageView.addConstraint(placeAspectRatio)
        view.addConstraints([placeBottomConstraint,
                             placeCenterHorizontally])
        
        /// Add Reject image view to the UI
        let rejectImageView = UIImageView()
        rejectImageView.image = rejectImage
        rejectImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rejectImageView)
        rejectImageView.isUserInteractionEnabled = true
        let rejectTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(rejectPortalDecorationModel))
        rejectImageView.addGestureRecognizer(rejectTapGestureRecognizer)
        
        /// Add Constraints for the reject image view
        let rejectBottomConstraint = NSLayoutConstraint(item: rejectImageView, attribute: .bottom, relatedBy: .equal, toItem: portalDecorationsView!, attribute: .top, multiplier: 1, constant: -5)
        let rejectAspectRatio = NSLayoutConstraint(item: rejectImageView, attribute: .width, relatedBy: .equal, toItem: rejectImageView, attribute: .height, multiplier: 1, constant: 0)
        let rejectCenterHorizontally = NSLayoutConstraint(item: rejectImageView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 0.7, constant: 0)
        
        rejectImageView.addConstraint(rejectAspectRatio)
        view.addConstraints([rejectBottomConstraint,
                             rejectCenterHorizontally])
        
        /// Set the image width according to the device's horizontal size class
        if view.traitCollection.horizontalSizeClass == .compact {
            let placeWidthConstraint = NSLayoutConstraint(item: placeImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
            placeImageView.addConstraint(placeWidthConstraint)
            
            let rejectWidthConstraint = NSLayoutConstraint(item: rejectImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
            rejectImageView.addConstraint(rejectWidthConstraint)
        } else if view.traitCollection.horizontalSizeClass == .regular {
            let placeWidthConstraint = NSLayoutConstraint(item: placeImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
            placeImageView.addConstraint(placeWidthConstraint)
            
            let rejectWidthConstraint = NSLayoutConstraint(item: rejectImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
            rejectImageView.addConstraint(rejectWidthConstraint)
        }
        
        portalDecorationOK = placeImageView
        portalDecorationReject = rejectImageView
    }
    
    @objc func rejectPortalDecorationModel() {
        if portal!.editingExistingDecorationModel {
            portal!.decorationModelPreview!.removeFromParentNode()
            portal!.decorationModelPreview = nil
            if let model = portal!.editingModel {
                portal!.portalNode.addChildNode(model)
                portalDecorationOK?.removeFromSuperview()
                portalDecorationReject?.removeFromSuperview()
                portal!.editingExistingDecorationModel = false
                portal!.editingDecorationID = nil
            }
        } else {
            portalDecorationsView?.deSelectCurrentModel()
        }
    }
    
    @objc func placePortalDecorationModel() {
        if portal!.editingExistingDecorationModel {
            portalDecorationOK?.removeFromSuperview()
            portalDecorationReject?.removeFromSuperview()
            
            /// Stop Showing A Preview Of The Model
            let modelRootTransform = portal!.decorationModelPreview!.simdTransform
            let modelLocalTransform = portal!.portalNode.simdConvertTransform(modelRootTransform, from: sceneView.scene.rootNode)
            
            if (portal?.decorationModelPreview) != nil {
                let node = portal!.editingModel!
                node.simdTransform = modelRootTransform
                portal?.decorationModelPreview = nil
                sceneView.scene.rootNode.addChildNode(node)
                
                let modelItemsQuery = PFQuery(className: "PortalModelItems")
                modelItemsQuery.getObjectInBackground(withId: portal!.editingDecorationID!) { (editingObject, error) in
                    if error == nil {
                        let transformArray = NSArray(array: [modelLocalTransform.columns.0.x,
                                                             modelLocalTransform.columns.0.y,
                                                             modelLocalTransform.columns.0.z,
                                                             modelLocalTransform.columns.0.w,
                                                             modelLocalTransform.columns.1.x,
                                                             modelLocalTransform.columns.1.y,
                                                             modelLocalTransform.columns.1.z,
                                                             modelLocalTransform.columns.1.w,
                                                             modelLocalTransform.columns.2.x,
                                                             modelLocalTransform.columns.2.y,
                                                             modelLocalTransform.columns.2.z,
                                                             modelLocalTransform.columns.2.w,
                                                             modelLocalTransform.columns.3.x,
                                                             modelLocalTransform.columns.3.y,
                                                             modelLocalTransform.columns.3.z,
                                                             modelLocalTransform.columns.3.w])
                        editingObject!["Transform"] = transformArray
                        editingObject!.saveInBackground()
                        self.portal!.editingDecorationID = nil
                    }
                    
                }
            }
            return
        }
        
        portalDecorationsView?.isUserInteractionEnabled = false
        
        portalDecorationOK?.removeFromSuperview()
        portalDecorationReject?.removeFromSuperview()
        
        /// Stop Showing A Preview Of The Model
        let modelRootTransform = portal!.decorationModelPreview!.simdTransform
        let modelLocalTransform = portal!.portalNode.simdConvertTransform(modelRootTransform, from: sceneView.scene.rootNode)
        print("Model Local Transform: \(modelLocalTransform)")
        
        if let preview = portal?.decorationModelPreview, let modelObject = portalDecorationsView?.currentlySelectedModel, let currentUser = PFUser.current() {
            let clone = preview.clone()
            portal?.decorationModelPreview = nil
            sceneView.scene.rootNode.addChildNode(clone)
            
            /// Persist this placement in the db
            /// modelObject is a record in the "PurchasedPortalModel" table
            /// Persist this placement in the "UserPortals" table
            /// Find the decoration model corresponding to this placement
            let decorationModel = modelObject["DecorationModel"] as! PFObject
            decorationModel.fetchIfNeededInBackground { (object: PFObject?, error: Error? ) -> Void in
                if error == nil {
                    if let decorationModel = object {
                        /// decorationModel is a record in the "PortalDecorationModel" table
                        /// Create a record in "PortalModelItems" table
                        let portalModelItem = PFObject(className: "PortalModelItems")
                        portalModelItem["DecorationModel"] = decorationModel
                        let transformArray = NSArray(array: [modelLocalTransform.columns.0.x,
                                                             modelLocalTransform.columns.0.y,
                                                             modelLocalTransform.columns.0.z,
                                                             modelLocalTransform.columns.0.w,
                                                             modelLocalTransform.columns.1.x,
                                                             modelLocalTransform.columns.1.y,
                                                             modelLocalTransform.columns.1.z,
                                                             modelLocalTransform.columns.1.w,
                                                             modelLocalTransform.columns.2.x,
                                                             modelLocalTransform.columns.2.y,
                                                             modelLocalTransform.columns.2.z,
                                                             modelLocalTransform.columns.2.w,
                                                             modelLocalTransform.columns.3.x,
                                                             modelLocalTransform.columns.3.y,
                                                             modelLocalTransform.columns.3.z,
                                                             modelLocalTransform.columns.3.w])
                        portalModelItem["Transform"] = transformArray
                        
                        portalModelItem.saveInBackground { (succeed: Bool?, error: Error? ) -> Void in
                            if error == nil {
                                if succeed == true {
                                    /// Check if the current user has a record in the "UserPortals" table
                                    let userPortalQuery = PFQuery(className: "UserPortals")
                                    userPortalQuery.whereKey("User", equalTo: currentUser)
                                    userPortalQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                                        if error == nil {
                                            if let userPortal = objects?.first {
                                                /// append the portalModelItem to the "ModelItems" relation
                                                let modelsRelation = userPortal.relation(forKey: "ModelItems")
                                                modelsRelation.add(portalModelItem)
                                                userPortal.saveInBackground { (succeed: Bool?, error: Error?) -> Void in
                                                    if error == nil {
                                                        if succeed == true {
                                                            /// Item successfuly saved in UserPortals
                                                            
                                                            self.portalDecorationsView?.loadItems()
                                                            self.portalDecorationsView?.isUserInteractionEnabled = true
                                                        }
                                                    }
                                                }
                                            } else {
                                                /// current user does not have a record in the "UserPortals" table
                                                /// create a record in "UserPortals" for current user
                                                let userPortal = PFObject(className: "UserPortals")
                                                userPortal["User"] = currentUser
                                                
                                                let modelsRelation = userPortal.relation(forKey: "ModelItems")
                                                modelsRelation.add(portalModelItem)
                                                userPortal.saveInBackground { (succeed: Bool?, error: Error?) -> Void in
                                                    if error == nil {
                                                        if succeed == true {
                                                            /// Item Successfuly saved in "UserPortals"
                                                            
                                                            self.portalDecorationsView?.loadItems()
                                                            self.portalDecorationsView?.isUserInteractionEnabled = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
