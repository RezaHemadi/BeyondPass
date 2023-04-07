//
//  RedBrick.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/20/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class RedBrick: Brick {
    let url = Bundle.main.url(forResource: "RedBrick", withExtension: "scn", subdirectory: "art.scnassets/RedBrick")!
    
    init() {
        super.init(url: url)!
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
