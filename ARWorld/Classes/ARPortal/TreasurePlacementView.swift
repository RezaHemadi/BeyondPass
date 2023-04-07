//
//  TreasurePlacementView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/31/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class TreasurePlacementView: UIView {
        
        var confirmButton: UIButton!
        
        var cancelButton: UIButton!
        
        var collectionView: UICollectionView!
        
        var noTreasureLabel: UILabel!
        
        var dataSource: TreasurePlacementViewDataSource?
        
        var delegate: TreasurePlacementViewDelegate?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = UIColor.clear
            clipsToBounds = false
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func initNodePlacementUI() {
            /// Show two images for accept or reject
            
            let placeImage = UIImage(named: "Place")!
            let rejectImage = UIImage(named: "Reject")!
            
            /// Add place image to the UI
            confirmButton = UIButton()
            confirmButton.setImage(placeImage, for: .normal)
            confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchDown)
            confirmButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(confirmButton)
            confirmButton.isUserInteractionEnabled = true
            
            /// Add Constraints for the place image view
            let placeBottomConstraint = NSLayoutConstraint(item: confirmButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
            let placeAspectRatio = NSLayoutConstraint(item: confirmButton, attribute: .width, relatedBy: .equal, toItem: confirmButton, attribute: .height, multiplier: 1, constant: 0)
            let placeCenterHorizontally = NSLayoutConstraint(item: confirmButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.3, constant: 0)
            
            confirmButton.addConstraint(placeAspectRatio)
            addConstraints([placeBottomConstraint,
                                 placeCenterHorizontally])
            
            /// Add Reject image view to the UI
            cancelButton = UIButton()
            cancelButton.setImage(rejectImage, for: .normal)
            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchDown)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(cancelButton)
            cancelButton.isUserInteractionEnabled = true
            
            /// Add Constraints for the reject image view
            let rejectBottomConstraint = NSLayoutConstraint(item: cancelButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
            let rejectAspectRatio = NSLayoutConstraint(item: cancelButton, attribute: .width, relatedBy: .equal, toItem: cancelButton, attribute: .height, multiplier: 1, constant: 0)
            let rejectCenterHorizontally = NSLayoutConstraint(item: cancelButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 0.7, constant: 0)
            
            cancelButton.addConstraint(rejectAspectRatio)
            addConstraints([rejectBottomConstraint,
                                 rejectCenterHorizontally])
            
            /// Set the image width according to the device's horizontal size class
            if traitCollection.horizontalSizeClass == .compact {
                let placeWidthConstraint = NSLayoutConstraint(item: confirmButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
                confirmButton.addConstraint(placeWidthConstraint)
                
                let rejectWidthConstraint = NSLayoutConstraint(item: cancelButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
                cancelButton.addConstraint(rejectWidthConstraint)
            } else if traitCollection.horizontalSizeClass == .regular {
                let placeWidthConstraint = NSLayoutConstraint(item: confirmButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
                confirmButton.addConstraint(placeWidthConstraint)
                
                let rejectWidthConstraint = NSLayoutConstraint(item: cancelButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
                cancelButton.addConstraint(rejectWidthConstraint)
            }
            
            confirmButton.transform = CGAffineTransform.init(scaleX: 0, y: 0)
            cancelButton.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
        
        func showNodePlacementUI () {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    self.confirmButton.transform = CGAffineTransform.identity
                    self.cancelButton.transform = CGAffineTransform.identity
                })
            }
        }
        
        func hideNodePlacementUI () {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    self.confirmButton.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                    self.cancelButton.transform = CGAffineTransform.init(scaleX: 0, y: 0)
                })
            }
        }
        
        @objc func confirmTapped() {
            delegate?.treasurePlacementView(self, didConfirmNodePlacement: true)
        }
        
        @objc func cancelTapped() {
            delegate?.treasurePlacementView(self, didCancelNodePlacement: true)
        }
        
        @objc func collectionViewTapped(recognizer: UITapGestureRecognizer) {
            if let indexPath = collectionView.indexPathForItem(at: recognizer.location(in: collectionView)) {
                delegate?.treasurePlacementView(self, didSelectItemAt: indexPath.row)
            }
        }
        
        func reloadData() {
            collectionView?.reloadData()
        }
        
        func showCollectionView() {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: bounds.width / 4, height: bounds.height * 0.9)
            layout.scrollDirection = .horizontal
            
            collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
            collectionView.collectionViewLayout = layout
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.backgroundColor = UIColor(red: 158/255.0, green: 162/255.0, blue: 168/255.0, alpha: 0.6)
            collectionView.layer.cornerRadius = 20
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(TreasurePlacementViewCell.self, forCellWithReuseIdentifier: "cell")
            addSubview(collectionView)
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectionViewTapped))
            collectionView.addGestureRecognizer(tapGestureRecognizer)
            
            let widthConstraint = NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
            let topConstraint = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 60)
            let bottomConstraint = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
            let centerHorizontally = NSLayoutConstraint(item: collectionView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
            
            addConstraints([widthConstraint, topConstraint, bottomConstraint, centerHorizontally])
            
            noTreasureLabel = UILabel()
            noTreasureLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(noTreasureLabel)
            noTreasureLabel.text = "You have not collected any Treasure."
            noTreasureLabel.font = UIFont(name: "Verdana-Bold", size: 20)
            noTreasureLabel.textColor = UIColor(red: 242/255, green: 221/255, blue: 87/255, alpha: 1.0)
            noTreasureLabel.textAlignment = NSTextAlignment.center
            noTreasureLabel.adjustsFontSizeToFitWidth = true
            
            let leftConstraint = NSLayoutConstraint(item: noTreasureLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
            let labelCenterVertically = NSLayoutConstraint(item: noTreasureLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.3, constant: 0)
            let labelRightConstraint = NSLayoutConstraint(item: noTreasureLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
            
            addConstraints([leftConstraint, labelCenterVertically, labelRightConstraint])
            
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            
            
            reloadData()
            
            initNodePlacementUI()
        }
        
        func decrementTreasure(at index: Int) {
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! TreasurePlacementViewCell
            cell.quantity! -= 1
        }
        func incrementTreasure(at index: Int) {
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! TreasurePlacementViewCell
            cell.quantity! += 1
        }
    }
}
extension ARPortal.TreasurePlacementView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if dataSource!.itemsCount(self)  != 0 { noTreasureLabel.removeFromSuperview() }
        return dataSource!.itemsCount(self)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ARPortal.TreasurePlacementViewCell
        cell.imageFile = dataSource!.treasurePlacementView(self, imageFileForTreasureAt: indexPath.row)
        cell.quantity = dataSource!.treasurePlacementView(self, countForTreasureAt: indexPath.row)
        if !cell.dataLoaded {
            cell.loadData()
        }
        
        return cell
    }
}
extension ARPortal.TreasurePlacementView: UICollectionViewDelegate {
    
}
protocol TreasurePlacementViewDataSource {
    func itemsCount(_ treasurePlacementView: ARPortal.TreasurePlacementView) -> Int
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, countForTreasureAt index: Int) -> Int
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, imageFileForTreasureAt index: Int) -> PFFileObject
}
protocol TreasurePlacementViewDelegate {
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didSelectItemAt index: Int) -> Void
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didCancelNodePlacement: Bool) -> Void
    func treasurePlacementView(_ treasurePlacementView: ARPortal.TreasurePlacementView, didConfirmNodePlacement: Bool) -> Void
}
