//
//  SelfProfileViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/16/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class SelfProfileViewController: UIViewController {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var _arPostsView: UIView!
    
    @IBOutlet var _followerView: UIView!
    
    @IBOutlet var _followingView: UIView!
    
    @IBOutlet var _profilePic: UIImageView!
    
    @IBOutlet var _arPostsLabel: UILabel!
    
    @IBOutlet var _followerLabel: UILabel!
    
    @IBOutlet var _followingLabel: UILabel!
    
    @IBOutlet var _usernameLabel: UILabel!
    
    @IBOutlet var _usernameView: UIView!
    
    @IBOutlet var _findFriendsView: UIView!
    
    @IBOutlet var _logoutView: UIView!
    
    @IBOutlet var _editProfile: UIButton!
    
    var followingCount: Int32!

    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.title = "Profile"
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self._arPostsView.layer.cornerRadius = 20
        self._followerView.layer.cornerRadius = 20
        self._followingView.layer.cornerRadius = 20
        self._usernameView.layer.cornerRadius = 20
        self._findFriendsView.layer.cornerRadius = 20
        self._logoutView.layer.cornerRadius = 20
        self.navigationController?.isNavigationBarHidden = true
        
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(findFriendsTapped))
        
        self._findFriendsView.addGestureRecognizer(touchGesture)
        
        let logOutTouchGesture = UITapGestureRecognizer(target: self, action: #selector(logOutTapped))
        
        self._logoutView.addGestureRecognizer(logOutTouchGesture)
        
        let currentUser = PFUser.current()
        if let currentUser = currentUser {
            self._usernameLabel.text = currentUser.username
            let profilePic = currentUser["profilePic"] as? PFFileObject
            if let profilePic = profilePic {
                profilePic.getDataInBackground {
                    (imageData: Data?, error: Error?) -> Void in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else if let imageData = imageData {
                        self._profilePic.image = UIImage(data: imageData)
                        self._profilePic.clipsToBounds = true
                        self._profilePic.layer.cornerRadius = 90
                        self._profilePic.contentMode = .scaleAspectFill
                    }
                }
            } else {
                // attempt to get profile pic from user's facebook profile
                Profile.loadCurrentProfile {
                    (profile, error) in
                    if let profile = profile {
                        let imageURL = profile.imageURL(forMode: Profile.PictureMode.normal, size: CGSize.init(width: 512, height:512))!
                        
                        URLSession.shared.dataTask(with: imageURL) {
                            (data: Data?, urlResponse: URLResponse?, error: Error?) in
                            if let data = data {
                                self._profilePic.image = UIImage(data: data)
                                self._profilePic.clipsToBounds = true
                                self._profilePic.layer.cornerRadius = 90
                                self._profilePic.contentMode = .scaleAspectFill
                            }
                            }.resume()
                    }
                }
            }
            // get the users followers
            let followersRelation = currentUser["Followers"] as! PFRelation
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
            
            // fetch users following
            let followingRelation = currentUser["Following"] as? PFRelation
            if let followingRelation = followingRelation {
                let followingQuery = followingRelation.query()
                followingQuery.countObjectsInBackground {
                    (count: Int32?, error: Error?) -> Void in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else if let count = count {
                        self._followingLabel.text = String(count)
                        self.followingCount = count
                    }
                }
            }
            // get the users arposts
            var arPosts = 0
                    
            let outdoorObjectsQuery = PFQuery(className: "SkySticker")
            outdoorObjectsQuery.whereKey("author", equalTo: currentUser)
            outdoorObjectsQuery.countObjectsInBackground { (outdoorCount: Int32?, error: Error?) -> Void in
                if let outdoorCount = outdoorCount {
                    arPosts += Int(outdoorCount)
                            
                    let textsQuery = PFQuery(className: "text")
                    textsQuery.whereKey("user", equalTo: currentUser)
                    textsQuery.countObjectsInBackground {   (textsCount: Int32?, error: Error?) -> Void in
                        if let textsCount = textsCount {
                            arPosts += Int(textsCount)
                                    
                            let cassettesQuery = PFQuery(className: "Cassette")
                            cassettesQuery.whereKey("addedBy", equalTo: currentUser)
                            cassettesQuery.countObjectsInBackground {   (cassettesCount: Int32?, error: Error?) -> Void in
                                if let cassettesCount = cassettesCount {
                                    arPosts += Int(cassettesCount)
                                            
                                    let tableCassettesQuery = PFQuery(className: "TableCassette")
                                    tableCassettesQuery.whereKey("addedBy", equalTo: currentUser)
                                    tableCassettesQuery.countObjectsInBackground {  (tableCassettesCount: Int32?, error: Error?) -> Void in
                                        if let tableCassettesCount = tableCassettesCount {
                                            arPosts += Int(tableCassettesCount)
                                            self._arPostsLabel.text = String(arPosts)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self._editProfile.transform = CGAffineTransform.identity
        self.navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Action Methods
    
    @IBAction func _editProfile(sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self._editProfile.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi))

        }, completion: {
            (succeed: Bool?) -> Void in
            self.performSegue(withIdentifier: "editProfile", sender: self)
        } )
    }
    
    @objc func findFriendsTapped() {
        self.performSegue(withIdentifier: "findFriends", sender: self)
    }
    
    @objc func logOutTapped() {
        
        let alertMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to logout?", preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertMessage.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: {
            (action: UIAlertAction) -> Void in
            
            let currentUser = PFUser.current()
            PFUser.logOutInBackground {
                (error: Error?) in
                
                if error == nil {
                    
                    // clear the user pointer in current installation
                    let currentInstallation = PFInstallation.current()
                    currentInstallation?.remove(forKey: "user")
                    currentInstallation?.saveInBackground()
                    
                    self.performSegue(withIdentifier: "logOutToLogin", sender: self)
                }
            }
            }))
        
        self.present(alertMessage, animated: true, completion: nil)
        
    }
    
    // MARK: - Helper Methods
    func refreshFollowing() {
        if let currentUser = PFUser.current() {
            
            let followingRelation = currentUser["Following"] as? PFRelation
            if let followingRelation = followingRelation {
                let followingQuery = followingRelation.query()
                followingQuery.countObjectsInBackground {
                    (count: Int32?, error: Error?) -> Void in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else if let count = count {
                        self._followingLabel.text = String(count)
                        self.followingCount = count
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editProfile" {
            let destinationViewController = segue.destination as! EditProfileViewController
            destinationViewController.followingCount = self.followingCount
            destinationViewController.arPosts = self._arPostsLabel.text!
            destinationViewController.followersCount = self._followerLabel.text!
        }
    }
}
