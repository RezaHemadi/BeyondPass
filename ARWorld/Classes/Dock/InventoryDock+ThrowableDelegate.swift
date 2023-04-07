//
//  InventoryDock+ThrowableDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/21/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension InventoryDock: ThrowableDelegate {
    func throwable(didSelectItem item: AnyObject) {
        self.inventoryDelegate?.inventoryDock(self, didSelectThrowable: item)
    }
}
