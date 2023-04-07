//
//  MainViewController+TrophyControllerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: TrophyControllerDelegate {
    func trophyController(_ controller: TrophyController, didAwardTrophy trophy: Trophy) {
        // Show "you have earned a trophy"
        showEarnedTrophy(trophy: trophy)
    }
    func trophyController(_ controller: TrophyController, didFinishFetchingTrophies trophies: [Trophy]) {
        
    }
    
    // MARK: - Helper Methods
    func showEarnedTrophy(trophy: Trophy) {
        trophy.loadImage { (image, error) in
            if let image = image {
                let imageView = UIImageView(image: image)
                
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                self.view.addSubview(imageView)
                
                imageView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                
                /// Configure Constraints
                let centerHorizontally = NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0)
                let centerVertically = NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0)
                let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 0.4, constant: 0)
                let aspectRatio = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
                
                self.view.addConstraints([centerHorizontally, centerVertically, widthConstraint])
                imageView.addConstraint(aspectRatio)
                
                UIView.animate(withDuration: 0.3) {
                    imageView.transform = CGAffineTransform.identity
                }
                
                // Show Label
                let label = UILabel()
                label.text = "You have earned a trophy"
                label.font = UIFont(name: "Verdana", size: 30)
                if self.view.traitCollection.horizontalSizeClass == .regular {
                    label.font = UIFont(name: "Verdana", size: 50)
                }
                label.textColor = UIColor(red: 216/255, green: 205/255, blue: 41/255, alpha: 1.0)
                self.view.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                
                // Configure Constraints
                let labelCenterHorizontally = NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal, toItem: label, attribute: .centerX, multiplier: 1, constant: 0)
                let labelBottomConstraint = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1, constant: -15)
                
                self.view.addConstraints([labelBottomConstraint, labelCenterHorizontally])
                
                let when = DispatchTime.now() + 5.0
                DispatchQueue.main.asyncAfter(deadline: when) {
                    imageView.removeFromSuperview()
                    label.removeFromSuperview()
                }
            }
        }
        
    }
}
