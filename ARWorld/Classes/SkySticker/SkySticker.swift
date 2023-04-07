//
//  SkySticker.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class SkySticker {
    // MARK: - Types
    
    enum Model: String {
        case phoenix = "8YEA7fCAEV"
        case dragon = "KwSv2dm6p8"
        case candle = "KcvUCwlCi8"
        case flower = "C7Xhk4AvOw"
        case iceGhost = "DQKKmhVt3a"
        case heart = "9FLhexXIeM"
        
        static var allModels: [Model] = [.phoenix, .dragon, .candle, .flower, .iceGhost, .heart]
        
        func getName() -> String {
            switch self {
            case .phoenix:
                return "Phoenix"
            case .dragon:
                return "Dragon"
            case .candle:
                return "Candle"
            case .flower:
                return "Flower"
            case .iceGhost:
                return "IceGhost"
            case .heart:
                return "Heart"
            }
        }
        
        func getModelID() -> String {
            switch self {
            case .phoenix:
                return "8YEA7fCAEV"
            case .dragon:
                return "KwSv2dm6p8"
            case .candle:
                return "KcvUCwlCi8"
            case .flower:
                return "C7Xhk4AvOw"
            case .iceGhost:
                return "DQKKmhVt3a"
            case .heart:
                return "9FLhexXIeM"
            }
        }
        
        func createNode() -> SCNNode {
            switch self {
            case .phoenix:
                return Phoenix()
            case .dragon:
                return Dragon()
            case .candle:
                return Candle()
            case .flower:
                return Flower()
            case .iceGhost:
                return IceGhost()
            case .heart:
                return Heart()
            }
        }
        
        func getImage() -> UIImage {
            switch self {
            case .phoenix:
                return UIImage(named: "PhoenixPreview")!
            case .dragon:
                return UIImage(named: "Dragon")!
            case .candle:
                return UIImage(named: "CandlePhoto")!
            case .flower:
                return UIImage(named: "FlowerOutdoor")!
            case .iceGhost:
                return UIImage(named: "IceGhostPreview")!
            case .heart:
                return UIImage(named: "Heart")!
            }
        }
    }
    
    // MARK: - Properties
    
    var location: CLLocation?
    
    var geoPoint: PFGeoPoint
    
    var author: PFUser
    
    /// object id of the sky sticker objects saved in db
    var id: String?
    
    var node: SCNNode
    
    var model: Model?
    
    var savedInDB: Bool
    
    init(location: CLLocation, author: PFUser, model: SkySticker.Model) {
        self.location = location
        self.geoPoint = PFGeoPoint(location: location)
        self.author = author
        self.model = model
        self.node = model.createNode()
        self.node.categoryBitMask = NodeCategories.skySticker.rawValue
        savedInDB = false
    }
    
    init (object: PFObject) {
        savedInDB = true
        geoPoint = object["location"] as! PFGeoPoint
        location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        let author = object["author"] as! PFUser
        self.author = author
        self.id = object.objectId!
        self.node = SCNNode()
        
        let model = object["model"] as! PFObject
        model.fetchIfNeededInBackground { (model, error) in
            if error == nil {
                self.model = Model.init(rawValue: model!.objectId!)
                self.node.addChildNode(self.model!.createNode())
            }
        }
    }
    
    func saveInDB(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) {
        let object = PFObject(className: "SkySticker")
        object["author"] = author
        object["location"] = geoPoint
        let modelPointer = PFObject(withoutDataWithClassName: "Models", objectId: model?.rawValue)
        object["model"] = modelPointer
        object.saveInBackground { (succeed, error) in
            if succeed == true {
                self.id = object.objectId
                self.node.name = object.objectId
                self.savedInDB = true
                print("Sky Sticker saved in db with id: \(self.id)")
                completion(true, nil)
            } else if let error = error {
                completion(succeed, error)
            }
        }
    }
}
