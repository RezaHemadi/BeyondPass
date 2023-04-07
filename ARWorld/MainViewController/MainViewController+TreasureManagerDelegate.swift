//
//  MainViewController+TreasureManagerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import AVFoundation

extension MainViewController: TreasureManagerDelegate {
    
    func adjustTreasurePosition(treasure: Treasure) {
        let position = getPosition(userLocation: locationManager.location!, userHeading: self.userHeading, to: treasure.location!)
        
        treasure.refNode.position = position
    }
    
    func treasureCollected(treasure: Treasure) {
        guard treasure.name != nil else { return }
        
        showCollectedTreasure(treasure)
        
        compassBar.bearingToTreasure = nil
    }
    
    func showTreasure(treasure: Treasure, at location: CLLocation) {
        let position = getPosition(userLocation: locationManager.location!, userHeading: self.userHeading, to: location)
        sceneView.addInfrontOfCamera(node: treasure.refNode, at: position)
    }
    
    func showTreasure(treasure: Treasure, at position: SCNVector3) {
        sceneView.addInfrontOfCamera(node: treasure.refNode, at: position)
    }
    
    // MARK: - Helper Methods
    
    func showCollectedTreasure(_ treasure: Treasure) {
        let name = treasure.name!
        let image = treasure.image
        
        let imageView = UIImageView(image: image)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        
        imageView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        /// Configure Constraints
        let centerHorizontally = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.6, constant: 0)
        let aspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
        
        view.addConstraints([centerHorizontally, centerVertically, widthConstraint])
        imageView.addConstraint(aspectRatio)
        
        UIView.animate(withDuration: 0.3) {
            imageView.transform = CGAffineTransform.identity
        }
        
        // Show Label
        let label = UILabel()
        label.text = "Found \(name)"
        label.font = UIFont(name: "Verdana", size: 50)
        label.textColor = UIColor(red: 216/255, green: 205/255, blue: 41/255, alpha: 1.0)
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Constraints
        let labelCenterHorizontally = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: label, attribute: .centerX, multiplier: 1, constant: 0)
        let labelBottomConstraint = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1, constant: -15)
        
        view.addConstraints([labelBottomConstraint, labelCenterHorizontally])
        
        let when = DispatchTime.now() + 5.0
        DispatchQueue.main.asyncAfter(deadline: when) {
            imageView.removeFromSuperview()
            label.removeFromSuperview()
        }
    }
}
