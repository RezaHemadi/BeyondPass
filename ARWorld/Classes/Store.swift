//
//  Store.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/25/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Store: NSObject, SKPaymentTransactionObserver {
    
    // MARK: - Types
    enum ProductType: String {
        case portalDecoration = "PortalDecoration"
        case portalWallpaper = "PortalWallpaper"
        case arcoin = "ARCoin"
    }
    
    // MARK: - Properties
    
    var delegate: StoreDelegate?
    
    var portalStoreDelegate: PortalStoreDelegate?
    
    // MARK: SKPaymentTransactionObserver
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                showTransactionAsInProgress(transaction, deffered: false)
                
            case .deferred:
                showTransactionAsInProgress(transaction, deffered: true)
                
            case .failed:
                failedTransaction(transaction)
                
            case .restored:
                restoreTransaction(transaction)
                
            case .purchased:
                completeTransaction(transaction)
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
    }
    
    // MARK: - Helper Methods
    
    private func showTransactionAsInProgress(_ transaction: SKPaymentTransaction, deffered: Bool) {
        delegate?.store(self, purchasingTransaction: transaction)
    }
    
    private func failedTransaction(_ transaction: SKPaymentTransaction) {
        delegate?.store(self, failedTransaction: transaction)
    }
    
    private func restoreTransaction(_ transaction: SKPaymentTransaction) {
        
    }
    
    private func completeTransaction(_ transaction: SKPaymentTransaction) {
        /// Determine the type of the purchased product
        let productIdentifier = transaction.payment.productIdentifier
        
        let productQuery = PFQuery(className: "Products")
        productQuery.whereKey("ProductIdentifier", equalTo: productIdentifier)
        productQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let product = objects?.first {
                    let productTypeLiteral = product["Type"] as! String
                    let productType = ProductType.init(rawValue: productTypeLiteral)!
                    
                    /// Make a persistent record in the servers of this purchase
                    if let currentUser = PFUser.current() {
                        switch productType {
                        case .portalDecoration:
                            /// Query to find the corrensponding decoration model
                            let portalDecorationModelQuery = PFQuery(className: "PortalDecorationModel")
                            portalDecorationModelQuery.whereKey("ProductID", equalTo: productIdentifier)
                            portalDecorationModelQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error?) -> Void in
                                if error == nil {
                                    if let portalDecorationModel = objects?.first {
                                        let purchasedPortalModel = PFObject(className: "PurchasedPortalModels")
                                        purchasedPortalModel["User"] = currentUser
                                        purchasedPortalModel["DecorationModel"] = portalDecorationModel
                                        purchasedPortalModel["ProductID"] = productIdentifier
                                        
                                        purchasedPortalModel.saveInBackground { (succeed: Bool?, error: Error?) in
                                            if succeed == true {
                                                // Tell the delegate that the item is available for use
                                                self.delegate?.store(self, purchasedTransaction: transaction)
                                                self.portalStoreDelegate?.store(self, makeModelAvailable: purchasedPortalModel)
                                                SKPaymentQueue.default().finishTransaction(transaction)
                                            }
                                        }
                                    }
                                }
                            }
                        case .portalWallpaper:
                            /// Add the purchased Portal wallpaper to the "PurchasedPortalWallpapers" table
                            /// Find the portalWallpaper object in the "PortalDecorationWallpaper" class
                            let portalDecorationWallpaperQuery = PFQuery(className: "PortalDecorationWallpaper")
                            portalDecorationWallpaperQuery.whereKey("ProductID", equalTo: productIdentifier)
                            portalDecorationWallpaperQuery.findObjectsInBackground { (objects: [PFObject]?, error: Error? ) -> Void in
                                if error == nil {
                                    if let portalDecorationWallpaper = objects?.first {
                                        /// Create a record in "PurchasedPortalWallpapers" class for the user
                                        let purchasedPortalWallpaper = PFObject(className: "PurchasedPortalWallpapers")
                                        purchasedPortalWallpaper["DecorationWallpaper"] = portalDecorationWallpaper
                                        purchasedPortalWallpaper["User"] = currentUser
                                        purchasedPortalWallpaper["ProductID"] = productIdentifier
                                        
                                        purchasedPortalWallpaper.saveInBackground { (succeed: Bool?, error: Error?) -> Void in
                                            if error == nil {
                                                if succeed == true {
                                                    // Tell the delegate that the item is available for use
                                                    self.delegate?.store(self, purchasedTransaction: transaction)
                                                    self.portalStoreDelegate?.store(self, makeWallpaperAvailable: purchasedPortalWallpaper)
                                                    SKPaymentQueue.default().finishTransaction(transaction)
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        case .arcoin:
                            // Add 100 AR Coins to the user's wallet
                            if let currentUser = PFUser.current() {
                                currentUser.incrementKey("ARCoin", byAmount: NSNumber.init(value: 100))
                                currentUser.saveInBackground(block: { (succeed, error) in
                                    self.delegate?.store(self, purchasedTransaction: transaction)
                                    SKPaymentQueue.default().finishTransaction(transaction)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func removeTransaction(_ transaction: SKPaymentTransaction) {
        
    }
}
extension Store {
    static private var singleton: Store = Store()
    
    static func sharedInstance() -> Store {
        return self.singleton
    }
}

protocol StoreDelegate {
    func store(_ store: Store, purchasingTransaction: SKPaymentTransaction)
    func store(_ store: Store, deferredTransaction: SKPaymentTransaction)
    func store(_ store: Store, failedTransaction: SKPaymentTransaction)
    func store(_ store: Store, purchasedTransaction: SKPaymentTransaction)
}
protocol PortalStoreDelegate {
    func store(_ store: Store, makeModelAvailable model: PFObject)
    func store(_ store: Store, makeWallpaperAvailable wallpaper: PFObject)
}
