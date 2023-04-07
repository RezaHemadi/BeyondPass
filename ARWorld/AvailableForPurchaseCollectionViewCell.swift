//
//  AvailableForPurchaseCollectionViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/25/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class AvailableForPurchaseCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var imageView = UIImageView()
    
    var label = UILabel()
    
    var product: SKProduct?
    
    var productObject: PFObject?
    
    var priceLabel: UILabel!
    
    var dataLoaded: Bool = false
    
    var isSelectable: Bool = false
    
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    var name: String? {
        didSet {
            label.text = name
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        clipsToBounds = false
        
        activityIndicator.frame = frame
        contentView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Add ImageView
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let topConstraint = NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 15)
        let aspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.9, constant: 0)
        
        imageView.addConstraint(aspectRatio)
        contentView.addConstraints([topConstraint,
                                    centerHorizontally,
                                    widthConstraint])
        
        // Add NameLabel
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "HelveticaNeue", size: 17)
        label.textColor = UIColor.white
        label.textAlignment = .center
        
        let labelCenterHorizontally = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let labelTopConstraint = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1, constant: 5)
        let labelWidthConstraint = NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.9, constant: 0)
        
        contentView.addConstraints([labelCenterHorizontally,
                                    labelTopConstraint,
                                    labelWidthConstraint])
        label.adjustsFontSizeToFitWidth = true
        imageView.setNeedsLayout()
        imageView.layoutIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Displaying UI
    
    func loadData() {
        if let product = self.product {
            name = product.localizedTitle
            /// Fetch product image from the database
            let query = PFQuery(className: "Products")
            query.whereKey("ProductIdentifier", equalTo: product.productIdentifier)
            query.findObjectsInBackground{ (objects: [PFObject]?, error: Error?) -> Void in
                if error == nil {
                    if let object = objects?.first {
                        self.productObject = object
                        let image = object["Image"] as! PFFileObject
                        image.getDataInBackground{ (data: Data?, error: Error? ) -> Void in
                            if error == nil {
                                self.image = UIImage(data: data!)
                                self.isSelectable = true
                                self.dataLoaded = true
                                self.stopAnimating()
                                self.showPriceTag()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showPriceTag() {
        let numberFormatter = NumberFormatter.init()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        
        
        var formattedPrice: String
        
        if let product = self.product {
            numberFormatter.locale = product.priceLocale
            formattedPrice = numberFormatter.string(from: product.price)!
            
            let width = bounds.width
            let height = bounds.height
            let middleX = bounds.midX
            let topEdge = bounds.minY
            
            let priceWidth = width / 3
            let priceHeight = height / 4
            let priceX = middleX - priceWidth / 2
            let priceY = topEdge + 2
            let priceFrame = CGRect(x: priceX, y: priceY, width: priceWidth, height: priceHeight)
            priceLabel = UILabel(frame: priceFrame)
            priceLabel.clipsToBounds = true
            priceLabel.layer.cornerRadius = 5
            priceLabel.text = formattedPrice
            priceLabel.backgroundColor = UIColor.white
            priceLabel.font = UIFont(name: "HelveticaNeue", size: 15)
            priceLabel.textColor = UIColor(red: 198/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)
            priceLabel.sizeToFit()
            priceLabel.textAlignment = .center
            
            addSubview(priceLabel)
        }
    }
    
    // MARK: - Helper Methods
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
}
