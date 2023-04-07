//
//  AddFriendsViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/6/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class AddFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    var searchController = UISearchController()
    var searchUsers: [PFUser] = [PFUser]()
    var searchActive: Bool! = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //set background image
        let background = UIImage(named: "introBackground")
        let backgroundView = UIImageView.init(image: background)
        backgroundView.bounds = self.tableView.bounds
        self.tableView.backgroundView = backgroundView
        
        
        self.tableView.allowsSelection = true
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.placeholder = "Search for a User"
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.delegate = self
        self.searchController.delegate = self
        self.definesPresentationContext = true
        self.tableView.tableHeaderView = self.searchController.searchBar
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadSearchUsers(searchString: String) {
        let query = PFUser.query()
        
        // filter by search string
        query?.whereKey("username", contains: searchString)
        
        self.searchActive = true
        query?.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if (error == nil) {
                self.searchUsers.removeAll(keepingCapacity: false)
                self.searchUsers += objects as! [PFUser]

            } else {
                self.searchActive = false
            }
            self.searchUsers = self.searchUsers.filter {
                (user) -> Bool in
                user.fetchIfNeededInBackground()
                if user.username == PFUser.current()?.username {
                    return false
                } else {
                    return true
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // force search if user clicks button
        let searchString: String = searchBar.text!.lowercased()
        if (searchString != "") {
            loadSearchUsers(searchString: searchString)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        // clear any search criteria
        searchBar.text = ""
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchString: String = searchController.searchBar.text!.lowercased()
        if (searchString != "" && !self.searchActive) {
            loadSearchUsers(searchString: searchString)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FindFriendsToUsersProfile" {
            let targetUser = sender as! PFUser
            
            let usersProfileViewController = segue.destination as! UsersProfileViewController
            usersProfileViewController.targetUser = targetUser
            
            let mainViewController = navigationController?.viewControllers[0] as! MainViewController
            usersProfileViewController.delegate = mainViewController
        }
    }
    
    // MARK: - TableView Delegate and Data Source
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = searchUsers[indexPath.row]
        
        performSegue(withIdentifier: "FindFriendsToUsersProfile", sender: user)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive {
            return self.searchUsers.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! SearchUserTableViewCell
        
        cell.backgroundColor = UIColor.clear

        
        if (self.searchController.isActive && self.searchUsers.count > indexPath.row) {
            let user = self.searchUsers[indexPath.row]
            let username = user.username
            let targetUserLocation = user["location"] as? PFGeoPoint
            cell._username.text = username
            cell.user = user
            
            let image = user["profilePic"] as? PFFileObject
            if let userImage = image {
                userImage.getDataInBackground {
                    (data: Data?, error: Error?) -> Void in
                    if (error == nil) {
                        cell._profilePic.image = UIImage(data: data!)
                        cell._profilePic.layer.cornerRadius = 30
                        cell._profilePic.clipsToBounds = true
                        cell._profilePic.contentMode = .scaleAspectFill
                    }
                }
            } else {
                cell._profilePic.image = nil
            }
            
            let query = PFQuery(className: "FollowRequest")
            query.whereKey("status", equalTo: "pending")
            query.whereKey("from", equalTo: PFUser.current()!)
            query.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                if let objects = objects {
                    for object in objects {
                        let sent = object["to"] as! PFUser
                        sent.fetchIfNeededInBackground {
                            (object: PFObject?, error: Error?) -> Void in
                            if let object = object {
                                let fetchedUser = object as! PFUser
                                if fetchedUser.username == user.username {
                                    cell._follow.setTitle("Requested", for: .normal)
                                    cell._follow.isEnabled = false
                                }
                            }
                        }
                    }
                }
                let relation = PFUser.current()?.relation(forKey: "Following")
                let query = relation!.query()
                query.findObjectsInBackground {
                    (objects: [PFObject]?, error: Error?) -> Void in
                    if let objects = objects {
                        for object in objects {
                            object.fetchInBackground {
                                (fetchedUser: PFObject?, error: Error?) -> Void in
                                if let fetchedUser = fetchedUser {
                                    if (username == fetchedUser["username"] as? String) {
                                        cell._follow.setTitle("Following", for: .normal)
                                        cell._follow.isEnabled = false
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            let currentUser = PFUser.current()!
            currentUser.fetchInBackground {
                (user: PFObject?, error: Error?) -> Void in
                if let user = user {
                    if let currentLocation = user["location"] as? PFGeoPoint {
                        if let targetUserLocation = targetUserLocation {
                            let distance = currentLocation.distanceInKilometers(to: targetUserLocation)
                            let distanceString = String(format: "%.2f km", distance)
                            cell._distance.text = distanceString
                            
                        }
                    }
                }
            }
        }
        
        return cell
    }
}
