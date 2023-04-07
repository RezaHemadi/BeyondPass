//
//  ChestViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/19/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class ChestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var closeButton: UIButton!
    
    // MARK: - Properties
    
    var user: PFUser = { return PFUser.current()! }()
    
    var numberOfItems: Int = 0
    var inventoryItemsRelation: PFRelation<PFObject>?
    // MARK: - UI Elements
    var activityIndicator: UIActivityIndicatorView!

    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.gray
        view.layer.cornerRadius = view.frame.width / 12
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.gray
        tableView.isHidden = true
        tableView.tableFooterView = UIView()
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = view.frame.width / 12
        
        closeButton.layer.cornerRadius = closeButton.frame.width / 12
        
        /// Display Activity Indicator while loading Inventory Items
        showInitialActivityIndicator()
        
        /// Load number of inventory items
        numberOfInventoryItems {
            (itemsCount, error) in
            if error == nil {
                self.numberOfItems = itemsCount!
                self.tableView.isHidden = false
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
                
                /// Load Inventory Items
                
            }
        }
        
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
                        completion(Int(count!), nil)
                    } else {
                        completion(nil, error!)
                    }
                }
            }
        }
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ChestTableViewCell
        
        cell.index = indexPath.row
        
        if cell.isContentLoaded {
            return cell
        }
        cell.showActivityIndicator()
        cell.itemsRelation = inventoryItemsRelation
        cell.loadContent()
        
        return cell
    }
    
    @IBAction func close(sender: UIButton) {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
