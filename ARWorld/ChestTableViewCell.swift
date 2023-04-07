//
//  ChestTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/19/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class ChestTableViewCell: UITableViewCell {
    
    // MARK: - Interface Builder Outlets
    
    @IBOutlet var itemImage: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var availableQuantity: UILabel!
    
    // MARK: - UI Elements
    
    private var activityIndicator = UIActivityIndicatorView(style: .white)
    
    // MARK: - Properties
    
    var index: Int!
    var itemObject: PFObject!
    var itemsRelation: PFRelation<PFObject>?
    var isContentLoaded: Bool = false

    // MARK: Cell Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        backgroundColor = UIColor.gray
        clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: UI
    
    func showActivityIndicator() {
        // Hide All UI Elements
        itemImage.isHidden = true
        title.isHidden = true
        availableQuantity.isHidden = true
        
        contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        
        contentView.addConstraints([centerVertically, centerHorizontally])
        
        activityIndicator.startAnimating()
    }
    
    // MARK: - Load Inventory Item
    
    func loadContent() {
        guard itemsRelation != nil else { return }
        
        itemImage.isHidden = false
        title.isHidden = false
        availableQuantity.isHidden = false
        
        let itemsQuery = itemsRelation!.query()
        itemsQuery.findObjectsInBackground {
            (objects, error) in
            if let inventoryItems = objects {
                let cellItem = inventoryItems[self.index]
                self.itemObject = cellItem
                
                let model = cellItem["Model"] as! PFObject
                let quantity = cellItem["Quantity"] as! Int
                
                // set the quantity label text
                self.availableQuantity.text = String(describing: quantity)
                
                model.fetchInBackground {
                    (object, error) in
                    if let model = object {
                        let imageName = model["imageName"] as! String
                        let image = UIImage(named: imageName)
                        let modelName = model["Name"] as! String
                        
                        self.itemImage.image = image
                        self.title.text = modelName
                        
                        self.isContentLoaded = true
                        self.activityIndicator.stopAnimating()
                    } else if let _  = error {
                        
                    }
                }
            } else if let _ = error {
                return
            }
        }
    }

}
