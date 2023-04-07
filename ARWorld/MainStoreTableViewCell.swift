//
//  MainStoreTableViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class MainStoreTableViewCell: UITableViewCell {
    
    // MARK: - Interface Outlets
    @IBOutlet var productImageView: UIImageView!
    
    @IBOutlet var productDescriptionText: UITextView!
    
    @IBOutlet var purchaseButton: UIButton!
    
    @IBOutlet var priceLabel: UILabel!
    
    // MARK: - Properties
    
    var imageFile: PFFileObject?
    
    var product: SKProduct?
    
    var productDescription: String? {
        didSet {
            productDescriptionText.text = productDescription
            productDescriptionText.adjustsFontForContentSizeCategory = true
            productDescriptionText.font = UIFont(name: "Helvetica-Neue", size: 15.0)
        }
    }
    
    var state: String? {
        didSet {
            purchaseButton.setTitle(state, for: .normal)
            purchaseButton.sizeToFit()
        }
    }
    
    var price: String? {
        didSet {
            priceLabel.text = price
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        backgroundColor = UIColor.clear
        productDescriptionText.backgroundColor = UIColor.clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadContent() {
        if let imageFile = imageFile {
            imageFile.getDataInBackground() { data, error in
                if error == nil {
                    if let imageData = data {
                        self.productImageView.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
    @IBAction func purchase() {
        guard product != nil else { return }
        
        let paymentRequest = SKMutablePayment(product: product!)
        SKPaymentQueue.default().add(paymentRequest)
    }

}
