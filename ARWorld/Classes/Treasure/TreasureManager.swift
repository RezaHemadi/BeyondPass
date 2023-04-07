//
//  TreasureManager.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//
//  Singleton to determine what treasure and where to show

import Foundation
import SWXMLHash

class TreasureManager {
    // MARK: - Properties
    
    var initializing: Bool
    
    var activeTreasure: Treasure?
    
    private var availableTreasure: [PFObject] = []
    
    private var collectedTreasure: [PFObject] = []
    
    var delegate: TreasureManagerDelegate?
    
    private var bestLocationAccuracy: Double
    
    var location: CLLocation {
        didSet {
            guard oldValue != location && initializing == false && self.activeTreasure != nil else { print("guard failed"); return }
            
            if location.horizontalAccuracy.isLess(than: self.bestLocationAccuracy) && self.activeTreasure!.refNode.isHidden {
                bestLocationAccuracy = location.horizontalAccuracy
                delegate?.adjustTreasurePosition(treasure: self.activeTreasure!)
            }
        }
   }
    
    var currentUser: PFUser = {
        return PFUser.current()!
    }()
    
    // MARK: - Initialization
    
    init(location: CLLocation) {
        self.location = location
        self.bestLocationAccuracy = location.horizontalAccuracy
        self.initializing = true
        
        fetchAvailableTreasure { (objects, error) in
            if error == nil {
                self.fetchCollectedTreasure({ (objects, error) in
                    if error == nil {
                        self.isCurrentLocationNew({ (isNew, error) in
                            if error == nil {
                                if isNew! {
                                    if let treasure = self.randomizeTreasure() {
                                        self.activeTreasure = treasure
                                        self.showTreasure(treasure: treasure, { (succeed) in
                                            if succeed == true {
                                                self.initializing = false
                                                self.activeTreasure?.playTreasureAvailableSound()
                                                self.activeTreasure?.refNode.isHidden = true
                                            }
                                        })
                                    } else {
                                        self.initializing = false
                                    }
                                } else {
                                    self.initializing = false
                                }
                            } else {
                                self.initializing = false
                            }
                        })
                    } else {
                        self.initializing = false
                    }
                })
            } else {
                self.initializing = false
            }
        }
    }
    
    // MARK: - Database
    
