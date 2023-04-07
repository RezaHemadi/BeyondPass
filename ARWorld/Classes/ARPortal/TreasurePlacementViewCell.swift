//
//  TreasurePlacementViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/31/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class TreasurePlacementViewCell: UICollectionViewCell {
        
        // MARK: - Properties
        
        var imageFile: PFFileObject?
        
        private var image: UIImage? {
            didSet {
                self.imageView.image = image
            }
        }
        
        var quantity: Int? {
            didSet {
                if quantity == 0 {
                    countLabel.textColor = UIColor.red
                } else {
                    countLabel.textColor = UIColor(red: 242/255, green: 221/255, blue: 87/255, alpha: 0.6)
                }
                countLabel.text = String(describing: quantity!)
            }
        }
        
        // MARK: - UI Elements
        
        private var activityIndicator: UIActivityIndicatorView
        
        private var isSelectable: Bool = false
        
        var dataLoaded: Bool = false
        
        private var imageView: UIImageView!
        
        private var countLabel = UILabel()
        
        // MARK: Initialization
        
        override init(frame: CGRect) {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            
            super.init(frame: frame)
        
            backgroundColor = UIColor.clear
            clipsToBounds = false
            
            activityIndicator.frame = frame
            contentView.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            
            // Add ImageView
            imageView = UIImageView()
            contentView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.clipsToBounds = true
            
            let aspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
            let centerHorizontally = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
            let centerVertically = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 0.8, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.7, constant: 0)
            
            imageView.addConstraint(aspectRatio)
            contentView.addConstraints([centerHorizontally,
                                        widthConstraint,
                                        centerVertically])
            
            // Add NameLabel
            contentView.addSubview(countLabel)
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = UIFont(name: "Verdana-Bold", size: 17)
            countLabel.textAlignment = .center
            countLabel.backgroundColor = UIColor.white
            countLabel.clipsToBounds = true
            
            let labelCenterHorizontally = NSLayoutConstraint(item: countLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
            let labelTopConstraint = NSLayoutConstraint(item: countLabel, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1, constant: 6)
            let labelWidthConstraint = NSLayoutConstraint(item: countLabel, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0)
            let labelAspectRatio = NSLayoutConstraint(item: countLabel, attribute: .width, relatedBy: .equal, toItem: countLabel, attribute: .height, multiplier: 1.3, constant: 0)
            
            countLabel.addConstraint(labelAspectRatio)
            contentView.addConstraints([labelCenterHorizontally,
                                        labelTopConstraint,
                                        labelWidthConstraint])
            
            imageView.setNeedsLayout()
            imageView.layoutIfNeeded()
            setNeedsLayout()
            layoutIfNeeded()
            
            countLabel.layer.cornerRadius = countLabel.bounds.width / 4
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        /*
        override func draw(_ rect: CGRect) {
            
            
        } */
        
        // MARK: - Methods
        
        func loadData() {
            imageFile!.getDataInBackground { imageData, error in
                if error == nil {
                    let image = UIImage(data: imageData!)!
                    self.image = image
                    self.dataLoaded = true
                    self.stopAnimating()
                    self.isSelectable = true
                }
            }
        }
        
        func toggleSelection() {
            if isSelected {
                isSelected = false
            } else {
                isSelected = true
            }
        }
        func stopAnimating() {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
}
