//
//  ModelLoader.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
 */
class ModelLoader {
    private(set) var loadedObjects = [Model]()
    
    private(set) var isLoading = false
    
    // MARK: - Loading object
    
    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
     */
    func loadVirtualObject(_ object: Model, loadedHandler: @escaping (Model) -> Void) {
        isLoading = true
        loadedObjects.append(object)
        
        // Load the content asynchronously.
        DispatchQueue.global(qos: .userInitiated).async {
            object.reset()
            object.load()
            
            self.isLoading = false
            loadedHandler(object)
        }
    }
    
    // MARK: - Removing Objects
    
    func removeAllVirtualObjects() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
}
