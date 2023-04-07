//
//  UsersProfileViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/17/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class UsersProfileViewController: UIViewController {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var _profilePic: UIImageView!
    @IBOutlet var _arPostsView: UIView!
    @IBOutlet var _arPostsLabel: UILabel!
    @IBOutlet var _followingView: UIView!
    @IBOutlet var _followingLabel: UILabel!
    @IBOutlet var _followerView: UIView!
    @IBOutlet var _followerLabel: UILabel!
    @IBOutlet var _distanceView: UIView!
    @IBOutlet var _distanceLabel: UILabel!
    @IBOutlet var _followButton: UIButton!
    @IBOutlet var _usernameView: UIView!
    @IBOutlet var _usernameLabel: UILabel!
    @IBOutlet var _visitPortal: UIButton!
    
    // MARK: - Properties
    
    var status: FollowStatus!
    
    var targetUser: PFObject!
    
    var delegate: UsersProfileDelegate?
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Profile"
        
        self._arPostsView.layer.cornerRadius = 20
        self._followingView.layer.cornerRadius = 20
        self._followerView.layer.cornerRadius = 20
        self._distanceView.layer.cornerRadius = 20
        self._usernameView.layer.cornerRadius = 20
        self._followButton.layer.cornerRadius = 20
        self._visitPortal.layer.cornerRadius = 20
        
        PFUser.current()!.followStatus(to: targetUser as! PFUser) {
            (status: FollowStatus?, error: Error?) -> Void in
            if let status = status {
                switch status {
                case .following:
                    self._followButton.setTitle("Following", for: .normal)
                    self.status = status
                case .notFollowing:
                    self._followButton.setTitle("Follow", for: .normal)
                    self.status = status
                case .requested:
                    self._followButton.setTitle("Requested", for: .normal)
                    self.status = status
                case .currentUser:
                    self._followButton.isEnabled = false
                    self.status = status
                }
            }
        }
        
        if let targetUser = self.targetUser {
            // get the users arposts
            var arPosts = 0
                    
            let outdoorObjectsQuery = PFQuery(className: "SkySticker")
            outdoorObjectsQuery.whereKey("author", equalTo: targetUser)
            outdoorObjectsQuery.countObjectsInBackground {  (outdoorCount: Int32?, error: Error?) -> Void in
                if let outdoorCount = outdoorCount {
                    arPosts += Int(outdoorCount)
                            
                    let textsQuery = PFQuery(className: "text")
                    textsQuery.whereKey("user", equalTo: targetUser)
                    textsQuery.countObjectsInBackground {   (textsCount: Int32?, error: Error?) -> Void in
                        if let textsCount = textsCount {
                            arPosts += Int(textsCount)
                                    
                            let cassettesQuery = PFQuery(className: "Cassette")
                            cassettesQuery.whereKey("author", equalTo: targetUser)
                            cassettesQuery.countObjectsInBackground {   (cassettesCount: Int32?, error: Error?) -> Void in
                                if let cassettesCount = cassettesCount {
                                    arPosts += Int(cassettesCount)
                                    self._arPostsLabel.text = String(arPosts)
                                }
                            }
                        }
                    }
                }
            }
            
            // count the target user's followers
            let followersRelation = targetUser.relation(forKey: "Followers")
            let followersQuery = followersRelation.query()
            followersQuery.countObjectsInBackground {
                (followersCount: Int32?, error: Error?) -> Void in
                
                if let followersCount = followersCount {
                    
                    self._followerLabel.text = String(followersCount)
                } else if let error = error {
                    
                    let alertMessage = UIAlertController(title: "server error", message: error.localizedDescription, preferredStyle: .alert)
                    alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.present(alertMessage, animated: true, completion: nil)
                }
            }
            
            targetUser.fetchInBackground {
                (target: PFObject?, error: Error?) -> Void in
                if let _ = error {
                    let alertController = UIAlertController(title:"Network Error",
                                                            message: "Could Not Connect to server",
                                                            preferredStyle: UIAlertController.Style.alert)
                    alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                            handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                } else if let target = target as? PFUser {
                    let profileImage = target["profilePic"] as? PFFileObject
                    if let profileImage = profileImage {
                        profileImage.getDataInBackground {
                            (imageData: Data?, error: Error?) -> Void in
                            if let imageData = imageData {
                                self._profilePic.image = UIImage(data: imageData)
                                self._profilePic.layer.cornerRadius = 90
                                self._profilePic.contentMode = .scaleAspectFill
                                self._profilePic.clipsToBounds = true
                            }
                        }
                    }
                    self._usernameLabel.text = target.username
                    let followingRelation = target["Following"] as? PFRelation
                    if let followingRelation = followingRelation {
                        let followingQuery = followingRelation.query()
                        followingQuery.countObjectsInBackground {
                            (followingCount: Int32?, error: Error?) -> Void in
                            if let followingCount = followingCount {
                                self._followingLabel.text = String(followingCount)
                            }
                        }
                    }
                    let currentUser = PFUser.current()
                    if let currentUser = currentUser {
                        let currentLocation = currentUser["location"] as? PFGeoPoint
                        let targetLocation = target["location"] as? PFGeoPoint
                        if let targetLocation = targetLocation, let currentLocation = currentLocation {
                            let distance = targetLocation.distanceInKilometers(to: currentLocation)
                            self._distanceLabel.text = String(format: "Distance: %.2f Km", distance)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Actions
    
    @IBAction func followButton(sender: UIButton) {
        if let targetUser = self.targetUser, let currentUser = PFUser.current(), let status = self.status {
            if status == FollowStatus.notFollowing {
                sendFollowRequest(from: currentUser, to: targetUser) {
                    (followStatus: FollowStatus?, error: Error?) -> Void in
                    if let followStatus = followStatus {
                        switch followStatus {
                        case .following:
                            self._followButton.setTitle("Following", for: .normal)
                        case .requested:
                            self._followButton.setTitle("Requested", for: .normal)
                        case .notFollowing:
                            self._followButton.setTitle("Follow", for: .normal)
                        case .currentUser:
                            return
                        }
                    }
                }
            } else if status == FollowStatus.requested {
                // cancel friend request
                
            } else if status == FollowStatus.following {
                // unfollow the user
                
            }
        }
    }
    
    @IBAction func visitPortal(sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.isEnabled = false
        
        /// Show Activivty indicator until portal is ready
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.frame = sender.frame
        sender.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        /// Create an instance of portal
        
        let portal = ARPortal(user: self.targetUser as! PFUser)
        portal.visiting = true
        activityIndicator.stopAnimating()
            
        self.delegate?.visitPortal(portal: portal)
        self.navigationController?.popToRootViewController(animated: true)
    }
}
protocol UsersProfileDelegate {
    func visitPortal(portal: ARPortal)
}
