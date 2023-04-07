//
//  InventoryItem.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class InventoryItem {
    
    enum Quantity {
        case infinite
        case limited(count: Int)
        
        mutating func decrease(amount: Int = 1) {
            switch self {
            case let .limited(count):
                guard count > 0 else { return }
                
                self = .limited(count: count - amount)
            case .infinite:
                return
            }
        }
    }
    
    enum Shape {
        case simple(node: SCNNode)
        case complex(model: Model)
    }
    
    let button: UIButton
    
    var object: PFObject?
    
    var shape: Shape
    
    var badge: UILabel?
    
    var quantity: Quantity
    
    weak var delegate: InventoryItemDelegate?
    
    
    init(button: UIButton, shape: Shape, quantity: Quantity = .infinite) {
        self.button = button
        self.shape = shape
        self.quantity = quantity
        
        self.button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    convenience init(button: UIButton, object: PFObject, quantity: Quantity = .infinite) {
        var shape: Shape?
        
        let objectName = object["Name"] as? String
        
        if objectName == "BlueBrick" {
            shape = .complex(model: BlueBrick())
        } else if objectName == "GreenBrick" {
            shape = .complex(model: GreenBrick())
        } else if objectName == "PurpleBrick" {
            shape = .complex(model: PurpleBrick())
        } else if objectName == "RockBrick" {
            shape = .complex(model: RockBrick())
        } else if objectName == "RedBrick" {
            shape = .complex(model: RedBrick())
        } else if objectName == "Battery" {
            shape = .complex(model: Battery() )
        } else {
            let model = Model.availableObjects.first {
                (virtualObject) -> Bool in
                if virtualObject.modelName == objectName {
                    return true
                }
                return false
            }
            shape = .complex(model: model!)
        }
        
        self.init(button: button, shape: shape!, quantity: quantity)
        
        self.object = object
    }
    
    @objc func buttonTapped() {
        switch quantity {
        case .infinite:
            self.delegate?.didSelect(shape)
        case .limited(let count):
            guard count > 0 else { return }
            
            self.delegate?.didSelect(shape)
            
            quantity.decrease()
            
            // change amount label in the inventory dock
            self.badge?.text = String(count - 1)
        }
    }
}
