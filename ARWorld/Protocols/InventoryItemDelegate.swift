//
//  InventoryItemDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol InventoryItemDelegate: class {
    func didSelect(_ shape: InventoryItem.Shape)
}
