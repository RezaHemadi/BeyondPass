//
//  Character.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol Character {
    
    var model: SCNNode { get set }
    var isActive: Bool { get set }
    
    func activate()
}

