//
//  isUserPrivate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/15/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

func isUserPrivate(_ user: PFObject, _ completion: @escaping (_ isPrivate: Bool?, _ error: Error?)-> Void) -> Void {
    var isPrivate: Bool!
    user.fetchInBackground {
        (targetUser: PFObject?, error: Error?) -> Void in
        if let error = error {
            completion(nil, error)
        } else if let targetUser = targetUser {
            isPrivate = targetUser["PrivateAccount"] as! Bool
            completion(isPrivate, nil)
        }
    }
}
