//
//  MainViewController+PortalDockDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/4/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: PortalDockDelegate {
    func portalDock(_ dock: PortalDock, didSelect option: PortalDock.Option) {
        switch option {
        case .decoration:
            decorationTapped()
        case .treasure:
            treasureTapped()
        }
    }
    
    func showPortalDecorationsView() {
        portalDecorationsView = PortalDecorationsView()
        portalDecorationsView!.delegate = self
        Store.sharedInstance().portalStoreDelegate = portalDecorationsView
        portalDecorationsView!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portalDecorationsView!)
        
        /// Add Constraints for the view
        let widthConstraint = NSLayoutConstraint(item: portalDecorationsView!, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: portalDecorationsView!, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.15, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: portalDecorationsView!, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: portalDecorationsView!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        
        view.addConstraints([widthConstraint, heightConstraint, bottomConstraint, centerHorizontally])
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
       portalDecorationsView!.showCollectionView()
    }
    
    fileprivate func decorationTapped() {
        dock.collapse()
        portal?.stopAnimations()
        portal?.state = .decorating
        /// Change Status Label
        statusViewController.showMessage("Tap here to end Portal Customizations.", autoHide: false)
        
        /// Show Decorations Collection View Controller
        showPortalDecorationsView()
    }
    
    fileprivate func treasureTapped() {
        optionsDock?.collapse()
        /// Change Status Label
        statusViewController.showMessage("Tap here to end Treasure placement.", autoHide: false)
        statusViewController.setBackgroundColor(UIColor(red: 209/255, green: 138/255,blue: 31/255, alpha: 1.0))
        
        let treasurePlacementView = ARPortal.TreasurePlacementView(frame: view.frame)
        treasurePlacementView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(treasurePlacementView)
        
        /// Add Constraints for the view
        let widthConstraint = NSLayoutConstraint(item: treasurePlacementView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: treasurePlacementView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.22, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: treasurePlacementView, attribute: .bottom, relatedBy: .equal, toItem: statusViewController.view, attribute: .top, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: treasurePlacementView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        
        view.addConstraints([widthConstraint, heightConstraint, bottomConstraint, centerHorizontally])
        
        portal!.treasurePlacementView = treasurePlacementView
        portal!.treasurePlacementView.dataSource = portal!.treasureController
        portal!.treasurePlacementView.delegate = portal!.treasureController!
        
        treasurePlacementView.setNeedsLayout()
        treasurePlacementView.layoutIfNeeded()
        treasurePlacementView.showCollectionView()
    }
}
