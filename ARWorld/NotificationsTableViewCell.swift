//
//  NotificationsTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/10/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class NotificationsTableViewCell: UITableViewCell {
    
    @IBOutlet var _profilePic: UIImageView!
    @IBOutlet var _username: UILabel!
    @IBOutlet var _accept: UIButton!
    @IBOutlet var _decline: UIButton!
    @IBOutlet var _distance: UILabel!
    
    var user: PFUser!
    var id: String!
    var followRequest: PFObject!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func accept(sender: UIButton) {
        if (self.user != nil) {
            if let id = self.id {
                PFCloud.callFunction(inBackground: "addFriendToFollowersRelation", withParameters: ["followRequest": id]) {
                    (objectId: Any?, error: Error?) -> Void in
                }
            }
            
            if let friendRequest = self.followRequest {
                // add the user to the currentUsers followers relation
                let targetUser = friendRequest["from"] as! PFObject
                targetUser.fetchIfNeededInBackground {
                    (object: PFObject?, error: Error?) -> Void in
                    if let object = object {
                        let followersRelation = PFUser.current()!.relation(forKey: "Followers")
                        followersRelation.add(object)
                        PFUser.current()!.saveInBackground {
                            (success: Bool?, error: Error?) -> Void in
                            if let _ = success {
                                friendRequest["status"] = "accepted"
                                friendRequest.saveInBackground()
                                modifyARCoins(CoinTransaction.NewFollower)
                                
                                // give the from user coins for following this user
                                let params = ["followingUserId": object.objectId!]
                                PFCloud.callFunction(inBackground: "newFollowingCoin", withParameters: params) {
                                    (response: Any?, error: Error?) -> Void in
                                }
                                
                                let pushParams = ["userId": object.objectId!,
                                                  "username": PFUser.current()!.username]
                                
                                PFCloud.callFunction(inBackground: "acceptedFollowingPush", withParameters: pushParams)
                                self.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func decline(sender: UIButton) {
        if (self.user != nil) {
            
            if let friendRequest = self.followRequest {
                friendRequest["status"] = "declined"
                friendRequest.saveInBackground()
            }
        }
        self.isHidden = true
    }

}
