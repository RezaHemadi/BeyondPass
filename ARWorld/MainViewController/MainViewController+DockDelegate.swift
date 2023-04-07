//
//  MainViewController+DockDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: DockDelegate {
    func dock(_ dock: Dock, didCollapse: Bool) {
        print("Dock collapsed")
        hintsController.tracker = .mainView
    }
    
    func dock(_ dock: Dock, didExpande: Bool) {
        print("Dock expanded")
        hintsController.tracker = .openLeftDock
    }
    
    func dock(_ dock: Dock, didHide: Bool) {
        
    }
}
