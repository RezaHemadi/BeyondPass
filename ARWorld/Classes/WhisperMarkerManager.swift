//
//  WhisperMarkerManager.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class WhisperMarkerManager {
    // MARK: - Configuration
    
    let radius = WHISPERMARKERFETCHINGRADIUS
    
    // MARK: - Properties
    
    var location: CLLocation {
        willSet {
            geoPoint = PFGeoPoint(location: location)
        }
        didSet {
            guard location.distance(from: lastUpdateLocation) > 5 else { return }
            
            if !isUpdating {
                updateMarkers({(succeed, error) in})
            }
        }
    }
    
    var geoPoint: PFGeoPoint
    
    var lastUpdateLocation: CLLocation
    
    var delegate: WhisperMarkerManagerDelegate?
    
    var isUpdating: Bool
    
    var markers: [String: CompassMarker] = [:]
    
    // MARK: - Initialization
    
    init(location: CLLocation) {
        self.location = location
        geoPoint = PFGeoPoint(location: location)
        lastUpdateLocation = location
        isUpdating = false
        updateMarkers({(succeed, error) in})
    }
    
    // MARK: Fetching Whispers
    
    private func fetchWhispers(_ completion: @escaping (_ whispers: [PFObject]?, _ error: Error?) -> Void) {
        let query = PFQuery(className: "Cassette")
        query.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: radius / 1000)
        DispatchQueue.global(qos: .background).async {
            do {
                let objects = try query.findObjects()
                completion(objects, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func updateMarkers(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        isUpdating = true
        
        fetchWhispers { (objects, error) in
            if let whispers = objects {
                for whisper in whispers {
                    if !self.isAddedBefore(object: whisper) {
                        let markerGeoPoint = whisper["location"] as! PFGeoPoint
                        let markerLocation = CLLocation(latitude: markerGeoPoint.latitude, longitude: markerGeoPoint.longitude)
                        let bearing = bearingToLocationDegrees(userLocation: self.location, destinationLocation: markerLocation)
                        let normalizedBearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
                        let marker = CompassMarker(bearing: normalizedBearing, style: .whisper)
                        self.delegate?.addMarker(marker, with: whisper.objectId!, for: self)
                        self.markers[whisper.objectId!] = marker
                    } else {
                        if let marker = self.markers[whisper.objectId!] {
                            let markerGeoPoint = whisper["location"] as! PFGeoPoint
                            let markerLocation = CLLocation(latitude: markerGeoPoint.latitude, longitude: markerGeoPoint.longitude)
                            let bearing = bearingToLocationDegrees(userLocation: self.location, destinationLocation: markerLocation)
                            let normalizedBearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
                            marker.bearing = normalizedBearing
                            self.delegate?.updateMarker(marker, with: whisper.objectId!, for: self)
                        }
                    }
                }
                self.isUpdating = false
                completion(true, nil)
            } else {
                self.isUpdating = false
                completion(nil, error)
            }
        }
    }
    
    private func isAddedBefore(object: PFObject) -> Bool {
        let objectId = object.objectId!
        
        if let _ = markers[objectId] {
            return true
        }
        return false
    }
}
protocol WhisperMarkerManagerDelegate {
    func addMarker(_ marker: CompassMarker, with id: String, for whisperMarkerManager: WhisperMarkerManager)
    func updateMarker(_ marker: CompassMarker, with id: String, for whisperMarkerManager: WhisperMarkerManager)
}
