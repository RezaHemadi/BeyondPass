//
//  sendFollowRequest.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/15/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

// this function follows the user if the user is not private and sends a request if the user is private
func sendFollowRequest(from: PFObject, to: PFObject, _ completion: @escaping (_ status: FollowStatus?, _ error: Error?) -> Void) -> Void {
    // check if the target user is private
    isUserPrivate(to) {
        (isPrivate: Bool?, error: Error?) -> Void in
        if let error = error {
            completion(nil, error)
        } else if let isPrivate = isPrivate {
            if isPrivate {
                
                // the user is private send them a follow request
                // create friend request object
                
                let followRequest = PFObject(className: "FollowRequest")
                followRequest["from"] = from
                followRequest["to"] = to
                followRequest["status"] = "pending"
                
                followRequest.saveInBackground {
                    (succeed: Bool?, error: Error?) -> Void in
                    if let _ = succeed {
                        completion(FollowStatus.requested, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            } else {
                // the user is not private follow them
                
                let currentUser = PFUser.current()!
                let relation = currentUser.relation(forKey: "Following")
                relation.add(to)
                completion(FollowStatus.following, nil)
                currentUser.saveInBackground {
                    (succeed: Bool?, error: Error?) -> Void in
                    if let _ = succeed {
                        
                        // create a follow request object on the server
                        let followRequest = PFObject(className: "FollowRequest")
                        followRequest["from"] = currentUser
                        followRequest["to"] = to
                        followRequest["status"] = "completed"
                        
                        followRequest.saveInBackground {
                            (succees: Bool?, error: Error?) -> Void in
                            
                            if let _ = succeed {
                                
                                let id = followRequest.objectId!
                                let params = ["id": id]
                                // call cloud code
                                PFCloud.callFunction(inBackground: "addToFollowers", withParameters: params) {
                                    (response: Any?, error: Error?) -> Void in
                                    
                                    print("Cloud function called")
                                }
                                
                                let pushParams = ["userId" : to.objectId, "fromUsername" : from["username"] as! String]
                                
                                PFCloud.callFunction(inBackground: "newFollowerPush", withParameters: pushParams) {
                                    (response, error) in
                                    
                                }
                            }
                        }
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
    }
}
