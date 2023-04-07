//
//  Throwable.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/21/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Throwable {
    var item: AnyObject
    var quantity: Quantity
    var image: UIImage?
    
    var delegate: ThrowableDelegate?
    
    enum Quantity {
        case infinite
        case limited(count: Int)
    }
    
    init(item: AnyObject, quantity: Quantity) {
        self.item = item
        self.quantity = quantity
    }
    
    @objc func throwableTapped() {
        let throwableItem = self.item
        
        switch quantity {
        case .infinite:
            self.delegate?.throwable(didSelectItem: throwableItem.clone())
        case .limited(var count):
            if count > 0 {
                self.delegate?.throwable(didSelectItem: throwableItem.clone())
                count -= 1
            }
        }
        
    }
}

extension Throwable {
    static var availableThrowables: [Throwable] = {
        var availableStuff = [Throwable]()
        
        // Append sandbox default throwables
        
        /// ball
        let ball = Ball()
        let quantity: Quantity = .infinite
        let image = UIImage(named: "BallPreview")
        let throwableBall = Throwable(item: ball, quantity: quantity)
        throwableBall.image = image
        
        availableStuff.append(throwableBall)
        
        // Grenade
        let grenade = Grenade()
        let grenadeQuantity: Quantity = .infinite
        let throwableGrenade = Throwable(item: grenade, quantity: grenadeQuantity)
        throwableGrenade.image = UIImage(named: "GrenadePreview")
        
        availableStuff.append(throwableGrenade)
        
        // Append server side inventory throwables
        
        return availableStuff
    }()
}


