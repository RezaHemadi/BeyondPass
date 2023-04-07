//
//  SkyStickerFormViewCell.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/27/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class SkyStickerFormViewCell: UICollectionViewCell {
    
    // MARK: - Configuration
    
    
    // MARK: - Properties
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    // MARK: - UI
    
    var imageView = UIImageView()
    var nameLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
        
        // Add ImageView
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white
        
        let topConstraint = NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 5)
        let aspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.8, constant: 0)
        
        imageView.addConstraint(aspectRatio)
        contentView.addConstraints([topConstraint,
                                    centerHorizontally,
                                    widthConstraint])
        
        imageView.setNeedsLayout()
        imageView.layoutIfNeeded()
        
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        
        // Add NameLabel
        /*
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont(name: "HelveticaNeue", size: 17)
        nameLabel.textColor = UIColor.white
        nameLabel.textAlignment = .center
        
        let bottomConstraint = NSLayoutConstraint(item: nameLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 5)
        let labelCenterHorizontally = NSLayoutConstraint(item: nameLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let labelTopConstraint = NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1, constant: 5)
        
        contentView.addConstraints([bottomConstraint,
                                   labelCenterHorizontally,
                                   labelTopConstraint])
        nameLabel.adjustsFontSizeToFitWidth = true */
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) { /*
        let innerRect = rect.insetBy(dx: 1, dy: 1)
        let path = UIBezierPath()
        var points: [CGPoint] = []
        points.append(CGPoint(x: innerRect.minX, y: innerRect.minY))
        points.append(CGPoint(x: innerRect.maxX, y: innerRect.minY))
        points.append(CGPoint(x: innerRect.maxX, y: innerRect.maxY))
        points.append(CGPoint(x: innerRect.minX, y: innerRect.maxY))
        points.append(CGPoint(x: innerRect.minX, y: innerRect.minY))
        
        path.move(to: points[0])
        for point in points[1...4] {
            path.addLine(to: point)
        }
        UIColor.black.setStroke()
        path.lineWidth = 2
        path.stroke() */
    }
}
