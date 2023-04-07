//
//  NotificationsViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/10/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var notification: Notification!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let background = UIImage(named: "NotificationsBackground")
        let backgroundView = UIImageView.init(image: background)
        backgroundView.bounds = self.tableView.bounds
        self.tableView.backgroundView = backgroundView
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            
            let navController = self.parent as! UINavigationController
            let mainViewController = navController.viewControllers[0] as! MainViewController
            mainViewController.refreshNotifications()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notification.totalFollowRequests
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "notificationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NotificationsTableViewCell
        let followRequest = self.notification.followRequest[indexPath.row]
        cell.followRequest = followRequest
        followRequest.fetchInBackground {
            (object: PFObject?, error: Error?) -> Void in
            let user = object!["from"] as! PFUser
            cell.id = object?.objectId
            user.fetchInBackground {
                (targetUser: PFObject?, error: Error?) -> Void in
                if let targetUser = targetUser {
                    cell._username.text = targetUser["username"] as? String
                    cell.user = targetUser as? PFUser
                    let currentLocation = PFUser.current()?["location"] as? PFGeoPoint
                    let targetLocation = targetUser["location"] as? PFGeoPoint
                    if let currentLocation = currentLocation, let targetLocation = targetLocation {
                        let distance = currentLocation.distanceInKilometers(to: targetLocation)
                        let distanceString = String(format: "%.2f km", distance)
                        cell._distance.text = distanceString
                    }
                    let image = targetUser["profilePic"] as! PFFileObject
                    image.getDataInBackground {
                        (imageData: Data?, error: Error?) -> Void in
                        if let imageData = imageData {
                            cell._profilePic.image = UIImage(data: imageData)
                            cell._profilePic.clipsToBounds = true
                            cell._profilePic.layer.cornerRadius = 30
                            cell._profilePic.contentMode = .scaleAspectFill
                        }
                    }
                }
            }
        }
        cell.backgroundColor = UIColor.clear
        
        return cell
        
    }
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        tableView.reloadData()
    }

    /*
    // MARK: - Navigation

     // In a storyboa as! PFUserrd-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
