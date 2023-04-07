//
//  PortalDecorationsView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/5/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import StoreKit

class PortalDecorationsView: UIView {
    
    // MARK: - Types
    
    enum Decoration {
        case model
        case wallpaper
    }
    
    enum Section: Int {
        case availableForPurchase
        case purchasedModel
        case purchasedWallpaper
        
        static var all: [Section] = [.availableForPurchase, .purchasedModel, .purchasedWallpaper]
    }
    
    // MARK: - Properties
    
    var modelsToShow: [PFObject] = [] // Models To Show in the collection view that can be put in the portal
    
    var wallpapersToShow: [PFObject] = []
    
    var currentUser = PFUser.current()!
    
    var availableForPurchaseCount: Int = 0
    
    var purchasedModelCount: Int = 0
    
    var purchasedWallpaperCount: Int = 0
    
    var delegate: PortalDecorationViewDelegate?
    
    var request: SKProductsRequest?
    
    var products: [SKProduct] = []
    
    var collectionView: UICollectionView!
    
    var currentlySelectedModel: PFObject?
    
    var currentlySelectedIndexPath: IndexPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(red: 158/255.0, green: 162/255.0, blue: 168/255.0, alpha: 0.6)
        clipsToBounds = true
        
        /// Attempt to load items
        loadItems()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: bounds.height * 0.65, height: bounds.height)
        
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PortalDecorationCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(AvailableForPurchaseCollectionViewCell.self, forCellWithReuseIdentifier: "availableForPurchase")
        collectionView.register(PortalWallpaperCollectionViewCell.self, forCellWithReuseIdentifier: "wallpaper")
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        collectionView.addGestureRecognizer(tapGestureRecognizer)
        
        addSubview(collectionView)
    }
    @objc func tap(recognizer: UITapGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: recognizer.location(in: collectionView)) {
            let localSection = Section.init(rawValue:indexPath.section)!
            
            switch localSection {
            case .availableForPurchase:
                let cell = collectionView.cellForItem(at: indexPath) as! AvailableForPurchaseCollectionViewCell
                if cell.isSelectable {
                    /// Create a payment request for the selected product
                    if let product = cell.product {
                        cell.isSelectable = false
                        requestPayment(product: product)
                        cell.isSelectable = false
                    }
                }
                
            case .purchasedModel:
                let cell = collectionView.cellForItem(at: indexPath) as! PortalDecorationCollectionViewCell
                
                if cell.isSelectable {
                    cell.toggleSelection()
                    if cell.isSelected {
                        delegate?.portalDecorationView(self, didSelectModel: cell.decorationModelObject!)
                        currentlySelectedModel = cell.decorationModelObject
                        currentlySelectedIndexPath = indexPath
                    } else {
                        delegate?.portalDecorationView(self, didDeselectModel: cell.decorationModelObject!)
                    }
                }
                
            case .purchasedWallpaper:
                let cell = collectionView.cellForItem(at: indexPath) as! PortalWallpaperCollectionViewCell
                
                if cell.isSelectable {
                    cell.isSelectable = false
                    cell.isSelected = true
                    delegate?.portalDecorationView(self, didSelectWallpaper: cell.decorationWallpaperObject!)
                    currentlySelectedIndexPath = indexPath
                }
            }
        }
    }
    
    func loadItems() {
        
        /// Load items that are available for purchase
        let query = PFQuery(className: "PortalDecorationModel")
        query.findObjectsInBackground {
            (objects, error) in
            if error == nil {
                
                var productIDs: [String] = []
                
                for object in objects! {
                    if let id = object["ProductID"] as? String {
                        productIDs.append(id)
                    }
                }
                
                let portalWallpaperQuery = PFQuery(className: "PortalDecorationWallpaper")
                portalWallpaperQuery.findObjectsInBackground{ (objects: [PFObject]?, error: Error?) -> Void in
                    if error == nil {
                        for object in objects! {
                            if let id = object["ProductID"] as? String {
                                productIDs.append(id)
                            }
                        }
                        
                        /// Load Models the user have purchased
                        let purchasedPortalModels = PFQuery(className: "PurchasedPortalModels")
                        purchasedPortalModels.whereKey("User", equalTo: self.currentUser)
                        purchasedPortalModels.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                            if error == nil {
                                if let purchasedModels = objects {
                                    /// Exclude the purchased models from request query
                                    let purchasedModelsIDs = purchasedModels.map { $0["ProductID"] as! String }
                                    productIDs = productIDs.filter{ (id) -> Bool in
                                        for purchasedID in purchasedModelsIDs {
                                            if purchasedID == id {
                                                return false
                                            }
                                        }
                                        return true
                                    }
                                    
                                    /// Exclude Purchased Wallpapers form the request query
                                    let purchasedWallpapersQuery = PFQuery(className: "PurchasedPortalWallpapers")
                                    purchasedWallpapersQuery.whereKey("User", equalTo: self.currentUser)
                                    purchasedWallpapersQuery.findObjectsInBackground {(objects: [PFObject]?, error: Error?) -> Void in
                                        if error == nil {
                                            if let purchasedWallpapers = objects {
                                                self.wallpapersToShow = purchasedWallpapers
                                                self.purchasedWallpaperCount = purchasedWallpapers.count
                                                
                                                let purchasedWallpapersIDs = purchasedWallpapers.map { $0["ProductID"] as! String }
                                                
                                                productIDs = productIDs.filter({ (id) -> Bool in
                                                    for purchasedID in purchasedWallpapersIDs {
                                                        if purchasedID == id {
                                                            return false
                                                        }
                                                    }
                                                    return true
                                                })
                                            }
                                            
                                            /// Check if the purchased model is already inside the user portal
                                            /// if not show it in the collection view
                                            let userPortalQuery = PFQuery(className: "UserPortals")
                                            userPortalQuery.whereKey("User", equalTo: self.currentUser)
                                            userPortalQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
                                                if error == nil {
                                                    if let userPortal = objects?.first {
                                                        let modelItems = userPortal.relation(forKey: "ModelItems")
                                                        let modelItemsQuery = modelItems.query()
                                                        modelItemsQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                                                            if error == nil {
                                                                if let portalModelItems = objects {
                                                                    let decorativeModels = portalModelItems.map { $0["DecorationModel"] as! PFObject }
                                                                    decorativeModels.forEach { try! $0.fetchIfNeeded() }
                                                                    let insideModelIDs = decorativeModels.map { $0["ProductID"] as! String }
                                                                    
                                                                    let modelsToShow = purchasedModelsIDs.filter{ (id) -> Bool in
                                                                        for insideModelID in insideModelIDs {
                                                                            if insideModelID == id {
                                                                                return false
                                                                            }
                                                                        }
                                                                        return true
                                                                    }
                                                                    
                                                                    self.purchasedModelCount = modelsToShow.count
                                                                    self.modelsToShow = purchasedModels.filter({ (object) -> Bool in
                                                                        let productID = object["ProductID"] as! String
                                                                        if modelsToShow.contains(productID) {
                                                                            return true
                                                                        }
                                                                        return false
                                                                    })
                                                                    
                                                                    self.collectionView.reloadData()
                                                                }
                                                            } else {
                                                                print("\(error)")
                                                            }
                                                        }
                                                    } else {
                                                        /// User has no purchased models in the portal
                                                        self.modelsToShow = purchasedModels
                                                        self.purchasedModelCount = purchasedModels.count
                                                        self.collectionView.reloadData()
                                                    }
                                                } else {
                                                    print("\(error)")
                                                }
                                            }
                                            
                                        } else {
                                            print("\(error)")
                                        }
                                        
                                        // Perform the products request
                                        let productIdentifiers = Set.init(productIDs)
                                        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
                                        self.request = request
                                        request.delegate = self
                                        request.start()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func displayStoreUI() {
        availableForPurchaseCount = products.count
        collectionView.reloadData()
    }
    
    // MARK: - Helper Methods
    
    func deSelectCurrentModel() {
        guard currentlySelectedModel != nil, currentlySelectedIndexPath != nil else { return }
        
        if let cell = collectionView.cellForItem(at: currentlySelectedIndexPath!) as? PortalDecorationCollectionViewCell {
            cell.toggleSelection()
            currentlySelectedIndexPath = nil
            delegate?.portalDecorationView(self, didDeselectModel: currentlySelectedModel!)
            currentlySelectedModel = nil
        }
    }
    
    func requestPayment(product: SKProduct) {
        let paymentRequest = SKMutablePayment(product: product)
        
        SKPaymentQueue.default().add(paymentRequest)
    }
}
extension PortalDecorationsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case Section.availableForPurchase.rawValue:
            return availableForPurchaseCount
            
        case Section.purchasedModel.rawValue:
            return purchasedModelCount
            
        case Section.purchasedWallpaper.rawValue:
            return purchasedWallpaperCount
            
        default:
            return 1
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        let localSection = Section.init(rawValue: section)!
        
        switch localSection {
        case .availableForPurchase:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "availableForPurchase", for: indexPath) as! AvailableForPurchaseCollectionViewCell
            
            
            cell.product = products[indexPath.row]
            cell.loadData()
            
            
            return cell
            
        case .purchasedModel:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PortalDecorationCollectionViewCell
            
            
            cell.decorationModelObject = modelsToShow[indexPath.row]
            cell.loadData()
            
            
            return cell
        case .purchasedWallpaper:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "wallpaper", for: indexPath) as! PortalWallpaperCollectionViewCell
            
            
            cell.decorationWallpaperObject = wallpapersToShow[indexPath.row]
            cell.loadContent()
            
            
            return cell
        }
    }
}
extension PortalDecorationsView: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.all.count
    }
}
extension PortalDecorationsView: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid Identifier: \(invalidIdentifier)")
        }
        
        // Display Store UI
        displayStoreUI()
    }
}
extension PortalDecorationsView: PortalStoreDelegate {
    func store(_ store: Store, makeModelAvailable model: PFObject) {
        modelsToShow.removeAll()
        wallpapersToShow.removeAll()
        availableForPurchaseCount = 0
        purchasedModelCount = 0
        purchasedWallpaperCount = 0
        collectionView.reloadData()
        loadItems()
    }
    
    func store(_ store: Store, makeWallpaperAvailable wallpaper: PFObject) {
        modelsToShow.removeAll()
        wallpapersToShow.removeAll()
        availableForPurchaseCount = 0
        purchasedModelCount = 0
        purchasedWallpaperCount = 0
        collectionView.reloadData()
        loadItems()
    }
    
    
}
protocol PortalDecorationViewDelegate {
    func portalDecorationView(_ view: PortalDecorationsView, didSelect poduct: SKProduct)
    func portalDecorationView(_ view: PortalDecorationsView, didSelectModel model: PFObject)
    func portalDecorationView(_ view: PortalDecorationsView, didDeselectModel model: PFObject)
    func portalDecorationView(_ view: PortalDecorationsView, didSelectWallpaper wallpaper: PFObject)
}
