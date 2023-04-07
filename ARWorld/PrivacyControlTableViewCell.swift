//
//  PrivacyControlTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/12/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class PrivacyControlTableViewCell: UITableViewCell {
    
    var user: PFUser!
    
    @IBOutlet var privacySwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.user = PFUser.current()!
        
        self.privacySwitch.isOn = false
        
        let query = PFUser.query()
        query?.whereKey("username", equalTo: self.user.username!)
        
        query?.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                let user = objects.first
                let privacy = user!["PrivateAccount"] as? Bool
                
                if let privacy = privacy {
                
                    if (privacy) {
                        self.privacySwitch.isOn = true
                    } else {
                        self.privacySwitch.isOn = false
                    }
                }
            } else {
                self.privacySwitch.isEnabled = false
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func switchPrivacy(sender: UISwitch) {
        if (self.privacySwitch.isOn) {
            let user = self.user!
            user["PrivateAccount"] = true
            user.saveInBackground {
                (succeed: Bool?, error: Error?) -> Void in
                if let _ = error {
                    self.privacySwitch.isOn = false
                }
            }
        } else {
            let user = self.user!
            user["PrivateAccount"] = false
            user.saveInBackground {
                (succeed: Bool?, error: Error?) -> Void in
                if let _ = error {
                    self.privacySwitch.isOn = true
                }
            }
        }
    }

}
