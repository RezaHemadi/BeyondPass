//
//  MainViewController+HintsControllerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: HintsControllerDelegate {
    func hintsController(_ controller: HintsController, showHint: UIImageView) {
        print("Showing hint")
        view.addSubview(showHint)
        
        let aspectRatio = showHint.bounds.width / showHint.bounds.height
        
        showHint.translatesAutoresizingMaskIntoConstraints = false
        
        let centerVertically = NSLayoutConstraint(item: showHint, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: showHint, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        
        if view.traitCollection.horizontalSizeClass == .regular {
            let centerHorizontally = NSLayoutConstraint(item: showHint, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: -100)
            view.addConstraint(centerHorizontally)
        } else {
            let centerHorizontally = NSLayoutConstraint(item: showHint, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: -30)
            view.addConstraint(centerHorizontally)
        }
        
        
        let aspectRatioConstraint = NSLayoutConstraint(item: showHint, attribute: .width, relatedBy: .equal, toItem: showHint, attribute: .height, multiplier: aspectRatio, constant: 0)
        
        showHint.addConstraint(aspectRatioConstraint)
        
        view.addConstraints([centerVertically,
                             widthConstraint])
        
        showHint.tag = MainView.hint.rawValue
    }
    
    func hintsController(_ controller: HintsController, removeHint: UIImageView) {
        print("Removing hint")
        let hint = view.viewWithTag(MainView.hint.rawValue)
        
        hint?.removeFromSuperview()
    }
}
