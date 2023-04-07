//
//  TrophyController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class TrophyController {
    
    // MARK: - Properties
    
    var user: PFUser
    
    var trophies: [Trophy] = []
    
    var delegate: TrophyControllerDelegate?
    
    init(user: PFUser) {
        self.user = user
    }
    
    func loadTrophies(_ completion: @escaping (_ trophies: [Trophy]?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let trophyQuery = PFQuery(className: "Trophy")
            trophyQuery.whereKey("Owner", equalTo: self.user)
            trophyQuery.includeKey("Model")
            trophyQuery.includeKey("Owner")
            let trophies = try? trophyQuery.findObjects()
            if let trophies = trophies {
                trophies.forEach( {self.trophies.append(Trophy(object: $0))} )
                self.delegate?.trophyController(self, didFinishFetchingTrophies: self.trophies)
                completion(self.trophies)
            }
        }
    }
    
    func storyDidFinishEpisode(_ episode: Int) {
        switch episode {
        case 1:
            // Define the trophy
            let trophyQuery = PFQuery(className: "Trophy")
            let model = PFObject(withoutDataWithClassName: "Models", objectId: "iOZap8qVxn")
            trophyQuery.whereKey("Owner", equalTo: user)
            trophyQuery.whereKey("Model", equalTo: model)
            trophyQuery.findObjectsInBackground { (objects, error) in
                if error == nil {
                    if objects!.isEmpty {
                        let trophyObject = PFObject(className: "Trophy")
                        trophyObject["Owner"] = self.user
                        trophyObject["Model"] = model
                        trophyObject.saveInBackground(block: { (succeed, error) in
                            if error == nil {
                                let trophy = Trophy(object: trophyObject)
                                self.delegate?.trophyController(self, didAwardTrophy: trophy)
                            }
                        })
                    }
                }
            }
        default:
            return
        }
    }
}

protocol TrophyControllerDelegate {
    func trophyController(_ controller: TrophyController, didFinishFetchingTrophies trophies: [Trophy]) -> Void
    func trophyController(_ controller: TrophyController, didAwardTrophy trophy: Trophy)
}
