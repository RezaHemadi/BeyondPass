//
//  RockBrick.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/20/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class RockBrick: Brick {
    let url = Bundle.main.url(forResource: "RockBrick", withExtension: "scn", subdirectory: "art.scnassets/RockBrick")!
    
    init() {
        super.init(url: url)!
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
