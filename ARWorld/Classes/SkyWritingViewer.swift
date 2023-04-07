//
//  SkyWritingViewer.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class SkyWritingViewer {
    // MARK: - Configuration
    
    var radius: Double = SKYWRITINGFETCHINGRADIUS
    
    // MARK: - Properties
    
    var location: CLLocation {
        willSet {
            geoPoint = PFGeoPoint(location: newValue)
        }
        didSet {
            guard !isUpdating && location.distance(from: lastUpdateLocation) > 5 else { return }
            
            lastUpdateLocation = location
            isUpdating = true
            updateSkyWritings { (succeed, error) in
            }
        }
    }
    
    var lastUpdateLocation: CLLocation
    
    var geoPoint: PFGeoPoint
    
    var addedObjects: [SkyWriting] = []
    
    var isUpdating: Bool = false
    
    var skyWritingViewerDelegate: SkyWritingViewerDelegate?
    
    // MARK: - Initializers
    
    init(location: CLLocation) {
        self.location = location
        lastUpdateLocation = location
        geoPoint = PFGeoPoint(location: location)
        isUpdating = true
        updateSkyWritings { (succeed, error) in
        }
    }
    
    // MARK: - Fetching Objects
    
    private func fetchObjects(_ completion: @escaping (_ objects: [PFObject]?, _ error: Error?) -> Void) {
        let query = PFQuery(className: "text")
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: radius / 1000)
        query.findObjectsInBackground {
            (texts: [PFObject]?, error: Error?) -> Void in
            completion(texts, error)
        }
    }
    
    private func updateSkyWritings(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        fetchObjects { (texts, error) in
            if let texts = texts {
                
                texts.forEach({ (object) in
                    if !self.isAddedBefore(object: object) {
                        let skyWriting = SkyWriting(textObject: object)
                        self.skyWritingViewerDelegate?.addSkyWriting(skyWriting, for: self)
                        self.addedObjects.append(skyWriting)
                    }
                })
                self.isUpdating = false
                completion(true, nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    
    private func isAddedBefore(object: PFObject) -> Bool {
        let objectId = object.objectId!
        
        let isAdded = addedObjects.contains { (skyWriting) -> Bool in
            if (!skyWriting.savedInDB || skyWriting.id! == objectId) {
                return true
            }
            return false
        }
        
        return isAdded
    }
}

protocol SkyWritingViewerDelegate {
    func addSkyWriting(_ skyWriting: SkyWriting, for viewer: SkyWritingViewer)
}
