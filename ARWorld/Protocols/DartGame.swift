//
//  DartGame.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol DartGame {
    
    func equipDart(variant: Dart.Variant)
    func setReticle(_ reticle: DartReticleView)
    func equippedDartThrown()
    func playHitSound()
    
    var equippedDart: Dart? { get }
    var dartsCount: Int { get }
    var reticle: DartReticleView? { get set }
}
