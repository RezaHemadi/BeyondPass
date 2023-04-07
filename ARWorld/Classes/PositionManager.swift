//
//  functions.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/14/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
import SceneKit
import Parse

class PositionManager {
    
    func fetchElements (location: CLLocation, radius: Double, className: String) throws -> [PFObject] {
        let userGeoPoint = PFGeoPoint(location: location)
        
        let query = PFQuery(className: className)
        
        query.whereKey("location", nearGeoPoint: userGeoPoint)
        query.limit = 10
        do {
            var objects = try query.findObjects()
            objects = objects.filter {
                (object) -> Bool in
                let targetLocation = object["location"] as! PFGeoPoint
                let objectLocation = CLLocation.init(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
                let distance = location.distance(from: objectLocation)
                
                if (distance < radius) {
                    return true
                } else {
                    return false
                }
            }
            return objects
        } catch {
            throw error
        }
    }
        
    
    
    
    func getBearing(userLocation: CLLocation, object: PFObject,
                    _ completion: @escaping (_ bearing: Double?, _ location: CLLocation?, _ error: Error?) -> Void) -> Void {
        do {
        try object.fetchIfNeeded()
        } catch {
            completion(nil, nil, error)
        }
        let objectLocation = object["location"] as! PFGeoPoint
                
        let location = CLLocation.init(latitude: objectLocation.latitude,
                                             longitude: objectLocation.longitude)
        let bearing = bearingToLocationDegrees(userLocation: userLocation, destinationLocation: location)
        completion(bearing, location, nil)
    }
    
    private func bearingToLocationRadian(_ userLocation: CLLocation, _ destinationLocation:CLLocation) -> Double {
        
        let lat1 = DegreesToRadians(userLocation.coordinate.latitude)
        let lon1 = DegreesToRadians(userLocation.coordinate.longitude)
        
        let lat2 = DegreesToRadians(destinationLocation.coordinate.latitude);
        let lon2 = DegreesToRadians(destinationLocation.coordinate.longitude);
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    private func bearingToLocationDegrees(userLocation: CLLocation, destinationLocation:CLLocation) -> Double {
        return   RadiansToDegrees(bearingToLocationRadian(userLocation, destinationLocation))
    }
    
    private func DegreesToRadians(_ degrees: Double ) -> Double {
        return degrees * Double.pi / 180
    }
    
    private func RadiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / Double.pi
    }

    func getPosition(userLocation: CLLocation, userHeading: CLLocationDirection, forYaw: Float, object: PFObject,
                     _ completion: @escaping (_ position: SCNVector3?, _ yaw: Float?, _ error: Error?) -> Void) -> Void {
        self.getBearing(userLocation: userLocation, object: object) {
            (bearing: Double?, location: CLLocation?, error: Error?) -> Void in
            if (error == nil) {
                let objectLocation = location!
                var bearing = bearing!
                var z: Double!
                var x: Double!
                
                if (bearing.isLess(than: 0)) {
                    bearing = 360 + bearing
                }
                let alpha = self.DegreesToRadians(userHeading - bearing)
                
                let distance = userLocation.distance(from: objectLocation)
                
                if (alpha > 0 && alpha < Double.pi / 2) {
                    z = distance * abs(cos(alpha))
                    x = distance * abs(sin(alpha))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha < 0) && (alpha > -(Double.pi / 2))) {
                    z = distance * abs(cos(alpha))
                    x = distance * abs(sin(alpha))
                    z = -abs(z)
                }
                if ((alpha > Double.pi / 2) && (alpha < Double.pi)) {
                    z = distance * abs(sin(alpha - (Double.pi / 2)))
                    x = distance * abs(cos(alpha - (Double.pi / 2)))
                    x = -abs(x)
                }
                if ((alpha > Double.pi) && (alpha < 3 * (Double.pi) / 2)) {
                    x = distance * abs(cos(alpha - (3 * (Double.pi) / 2)))
                    z = distance * abs(sin(alpha - (3 * (Double.pi) / 2)))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha > -(Double.pi)) && (alpha < -((Double.pi) / 2))) {
                    x = distance * abs(cos(alpha - (Double.pi / 2)))
                    z = distance * abs(sin(alpha - (Double.pi / 2)))
                }
                if ((alpha > 3 * (Double.pi / 2)) && (alpha < 2 * Double.pi)) {
                    x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
                    z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
                    z = -abs(z)
                }
                if ((alpha > (-2 * Double.pi)) && (alpha < (-3 * Double.pi / 2)))  {
                    x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
                    z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha > (-3 * (Double.pi / 2))) && (alpha < -(Double.pi))) {
                    x = distance * abs(cos((3 * (Double.pi) / 2) - alpha))
                    z = distance * abs(sin((3 * (Double.pi) / 2) - alpha))
                    x = -abs(x)
                }
                
                completion(SCNVector3.init(x: Float(x), y: 0, z: Float(z)), forYaw, nil)
            } else {
                completion(nil, nil, error)
            }
        }
        
    }
    /*
    func refresh(_ completion: @escaping (_ succeed: Bool?) -> Void) -> Void {
        self.distances.removeAll()
        self.nearElements.removeAll()
        self.farElements.removeAll()
        self.fetchElements(location: self.userLocation, radius: self.nearRadius, className: "text") {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                self.nearElements = objects
                
                self.fetchElements(location: self.userLocation, radius: self.farRadius, className: "text") {
                    (farObjects: [PFObject]?, error: Error?) -> Void in
                    if var farObjects = farObjects {
                        farObjects = farObjects.filter {
                            (object: PFObject) -> Bool in
                            let id = object.objectId
                            for element in self.nearElements {
                                if (element.objectId == id) {
                                    return false
                                }
                            }
                            return true
                        }
                        self.farElements = farObjects
                        completion(true)
                    }
                }
            }
            
        }
    }
    
        func getNearPositions(_ completion: @escaping
            (_ positions: [String:SCNVector3]?) -> Void) -> Void {
        var positions = [String: SCNVector3]()
        for object in self.nearElements {
            let id = object.objectId!
            self.getPosition(object: object) {
                (position: SCNVector3?, error: Error?) -> Void in
                if let position = position {
                    positions.updateValue(position, forKey: id)
                }
            }
            completion(positions)
        }
    }
    
    func getFarPostitions(_ completion: @escaping
        (_ positions: [String:SCNVector3]?, _ scalingFactor: [String:Double]?) -> Void) -> Void {
            
        var positions = [String: SCNVector3]()
        var scalingFactors = [String:Double]()
            
        for object in self.farElements {
            let id = object.objectId
            self.getPosition(object: object) {
                (position: SCNVector3?, error: Error?) -> Void in
                if var position = position {
                    let distanceDict = self.distances.first {
                        (key: String, value: Double) -> Bool in
                        if key == id {
                            return true
                        }
                        return false
                    }
                    let distance = distanceDict!.value
                    let scalingFactor = distance / self.farRadius
                    
                    position.y = Float(scalingFactor * 10)
                    positions.updateValue(position, forKey: id!)
                    scalingFactors.updateValue(scalingFactor, forKey: id!)
                }
            }
        }
            completion(positions, scalingFactors)
    }
 */
    func getPosition(userLocation: CLLocation, userHeading: CLLocationDirection, forYaw: Float, to: CLLocation,
                     _ completion: @escaping (_ position: SCNVector3?, _ yaw: Float?, _ error: Error?) -> Void) -> Void {
        self.getBearing(userLocation: userLocation, to: to) {
            (bearing: Double?, location: CLLocation?, error: Error?) -> Void in
            if (error == nil) {
                let objectLocation = location!
                var bearing = bearing!
                var z: Double!
                var x: Double!
                
                if (bearing.isLess(than: 0)) {
                    bearing = 360 + bearing
                }
                let alpha = self.DegreesToRadians(userHeading - bearing)
                
                let distance = userLocation.distance(from: objectLocation)
                
                if (alpha > 0 && alpha < Double.pi / 2) {
                    z = distance * abs(cos(alpha))
                    x = distance * abs(sin(alpha))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha < 0) && (alpha > -(Double.pi / 2))) {
                    z = distance * abs(cos(alpha))
                    x = distance * abs(sin(alpha))
                    z = -abs(z)
                }
                if ((alpha > Double.pi / 2) && (alpha < Double.pi)) {
                    z = distance * abs(sin(alpha - (Double.pi / 2)))
                    x = distance * abs(cos(alpha - (Double.pi / 2)))
                    x = -abs(x)
                }
                if ((alpha > Double.pi) && (alpha < 3 * (Double.pi) / 2)) {
                    x = distance * abs(cos(alpha - (3 * (Double.pi) / 2)))
                    z = distance * abs(sin(alpha - (3 * (Double.pi) / 2)))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha > -(Double.pi)) && (alpha < -((Double.pi) / 2))) {
                    x = distance * abs(cos(alpha - (Double.pi / 2)))
                    z = distance * abs(sin(alpha - (Double.pi / 2)))
                }
                if ((alpha > 3 * (Double.pi / 2)) && (alpha < 2 * Double.pi)) {
                    x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
                    z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
                    z = -abs(z)
                }
                if ((alpha > (-2 * Double.pi)) && (alpha < (-3 * Double.pi / 2)))  {
                    x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
                    z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
                    x = -abs(x)
                    z = -abs(z)
                }
                if ((alpha > (-3 * (Double.pi / 2))) && (alpha < -(Double.pi))) {
                    x = distance * abs(cos((3 * (Double.pi) / 2) - alpha))
                    z = distance * abs(sin((3 * (Double.pi) / 2) - alpha))
                    x = -abs(x)
                }
                
                completion(SCNVector3.init(x: Float(x), y: 0, z: Float(z)), forYaw, nil)
            } else {
                completion(nil, nil, error)
            }
        }
        
    }
    func getBearing(userLocation: CLLocation, to: CLLocation,
                    _ completion: @escaping (_ bearing: Double?, _ location: CLLocation?, _ error: Error?) -> Void) -> Void {
        let bearing = bearingToLocationDegrees(userLocation: userLocation, destinationLocation: to)
        completion(bearing, to, nil)
    }
}


