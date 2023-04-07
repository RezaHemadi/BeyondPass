//
//  TreasureViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class TreasureViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var closeButton: UIButton!
    
    // MARK: - Properties
    
    private var user: PFUser = { return PFUser.current()! }()
    
    private var numberOfItems: Int = 0
    
    private var collectedTreasureObjects: [PFObject] = []
    
    // MARK: - UI Elements
    
    var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        tableView.backgroundColor = UIColor.clear
        view.layer.cornerRadius = view.frame.width / 12
        
        tableView.tableFooterView = UIView()
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = view.frame.width / 12
        
        closeButton.layer.cornerRadius = closeButton.frame.width / 12
        
        loadCollectedTreasureObjects() { (object, error) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    // MARK: - Database
    
    private func loadCollectedTreasureObjects(_ completion: @escaping (_ objects: [PFObject]?, _ error: Error?) -> Void) {
        let query = PFQuery(className: "CollectedTreasure")
        query.whereKey("User", equalTo: user)
        query.findObjectsInBackground { (objects, error) in
            if error == nil {
                self.numberOfItems = objects!.count
                self.collectedTreasureObjects = objects!
                self.tableView.reloadData()
                completion(objects!, nil)
            } else {
                completion(nil, error!)
            }
        }
    }
    
    
    
    // MARK: - TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TreasureTableViewCell
        cell.treasureObject = collectedTreasureObjects[indexPath.row]
        cell.loadTreasure()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
