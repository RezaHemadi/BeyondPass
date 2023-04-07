//
//  DartGameDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol DartGameDelegate {
    func dartGame(_ game: DartGame, didBeginWith dartType: Dart.Variant)
    func dartGameDidEnd(_ game: DartGame)
    func dartGame(_ game: DartGame, equippedNewDart dartType: Dart.Variant)
}
