//
//  EditProfileViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/17/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var _editButton: UIButton!
    @IBOutlet var _confirmEditButton: UIButton!
    @IBOutlet var _profilePicImage: UIImageView!
    @IBOutlet var _tapToChange: UIButton!
    @IBOutlet var _usernameLabel: UILabel!
    @IBOutlet var _emailLabel: UILabel!
    @IBOutlet var _arPostLabel: UILabel!
    @IBOutlet var _followingLabel: UILabel!
    @IBOutlet var _followerLabel: UILabel!
    @IBOutlet var _isPrivate: UISwitch!
    @IBOutlet var _followingView: UIView!
    @IBOutlet var _followerView: UIView!
    @IBOutlet var _arPostsView: UIView!

    var isAccountPrivate: Bool!
    var followingCount: Int32!
    var arPosts: String = ""
    var followersCount: String = ""
    var visitsCount: String = ""
    var imageSize = CGSize.init(width: 512, height: 512)
    
    var profilePicImage: PFFileObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self._isPrivate.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
        self._editButton.isEnabled = false
        self._tapToChange.layer.cornerRadius = 5
        self._isPrivate.isOn = false
        self._arPostsView.layer.cornerRadius = 20
        self._followerView.layer.cornerRadius = 20
        self._followingView.layer.cornerRadius = 20
        
        self._arPostLabel.text = self.arPosts
        self._followerLabel.text = self.followersCount
        
        let currentUser = PFUser.current()
        if let currentUser = currentUser {
            self._usernameLabel.text = "Username: " + currentUser.username!
            self._emailLabel.text = "Email: " + currentUser.email!
            self.isAccountPrivate = currentUser["PrivateAccount"] as? Bool
            if let isAccountPrivate = self.isAccountPrivate {
                self._isPrivate.isOn = isAccountPrivate
            }
            
            self._followingLabel.text = String(self.followingCount)
            let image = currentUser["profilePic"] as? PFFileObject
            image?.getDataInBackground {
                (data: Data?, error: Error?) -> Void in
                if let data = data {
                    self._profilePicImage.image = UIImage(data: data)
                    self._profilePicImage.clipsToBounds = true
                    self._profilePicImage.layer.cornerRadius = 90
                    self._profilePicImage.contentMode = .scaleAspectFill
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeProfilePic(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage {
            
            let resizedImage = resizeImage(image: selectedImage, targetSize: self.imageSize)
            _profilePicImage.image = resizedImage
            _profilePicImage.contentMode = .scaleAspectFill
            _profilePicImage.clipsToBounds = true
            let imageData = resizedImage.pngData()
            self.profilePicImage = PFFileObject(name: "profilePic.png", data: imageData!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        // Do something
        self.isAccountPrivate = value
    }
    
    @IBAction func confirmEdit(sender: UIButton) {
        // save profile pic in background
        let currentUser = PFUser.current()!
        var shouldSave: Bool = false
        
        if let profileImage = self.profilePicImage {
            
            currentUser["profilePic"] = profileImage
            shouldSave = true
        }
        if let isPrivate = self.isAccountPrivate {
            
            currentUser["PrivateAccount"] = isPrivate
            shouldSave = true
        }
            
        if shouldSave {
            
            currentUser.saveInBackground {
                (succeed: Bool?, error: Error?) -> Void in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }

        }
        
        // pop this view controller from the navigation controller
        let navController = self.parent as! UINavigationController
        
        navController.popToRootViewController(animated: true)
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
