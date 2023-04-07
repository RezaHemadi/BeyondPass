//
//  InventoryDock+InventoryItemDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension InventoryDock: InventoryItemDelegate {
    func didSelect(_ shape: InventoryItem.Shape) {
        inventoryDelegate?.inventoryDock(self, didSelectItem: shape)
    }
}
