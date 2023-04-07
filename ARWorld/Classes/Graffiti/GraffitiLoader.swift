//
//  GraffitiLoader.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/30/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class GraffitiLoader {
    // MARK: - Properties
    
    var location: CLLocation {
        didSet {
            guard lastUpdateLocation != nil, lastUpdateLocation!.distance(from: location) > 10 else { return }
            
            runLoop()
        }
    }
    
    var lastUpdateLocation: CLLocation?
    
    var loadedItems: [String: PFObject] = [:]
    
    var queuedItems: [String: PFObject] = [:]
    
    var displayedItems: [String] = []
    
    var delegate: GraffitiLoaderDelegate?
    
    init(location: CLLocation) {
        self.location = location
        
        runLoop()
    }
    
    func runLoop() {
        DispatchQueue.global(qos: .background).async {
            let graffitiQuery = PFQuery(className: "Graffiti")
            let geoPoint = PFGeoPoint.init(location: self.location)
            graffitiQuery.whereKey("Location", nearGeoPoint: geoPoint, withinKilometers: 0.1)
            graffitiQuery.findObjectsInBackground() { objects, error in
                if error == nil {
                    if let graffitiObjects = objects {
                        for graffitiObject in graffitiObjects {
                            if self.displayedItems.contains(graffitiObject.objectId!) { continue }
                            self.loadedItems[graffitiObject.objectId!] = graffitiObject
                            let itemGeoPoint = graffitiObject["Location"] as! PFGeoPoint
                            let itemLocation = CLLocation.init(latitude: itemGeoPoint.latitude, longitude: itemGeoPoint.longitude)
                            if itemLocation.distance(from: self.location) < 10 {
                                self.queuedItems[graffitiObject.objectId!] = graffitiObject
                            } else {
                                self.queuedItems[graffitiObject.objectId!] = nil
                            }
                        }
                    }
                }
                // Fetching from server done
                for (key, value) in self.queuedItems {
                    self.delegate?.createGraffiti(for: self, withObject: value, withID: key)
                }
                self.lastUpdateLocation = self.location
            }
        }
        
    }
    
    func delegateDisplayedItem(withID id: String) {
        self.displayedItems.append(id)
    }
}

protocol GraffitiLoaderDelegate {
    func createGraffiti(for graffitiLoader: GraffitiLoader, withObject object: PFObject, withID id: String)
}
