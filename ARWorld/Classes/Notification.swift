//
//  Notification.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/10/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

class Notification {
    var followRequest = [PFObject]()
    var totalFollowRequests: Int!
    var user: PFUser!
    
    init(user: PFUser) {
        self.user = user
        
    }
    
    func fetchFollowRequests(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void) -> Void {
        let query = PFQuery(className: "FollowRequest")
        query.whereKey("to", equalTo: self.user)
        query.whereKey("status", equalTo: "pending")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                self.followRequest = objects
                self.totalFollowRequests = self.followRequest.count
                completion (true, nil)
            } else {
                self.totalFollowRequests = 0
                if let error = error {
                    completion(nil, error)
                }
            }
        }
    }
}
