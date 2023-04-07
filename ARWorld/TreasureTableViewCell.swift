//
//  TreasureTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class TreasureTableViewCell: UITableViewCell {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var treasureImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var quantityLabel: UILabel!
    
    // MARK: - Properties
    
    var treasureObject: PFObject?

    // MARK: Cell life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Loading Content
    
    func loadTreasure() {
        guard treasureObject != nil else { return }
        
        DispatchQueue.global(qos: .background).async {
            let treasure = self.treasureObject!["Treasure"] as! PFObject
            let quantity = self.treasureObject!["Quantity"] as! NSNumber
            self.quantityLabel.text = String(describing: quantity)
            treasure.fetchIfNeededInBackground { (object, error) in
                if error == nil {
                    let name = object!["Name"] as! String
                    let imageFile = object!["Image"] as! PFFileObject
                    self.titleLabel.text = name
                    imageFile.getDataInBackground { (data, error) in
                        if error == nil {
                            let image = UIImage(data: data!)
                            self.treasureImageView.image = image
                        }
                    }
                }
            }
        }
    }

}
