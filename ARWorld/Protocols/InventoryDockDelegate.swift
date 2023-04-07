//
//  InventoryDockDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol InventoryDockDelegate: OptionsDockDelegate {
    func inventoryDock(_ dock: InventoryDock, didSelectItem item: InventoryItem.Shape)
    func inventoryDock(_ dock: InventoryDock, didSelectThrowable item: AnyObject)
}
