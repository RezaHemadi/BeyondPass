//
//  InventoryDock.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class InventoryDock: OptionsDock {
    
    var inventoryDelegate: InventoryDockDelegate?
    var inventoryItems = [InventoryItem]()
    
    init() {
        super.init(icon: UIImage(named: "Backpack")!)
        
        addInventoryItems() { succeed in
            DispatchQueue.main.async {
                // Add throwables to the dock
                let throwables = Throwable.availableThrowables
                for throwable in throwables {
                    let image = throwable.image!
                    let quantity = throwable.quantity
                    let (button, _) = self.addButtonToScrollView(icon: image)
                    throwable.delegate = self
                    button.addTarget(throwable, action: #selector(throwable.throwableTapped), for: .touchUpInside)
                }
                
                
                /// Add other default inventory items
                
                // Brick
                let woodBrick = WoodenBrick()
                let woodBrickPreview = UIImage(named: "WoodenBrick")!
                let (brickButton, _) = self.addButtonToScrollView(icon: woodBrickPreview)
                let woodBrickItem = InventoryItem(button: brickButton, shape: .simple(node: woodBrick), quantity: .infinite)
                woodBrickItem.delegate = self
                self.inventoryItems.append(woodBrickItem)
                
                
                // cylinder
                let cylinder = Cylinder()
                let cylinderPreview = UIImage(named: "CylinderPreview")!
                
                let (cylinderButton, _) = self.addButtonToScrollView(icon: cylinderPreview)
                let cylinderInventoryItem = InventoryItem(button: cylinderButton, shape: .simple(node: cylinder))
                cylinderInventoryItem.delegate = self
                self.inventoryItems.append(cylinderInventoryItem)
                
                // cone
                let cone = Cone()
                let conePreview = UIImage(named: "ConePreview")!
                
                let (coneButton, _ ) = self.addButtonToScrollView(icon: conePreview)
                let coneInventoryItem = InventoryItem(button: coneButton, shape: .simple(node: cone))
                coneInventoryItem.delegate = self
                self.inventoryItems.append(coneInventoryItem)
                
                // cube
                let cube = Cube()
                let cubePreview = UIImage(named: "CubePreview")!
                
                let (cubeButton, _) = self.addButtonToScrollView(icon: cubePreview)
                let cubeInventoryItem = InventoryItem(button: cubeButton, shape: .simple(node: cube))
                cubeInventoryItem.delegate = self
                self.inventoryItems.append(cubeInventoryItem)
                
                // pyramid
                let pyramid = Pyramid()
                let pyramidPreview = UIImage(named: "PyramidPreview")!
                
                let (pyramidButton, _) = self.addButtonToScrollView(icon: pyramidPreview)
                let pyramidInventoryItem = InventoryItem(button: pyramidButton, shape: .simple(node: pyramid))
                pyramidInventoryItem.delegate = self
                self.inventoryItems.append(pyramidInventoryItem)
                
                
                self.drawSeperatorLines()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addInventoryItems(_ completionHandler: @escaping (_ succeed: Bool?) -> Void = {(succeed) -> Void in}) {
        
        let inventoryQuery = PFQuery(className: "Inventory")
        inventoryQuery.whereKey("User", equalTo: PFUser.current()!)
        inventoryQuery.getFirstObjectInBackground {
            (object, error) in
            
            if error == nil {
                let items = object!.relation(forKey: "Items")
                let itemsQuery = items.query()
                itemsQuery.findObjectsInBackground {
                    (objects, error) in
                    if error == nil {
                        if let items = objects {
                            
                            let itemsCount = items.count
                            var i = 1
                            for item in items {
                                
                                let model = item["Model"] as! PFObject
                                let count = item["Quantity"] as! Int
                                
                                model.fetchInBackground {
                                    (model, error) in
                                    if error == nil {
                                        
                                        let imageName = model!["imageName"] as! String
                                        let image = UIImage(named: imageName)!
                                        
                                        let (button, badge) = self.addButtonToScrollView(icon: image, count: count)
                                        let inventoryItem = InventoryItem(button: button, object: model!)
                                        
                                        if let badge = badge {
                                            inventoryItem.badge = badge
                                            inventoryItem.quantity = .limited(count: count)
                                        } else {
                                            inventoryItem.quantity = .infinite
                                        }
                                        
                                        inventoryItem.delegate = self
                                        
                                        self.inventoryItems.append(inventoryItem)
                                        
                                        if i == itemsCount {
                                            completionHandler(true)
                                        }
                                        i += 1
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

extension InventoryDock {
    // static functions and variables
    
}
