//
//  CassetteViewer.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class CassetteViewer {
    // MARK: - Configuration
    
    var radius = WHISPERFETCHINGRADIUS
    
    // MARK: - Properties
    
    var location: CLLocation {
        willSet {
            geoPoint = PFGeoPoint(location: newValue)
        }
        didSet {
            guard !isUpdating && location.distance(from: lastUpdateLocation) > 5 else { return }
            
                isUpdating = true
                updateWhispers { (succeed, error) in
                    
                }
                lastUpdateLocation = location
        }
    }
    var lastUpdateLocation: CLLocation
    
    var geoPoint: PFGeoPoint
    
    var isUpdating: Bool
    
    var addedObjects: [Cassette] = []
    
    var cassetteViewerDelegate: CassetteViewerDelegate?
    
    // MARK: - Initialization
    
    init(location: CLLocation) {
        self.location = location
        geoPoint = PFGeoPoint(location: location)
        lastUpdateLocation = location
        isUpdating = true
        updateWhispers { (succeed, error) in
        }
    }
    
    // MARK: - Updating Whispers
    
    private func fetchObjects(_ completion: @escaping (_ objects: [PFObject]?, _ error: Error?) -> Void ) {
        let query = PFQuery(className: "Cassette")
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: radius / 1000)
        query.findObjectsInBackground {
            (cassetteObjects, error) in
            completion(cassetteObjects, error)
        }
    }
    private func updateWhispers(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void ) {
        fetchObjects { (objects, error) in
            if let whispers = objects {
                
                whispers.forEach({ (object) in
                    if !self.isAddedBefore(object: object) {
                        
                        let cassette = Cassette(cassetteObject: object)
                        self.cassetteViewerDelegate?.addCassette(cassette, for: self)
                        self.addedObjects.append(cassette)
                    }
                })
                self.isUpdating = false
                completion(true, nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    private func removeRedundantWhispers(fetchedObjects: [PFObject]) {
        let redundantObjects = addedObjects.filter {
            (cassette) -> Bool in
            guard cassette.savedInDB == true else { return false }
            
            for fetchedObject in fetchedObjects {
                if cassette.id == fetchedObject.objectId! {
                    return false
                }
            }
            return true
        }
        // Remove redundant nodes and also remove them from added objects array
        redundantObjects.forEach { $0.removeFromParentNode(); if let index = addedObjects.index(of: $0) { addedObjects.remove(at: index)}}
    }
    private func isAddedBefore(object: PFObject) -> Bool {
        let objectId = object.objectId!
        
        let isAdded = addedObjects.contains { (cassette) -> Bool in
            if (!cassette.savedInDB || cassette.id! == objectId) {
                return true
            }
            return false
        }
        
        return isAdded
    }
}
protocol CassetteViewerDelegate {
    func addCassette(_ cassette: Cassette, for viewer: CassetteViewer)
}
