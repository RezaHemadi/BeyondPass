//
//  ProfilePicTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 10/21/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit

class ProfilePicTableViewCell: UITableViewCell {
    
    @IBOutlet var _profilePic: UIImageView!
    var profilePic: UIImage!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        _profilePic.image = self.profilePic
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
