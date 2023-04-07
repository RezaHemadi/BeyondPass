//
//  MainViewController+RadialMenueDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: RadialMenueDelegate {
    func radialMenue(_ radialMenue: RadialMenue, didSelect option: RadialMenue.Option) {
        // Hide Radial Menue
        UIView.animate(withDuration: ButtonsAnimationDuration) {
            radialMenue.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
        switch option {
        case .addToReality:
            plusButton.interfaceHidden = false
            unhidePlusButton()
        case .addText:
            // Display Add Text Form
            _addTextField.isUserInteractionEnabled = true
            UIView.animate(withDuration: ButtonsAnimationDuration, animations: {
                self._addTextDialog.transform = CGAffineTransform.identity
            })
        case .addObject:
            // Display SkySticker form
            showSkyStickerForm()
        case .addCassette:
            cassetteButtonTapped()
        }
    }
    private func showSkyStickerForm() {
        let skyStickerForm = SkyStickerFormView()
        view.addSubview(skyStickerForm)
        
        skyStickerForm.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: skyStickerForm, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: skyStickerForm, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: skyStickerForm, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: skyStickerForm, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.7, constant: 0)
        
        view.addConstraints([centerVertically,
                             centerHorizontally,
                             widthConstraint,
                             heightConstraint])
        view.setNeedsLayout()
        view.layoutIfNeeded()
        skyStickerForm.showCollectionView()
        skyStickerForm.delegate = self
    }
}
