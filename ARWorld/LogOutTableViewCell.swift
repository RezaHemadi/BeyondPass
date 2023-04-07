//
//  LogOutTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 10/22/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class LogOutTableViewCell: UITableViewCell {
    
    @IBOutlet var _logOut: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func _logOut(_ sender: Any) {
        print("log out")
        let user = PFUser.current()
        user?.deleteInBackground()
        PFUser.logOut()
    }
}
