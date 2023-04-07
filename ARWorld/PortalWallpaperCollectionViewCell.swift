//
//  PortalWallpaperCollectionViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/25/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class PortalWallpaperCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    var decorationWallpaperObject: PFObject?
    
    override var isSelected: Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var isSelectable: Bool = false
    
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
    
    var dataLoaded: Bool = false
    
    var imageView = UIImageView()
    
    var label = UILabel()
    
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
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        var points: [CGPoint] = []
        let width = bounds.width * 0.9
        points.append(CGPoint(x: bounds.minX + (bounds.width - width) / 2, y: bounds.minY + 15))
        points.append(CGPoint(x: bounds.maxX - (bounds.width - width) / 2, y: bounds.minY + 15))
        points.append(CGPoint(x: bounds.maxX - (bounds.width - width) / 2, y: bounds.minY + width + 15))
        points.append(CGPoint(x: bounds.minX + (bounds.width - width) / 2, y: bounds.minY + width + 15))
        points.append(CGPoint(x: bounds.minX + (bounds.width - width) / 2, y: bounds.minY + 15))
        
        path.move(to: points[0])
        for point in points[1...4] {
            path.addLine(to: point)
        }
        
        if isSelected {
            UIColor(red: 59/255.0, green: 103/255.0, blue: 191/255.0, alpha: 1).setStroke()
            path.lineWidth = 8
            path.stroke()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Load Content
    
    func loadContent() {
        // We are working with the "PurchasedPortalWallpapers" class
        if let purchasedWallpaper = self.decorationWallpaperObject {
            let decorationWallpaper = purchasedWallpaper["DecorationWallpaper"] as! PFObject
            decorationWallpaper.fetchInBackground {(object: PFObject?, error: Error?) -> Void in
                if error == nil {
                    if let wallpaper = object {
                        let name = wallpaper["Name"] as! String
                        self.name = name
                        let imageFile = wallpaper["Image"] as! PFFileObject
                        imageFile.getDataInBackground { (data: Data?, error: Error?) -> Void in
                            if error == nil {
                                if let imageData = data {
                                    self.image = UIImage(data: imageData)
                                    
                                    self.dataLoaded = true
                                    self.stopAnimating()
                                    self.isSelectable = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UI
    
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
