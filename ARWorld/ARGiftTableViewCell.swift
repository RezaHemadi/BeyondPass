//
//  ARGiftTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/11/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class ARGiftTableViewCell: UITableViewCell {
    // MARK: - Interface Outlets
    
    @IBOutlet var itemTitle: UILabel!
    @IBOutlet var itemImage: UIImageView!
    @IBOutlet var availableQuantity: UILabel!
    @IBOutlet var giftingQuantity: UITextField!
    
    // MARK: - UI Elements
    
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    var itemsRelation: PFRelation<PFObject>?
    
    var delegate: ARGiftTableViewCellDelegate?
    
    var giftType: GiftType!
    
    var inventoryItem: PFObject!
    
    var collectedTreasureObject: PFObject!
    
    var dataLoaded: Bool = false
    
    var index: Int!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.gray
        
        giftingQuantity.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - UI
    
    func showActivityIndicator() {
        // Hide all UI Elements
        itemTitle.isHidden = true
        itemImage.isHidden = true
        availableQuantity.isHidden = true
        giftingQuantity.isHidden = true
        
        self.contentView.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        
        contentView.addConstraints([centerVertically,
                                    centerHorizontally])
 
        
        activityIndicator.startAnimating()
    }
    
    // MARK: - Load Inventory Item
    
    func loadContent() {
        itemTitle.isHidden = false
        itemImage.isHidden = false
        availableQuantity.isHidden = false
        giftingQuantity.isHidden = false
        
        switch giftType! {
            
        case .arCoin:
            itemTitle.text = "AR Coin"
            itemImage.image = UIImage(named: "ARCoin")
            availableQuantity.text = String(describing: PFUser.current()!["ARCoin"] as! Int)
            activityIndicator.stopAnimating()
            self.dataLoaded = true
        case .inventory:
            let itemsQuery = itemsRelation!.query()
            itemsQuery.findObjectsInBackground {
                (objects, error) in
                if let inventoryItems = objects {
                    let cellItem = inventoryItems[self.index]
                    self.inventoryItem = cellItem
                    
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
                            self.itemTitle.text = modelName
                            self.dataLoaded = true
                            
                            self.activityIndicator.stopAnimating()
                        } else if let _  = error {
                            
                        }
                    }
                } else if let _ = error {
                    return
                }
            }
        case .treasure:
            let quantity = collectedTreasureObject["Quantity"] as! NSNumber
            let treasureObject = collectedTreasureObject["Treasure"] as! PFObject
            
            self.availableQuantity.text = String(describing: quantity)
            treasureObject.fetchIfNeededInBackground { (object, error) in
                if error == nil {
                    if let treasure = object {
                        let name = treasure["Name"] as! String
                        let imageFile = treasure["Image"] as! PFFileObject
                        self.itemTitle.text = name
                        
                        imageFile.getDataInBackground { (data, error) in
                            if error == nil {
                                if let imageData = data {
                                    self.itemImage.image = UIImage(data: imageData)!
                                    self.activityIndicator.stopAnimating()
                                    self.dataLoaded = true
                                }
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
}

extension ARGiftTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField.text != nil, Int(textField.text!) != nil else { return }
        
        // Check if the input is more than the available quantity
        if Int(availableQuantity.text!)! < Int(textField.text!)! {
            textField.text = availableQuantity.text
        }
        
        delegate?.arGiftTableViewCell(self, didChangeGiftingAmount: Int(textField.text!)!)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
            return true
        }
        return false
    }
}
