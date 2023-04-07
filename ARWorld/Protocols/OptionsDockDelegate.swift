//
//  DockDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/11/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol OptionsDockDelegate {
    func dockDidCollapse(_ dock: OptionsDock)
    func dockDidExpand(_ dock: OptionsDock)
}
