//
//  MainStoreViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 8/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class MainStoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKProductsRequestDelegate, StoreDelegate {
    
    // MARK: Interface Outlets
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var closeButton: UIButton!
    
    @IBOutlet var titleLabel: UILabel!
    
    // MARK: - Properties
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    
    var productObjects: [PFObject] = []
    
    var products: [SKProduct] = []
    
    var productImages: [String: PFFileObject] = [:]
    
    var purchasedItems: [String] = []
    
    var delegate: MainStoreViewControllerDelegate?
    
    var currentUser: PFUser = {
        return PFUser.current()!
    }()
    
    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Store.sharedInstance().delegate = self
        view.backgroundColor = UIColor.gray
        view.layer.cornerRadius = 10
        
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        let centerHorizontally = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraints([centerVertically, centerHorizontally])
        activityIndicator.startAnimating()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.gray
        tableView.tableFooterView = UIView()
        
        loadPurchasedItems() { (succeed, error) in
            if error == nil {
                self.loadProducts()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Fetching Products
    func loadProducts() {
        let productsQuery = PFQuery(className: "Products")
        productsQuery.findObjectsInBackground() { (objects, error) in
            if error == nil {
                if let productObjects = objects {
                    // Process the objects
                    var productIDs: [String] = []
                    productObjects.forEach({ productIDs.append($0["ProductIdentifier"] as! String); self.productObjects.append($0) })
                    let producsIDsSet: Set<String> =  Set.init(productIDs)
                    let productRequest = SKProductsRequest(productIdentifiers: producsIDsSet)
                    productRequest.delegate = self
                    productRequest.start()
                }
            } else {
                // Dispay error message to user
                
            }
        }
    }
    
    func loadPurchasedItems(_ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> Void = { _, _ in }) {
        let purchasedPortalModelQuery = PFQuery(className: "PurchasedPortalModels")
        purchasedPortalModelQuery.whereKey("User", equalTo: currentUser)
        let purchasedPortalWallpaperQuery = PFQuery(className: "PurchasedPortalWallpapers")
        purchasedPortalWallpaperQuery.whereKey("User", equalTo: currentUser)
        purchasedPortalModelQuery.findObjectsInBackground() { objects, error in
            if error == nil {
                if let purchasedModels = objects {
                    purchasedModels.forEach( {self.purchasedItems.append($0["ProductID"] as! String)} )
                    
                    purchasedPortalWallpaperQuery.findObjectsInBackground() { objects, error in
                        if error == nil {
                            if let purchasedWallpapers = objects {
                                purchasedWallpapers.forEach( {self.purchasedItems.append($0["ProductID"] as! String)} )
                                completion(true, nil)
                            }
                        } else {
                            completion(nil, error)
                        }
                    }
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - SKProductRequest Delegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        
        // Display Store UI
        displayStoreUI()
        
        // Reload Table view
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        tableView.reloadData()
    }
    
    // MARK: - Show Store UI
    func displayStoreUI() {
        for product in products {
            let id = product.productIdentifier
            let productObject = productObjects.first(where: { ($0["ProductIdentifier"] as! String) == id })!
            productImages[id] = productObject["Image"] as? PFFileObject
        }
    }
    
    func priceTag(_ product: SKProduct) -> String {
        let numberFormatter = NumberFormatter.init()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        var formattedPrice: String
        numberFormatter.locale = product.priceLocale
        formattedPrice = numberFormatter.string(from: product.price)!
        return formattedPrice
    }
    
    // MARK: - Interface Builder Action Methods
    
    @IBAction func close(sender: UIButton) {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    // MARK: - UITableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainStoreTableViewCell
        let product = products[indexPath.row]
        cell.product = product
        cell.productDescription = product.localizedDescription
        cell.imageFile = productImages[product.productIdentifier]
        if purchasedItems.contains(product.productIdentifier) {
            cell.state = "Purchased"
            cell.purchaseButton.isEnabled = false
        } else {
            cell.state = "Purchase"
            cell.price = priceTag(product)
        }
        cell.loadContent()
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - Store Delegate
    func store(_ store: Store, failedTransaction: SKPaymentTransaction) {
        
    }
    func store(_ store: Store, deferredTransaction: SKPaymentTransaction) {
        
    }
    func store(_ store: Store, purchasedTransaction: SKPaymentTransaction) {
        let productID = purchasedTransaction.payment.productIdentifier
        let product = products.first(where: {$0.productIdentifier == productID} )!
        if let index = products.firstIndex(of: product) {
            let indexPath = IndexPath(item: index, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as! MainStoreTableViewCell
            cell.purchaseButton.setTitle("Purchased", for: .normal)
            cell.purchaseButton.isEnabled = false
            delegate?.mainStoreViewController(self, refreshARCoin: true)
        }
    }
    func store(_ store: Store, purchasingTransaction: SKPaymentTransaction) {
        
    }
}

protocol MainStoreViewControllerDelegate {
    func mainStoreViewController(_ mainStoreViewController: MainStoreViewController, refreshARCoin: Bool) -> Void
}
