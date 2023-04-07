//
//  ARGiftViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/10/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//
// Users can gift items from their inventory, ar coins and treasures.
// Treasure items are stored in "CollectedTreasure" Table with "Treasure" and "Quantity" Fields. Quantity is NSNumber
// and Treasure is a pointer to "Treasure" table.

import UIKit

class ARGiftViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Interface Outlets
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var username: UILabel!
    
    @IBOutlet var cancelButton: UIButton!
    
    @IBOutlet var giftButton: UIButton!
    
    // MARK: - Properties
    var user: PFUser = { return PFUser.current()! }()
    var targetUser: PFUser? {
        didSet {
            username.text = targetUser?.username
        }
    }
    var numberOfItems: Int = 0
    
    var inventoryItemsRelation: PFRelation<PFObject>?
    
    var treasureItems: [PFObject] = []
    
    var giftingDict: [PFObject: Int] = [:]
    
    var giftingTreasure: [PFObject: Int] = [:]
    
    var arCoinGift: Int?
    
    // MARK: - UI Elemets
    var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - TableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return numberOfItems
        case 1:
            return 1
        case 2:
            return treasureItems.count
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ARGiftTableViewCell
        
        cell.delegate = self
        cell.showActivityIndicator()
        
        let type = GiftType.init(rawValue: indexPath.section)!
        cell.giftType = type
        switch type {
        case .arCoin:
            break
        case .inventory:
            cell.index = indexPath.row
            cell.itemsRelation = inventoryItemsRelation
        case .treasure:
            cell.collectedTreasureObject = treasureItems[indexPath.row]
        }
        cell.loadContent()
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.gray
        view.layer.cornerRadius = 10
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.gray
        tableView.isHidden = true
        tableView.tableFooterView = UIView()
        
        /// Display Activity Indicator while loading Inventory Items
        showInitialActivityIndicator()
        
        /// Load number of inventory items
        numberOfInventoryItems() { _, _ in }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI
    func showInitialActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
        let centerHorizontally = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        
        view.addConstraints([widthConstraint,
                             heightConstraint,
                             centerHorizontally,
                             centerVertically])
        
        activityIndicator.startAnimating()
    }
    
    // MARK: - Interface Builder Action Methods
    
    @IBAction func gift(sender: UIButton) {
        // Process coin gift
        if arCoinGift != nil {
            if arCoinGift! != 0 {
                // Award Coins for target user
                let params = ["to": targetUser!.objectId!,
                              "from": user.objectId!,
                              "amount": String(describing: arCoinGift!)]
                PFCloud.callFunction(inBackground: "giftCoin", withParameters: params)
                
                // if successful subtract coins from user
                let initialAmount = user["ARCoin"] as! Int
                user["ARCoin"] = initialAmount - arCoinGift!
                user.saveInBackground()
            }
        }
        
        for (key, value) in giftingDict.filter({ (_, value) in return value != 0 }) {
            // Extract the model of the key
            let model = key["Model"] as! PFObject
            
            targetUser?.award(model: model, amount: value) {
                (succeed, error) in
                if error == nil {
                    // subtract amount from user inventory item
                    self.user.subtractInventory(item: key, amount: value)
                    
                    // send notification to the user
                    let modelName = model["name"] as! String
                    let params = ["to": self.targetUser?.objectId!,
                                  "from": self.user.objectId!,
                                  "name": modelName,
                                  "amount": String(describing: value)]
                    PFCloud.callFunction(inBackground: "giftInventory", withParameters: params)
                }
            }
        }
        
        for (key, value) in giftingTreasure.filter( { (_, value) in return value != 0 }) {
            key.incrementKey("Quantity", byAmount: NSNumber.init(value: value))
            key.saveInBackground()
            let treasureObject = key["Treasure"] as! PFObject
            let collectedTreasureQuery = PFQuery(className: "CollectedTreasure")
            collectedTreasureQuery.whereKey("User", equalTo: targetUser!)
            collectedTreasureQuery.whereKey("Treasure", equalTo: treasureObject)
            collectedTreasureQuery.findObjectsInBackground { (objects, error) in
                if error == nil {
                    if let object = objects?.first! {
                        // increment object
                        object.incrementKey("Quantity", byAmount: NSNumber(integerLiteral: value))
                        object.saveInBackground()
                    } else {
                        // create a new collected treasure object
                        let collectedTreasureObject = PFObject(className: "CollectedTreasure")
                        collectedTreasureObject["User"] = self.targetUser!
                        collectedTreasureObject["Quantity"] = NSNumber(integerLiteral: value)
                        collectedTreasureObject["Treasure"] = treasureObject
                        collectedTreasureObject.saveInBackground()
                    }
                }
            }
        }
        
        // Remove the gifting form view
        cleanUp()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    @IBAction func cancel(sender: UIButton) {
        cleanUp()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    // MARK: - Loading Inventory
    
    func numberOfInventoryItems(_ completion: @escaping (_ itemsCount: Int?, _ error: Error?) -> Void) {
        let inventoryQuery = PFQuery(className: "Inventory")
        inventoryQuery.whereKey("User", equalTo: user)
        inventoryQuery.getFirstObjectInBackground {
            (object, error) in
            if error == nil {
                let items = object!.relation(forKey: "Items")
                self.inventoryItemsRelation = items
                let itemsQuery = items.query()
                itemsQuery.countObjectsInBackground {
                    (count: Int32?, error: Error?) -> Void in
                    if error == nil {
                        self.numberOfItems = Int(count!)
                        self.loadTreasureItems { (objects, error) in
                            if error == nil {
                                self.treasureItems = objects!
                                self.activityIndicator.stopAnimating()
                                self.tableView.isHidden = false
                                self.tableView.reloadData()
                                completion(Int(count!), nil)
                            } else {
                                print(error)
                                completion(nil, error)
                            }
                        }
                    } else {
                        completion(nil, error!)
                    }
                }
            }
        }
    }
    
    func loadTreasureItems(_ completion: @escaping (_ items: [PFObject]?, _ error: Error?) -> Void) {
        let collectedTreasureQuery = PFQuery(className: "CollectedTreasure")
        collectedTreasureQuery.whereKey("User", equalTo: user)
        collectedTreasureQuery.findObjectsInBackground { (objects, error) in
            if error == nil {
                completion(objects, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func cleanUp() {
        targetUser = nil
        inventoryItemsRelation = nil
        giftingDict.removeAll()
        arCoinGift = nil
    }
}

extension ARGiftViewController: ARGiftTableViewCellDelegate {
    func arGiftTableViewCell(_ cell: ARGiftTableViewCell, didChangeGiftingAmount amount: Int) {
        
        switch cell.giftType! {
        case .arCoin:
            
            arCoinGift = amount
        case .inventory:
            
            // Extract the item
            let item = cell.inventoryItem
            
            let giftingItems = giftingDict.keys
            
            // Check if This Item is Already in the gifting items array
            if let existingItem = giftingItems.first(where: { $0.objectId! == item!.objectId! }) {
                // Change the amount for this item
                giftingDict[existingItem] = amount
            } else {
                // Add gifting amount for this item
                giftingDict[item!] = amount
            }
        case .treasure:
            let item = cell.collectedTreasureObject
            
            let giftingItems = giftingTreasure.keys
            
            // Check if This Item is Already in the gifting items array
            if let existingItem = giftingItems.first(where: { $0.objectId! == item!.objectId! }) {
                // Change the amount for this item
                giftingDict[existingItem] = amount
            } else {
                // Add gifting amount for this item
                giftingDict[item!] = amount
            }
        default:
            break
        }
    }
}
enum GiftType: Int {
    case inventory = 0
    case arCoin = 1
    case treasure = 2
}