    private func fetchAvailableTreasure(_ completion: @escaping (_ treasure: [PFObject]?, _ error: Error? ) -> Void) {
        let treasuresQuery = PFQuery(className: "Treasure")
        treasuresQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                if let treasure = objects {
                    self.availableTreasure = treasure
                    completion(treasure, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func fetchCollectedTreasure(_ completion: @escaping (_ treasure: [PFObject]?, _ error: Error?) -> Void) {
        let collectedTreasureQuery = PFQuery(className: "CollectedTreasure")
        collectedTreasureQuery.whereKey("User", equalTo: self.currentUser)
        collectedTreasureQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                if let collectedTreasure = objects {
                    self.collectedTreasure = collectedTreasure
                    completion(collectedTreasure, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentLocationNew(_ completion: @escaping (_ isNew: Bool?, _ error: Error?) -> Void) {
        var distances: [Double] = []
        
        outer: for collectedTreasure in collectedTreasure {
            let locationsRelation = collectedTreasure.relation(forKey: "Locations")
            let locationsQuery = locationsRelation.query()
            do {
                let locationObjects = try locationsQuery.findObjects()
                inner: for locationObject in locationObjects {
                    let geoPoint = locationObject["Location"] as! PFGeoPoint
                    
                    // Check if the location is near
                    let geoLocation = CLLocation.init(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    let distance = self.location.distance(from: geoLocation)
                    distances.append(distance)
                }
            } catch {
                completion(nil, error)
            }
        }
        if distances.contains(where: { $0.isLess(than: 1000) } ) {
            completion(false, nil)
        } else {
            completion(true, nil)
        }
    }
    
    private func randomizeTreasure() -> Treasure? {
        guard !availableTreasure.isEmpty else { return nil }
        
        let count = self.availableTreasure.count
        let randomInt = arc4random_uniform(UInt32(count))
        
        let randomTreasure = self.availableTreasure[Int(randomInt)]
        
        return Treasure(id: randomTreasure.objectId!)
    }
    
    private func showTreasure(treasure: Treasure, _ completion: @escaping (_ succeed: Bool?) -> Void) {
        treasure.loadModel({ (succeed, error) in
            if succeed == true {
                // Place the treasure around the user
                self.nearLocation({ (location, error) in
                    if error == nil {
                        if let location = location {
                            treasure.location = location
                            self.delegate?.showTreasure(treasure: treasure, at: location)
                            completion(true)
                        }
                    }
                })
            }
        })
    }
    
    private func nearLocation(_ completion: @escaping (_ location: CLLocation?, _ error: Error?) -> Void) {
        let defaultSession = URLSession(configuration: .default)
        let dataTask: URLSessionDataTask?
        
        /// Calculate a bounding box to query against
        let lat = self.location.coordinate.latitude
        let lon = self.location.coordinate.longitude
        
        let (left, right) = roundToBounds(coordinate: lon)
        let (up, down) = roundToBounds(coordinate: lat)
        
        print("left: \(left), right: \(right), up: \(up), down: \(down)")
        
        
        if var urlComponents = URLComponents(string: "https://api.openstreetmap.org/api/0.6/map") {
            urlComponents.query = "bbox=\(left),\(up),\(right),\(down)"
            
            guard let url = urlComponents.url else { return }
            
            print("URL = \(url)")
            
            dataTask = defaultSession.dataTask(with: url) { data, response, error in
                if let data = data {
                    var nodeLocations: [CLLocation] = []
                    
                    let xml = SWXMLHash.config { config in }.parse(data)
                    let nodes = xml["osm"]["node"].all
                    
                    var nearestNode: CLLocation?
                    var distance: Double?
                    for node in nodes {
                        // Check if the node has any tags
                        if let _ = node["tag"].element {
                            continue
                        }
                        let lonString = node.element?.attribute(by: "lon")?.text
                        let latString = node.element?.attribute(by: "lat")?.text
                        
                        if lonString != nil && latString != nil {
                            let longitude = Double(lonString!)!
                            let latitude = Double(latString!)!
                            let nodeLocation = CLLocation.init(latitude: latitude, longitude: longitude)
                            
                            if nearestNode == nil {
                                nearestNode = nodeLocation
                                distance = self.location.distance(from: nodeLocation)
                            } else {
                                let newDistance = self.location.distance(from: nodeLocation)
                                if newDistance.isLess(than: distance!) {
                                    nearestNode = nodeLocation
                                    distance = newDistance
                                }
                            }
                        }
                    }
                    completion(nearestNode!, nil)
                    print("Distance From nearest node: \(distance!)")
                }
            }
            
            dataTask?.resume()
        }
    }
    
    func treasureCollected() {
        guard activeTreasure != nil else { return }
        
        activeTreasure?.isCollected = true
        
        // Play Collecting treasure sound
        activeTreasure?.stopTreasureAvailableSound()
        activeTreasure?.playTreasureCollectSound()
        
        activeTreasure?.fade() { (succeed) in
            if succeed == true {
                /// Save collected treasure in db
                self.activeTreasure?.saveInDB() { (succeed, error) in
                    /// Tell the delegate the treasure is collected
                    self.delegate?.treasureCollected(treasure: self.activeTreasure!)
                    self.activeTreasure = nil
                }
            }
        }
    }
    
    private func roundToBounds(coordinate: Double) -> (Double, Double) {
        let tempInt = Int(coordinate * 1000)
        let minInt = tempInt - 1
        let maxInt = tempInt + 1
        
        return (Double(minInt) / 1000 , Double(maxInt) / 1000)
    }
    private func randomPosition() -> SCNVector3 {
        let r = drand48() * 25
        let teta = drand48() * 2 * .pi
        
        var x = r * cos(teta)
        var z = r * sin(teta)
        
        if teta > .pi / 2 && teta < .pi {
            x = -x
        } else if teta > .pi && teta <  3 * .pi / 2 {
            x = -x
            z = -z
        } else if teta > 3 * .pi / 2 {
            z = -z
        }
        
        let position = SCNVector3Make(Float(x), 0, Float(z))
        return position
    }
}

protocol TreasureManagerDelegate {
    func showTreasure(treasure: Treasure, at location: CLLocation)
    func showTreasure(treasure: Treasure, at position: SCNVector3)
    func treasureCollected(treasure: Treasure)
    func adjustTreasurePosition(treasure: Treasure)
}
