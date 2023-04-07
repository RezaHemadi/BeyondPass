//
//  SearchUserTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/8/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class SearchUserTableViewCell: UITableViewCell {
    
    @IBOutlet var _profilePic: UIImageView!
    @IBOutlet var _username: UILabel!
    @IBOutlet var _follow: UIButton!
    @IBOutlet var _distance: UILabel!
    var user: PFUser!
    var isPrivate: Bool!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        selectionStyle = UITableViewCell.SelectionStyle.none
    }
    @IBAction func followClicked(_ sender: Any) {
        if let selectedUser = self.user {
            
            self._follow.isEnabled = false
            
            selectedUser.fetchInBackground {
                (targetUser: PFObject?, error: Error?) -> Void in
                if let targetUser = targetUser {
                    self.isPrivate = targetUser["PrivateAccount"] as! Bool
                }
                if (self.isPrivate) {
                    // create friend request object
                    let followRequest = PFObject(className: "FollowRequest")
                    followRequest["from"] = PFUser.current()
                    followRequest["to"] = selectedUser
                    followRequest["status"] = "pending"
                    
                    followRequest.saveInBackground {
                        (succeed: Bool?, error: Error?) -> Void in
                        if let _ = succeed {
                            self._follow.setTitle("Requested", for: .normal)
                        }
                    }
                } else {
                    let currentUser = PFUser.current()!
                    sendFollowRequest(from: currentUser, to: selectedUser) {
                        (followStatus: FollowStatus?, error: Error?) -> Void in
                            if error == nil {
                                self._follow.setTitle("Following", for: .normal)
                                
                                // give coins
                                // give 10 coins to the current user
                                modifyARCoins(CoinTransaction.FollowedUser)
                                
                                //give 50 coins to selected user
                                PFCloud.callFunction(inBackground: "newFollowerCoin", withParameters: ["followedUserId": selectedUser.objectId!]) {
                                    (response: Any?, error: Error?) -> Void in
                                    
                                }
                            }
                    }
                }

            }
            
        }
    }
}
