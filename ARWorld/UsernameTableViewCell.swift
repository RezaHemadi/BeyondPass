//
//  UsernameTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 10/21/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit

class UsernameTableViewCell: UITableViewCell {
    
    @IBOutlet var _username: UILabel!
    var username: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
