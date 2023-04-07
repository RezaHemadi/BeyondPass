//
//  SignUpViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 9/29/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class SignUpViewController: UIViewController,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var _email: UITextField!
    @IBOutlet var _username: UITextField!
    @IBOutlet var _password: UITextField!
    @IBOutlet var _showPasswordButton: UIButton!
    @IBOutlet var _signup_button: UIButton!
    @IBOutlet var _facebookSignupButton: UIButton!
    @IBOutlet var _loginButton: UIButton!
    @IBOutlet var _profilePic: UIImageView!
    
    // MARK: - Properties
    
    var user: PFUser!
    var profilePic: PFFileObject!
    var isPasswordHidden: Bool = true
    let targetImageSize = CGSize.init(width: 512, height: 512)
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //_profilePic.layer.cornerRadius = 30.0
        //_profilePic.clipsToBounds = true
        _profilePic.isUserInteractionEnabled = true
        
        self._email.delegate = self
        self._username.delegate = self
        self._password.delegate = self
        
        self._email.tag = 0
        self._username.tag = 1
        self._password.tag = 2
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                       action: #selector(picTap))
        singleTap.numberOfTapsRequired = 1
        _profilePic.addGestureRecognizer(singleTap)
        
        let tap: UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        
    }
    
    // MARK: - UI Action Methods
    
    @IBAction func showPassword(sender: UIButton) {
        let isSecure = _password.isSecureTextEntry
        
        if isSecure {
            _password.isSecureTextEntry = false
            
            _showPasswordButton.setImage(UIImage(named: "HidePassword"), for: .normal)
        } else {
            _password.isSecureTextEntry = true
            
            _showPasswordButton.setImage(UIImage(named: "Show"), for: .normal)
        }
    }
    
    @objc func picTap(recognizer: UIGestureRecognizer) {

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            
            let resizedImage = resizeImage(image: editedImage, targetSize: self.targetImageSize)
            _profilePic.image = resizedImage
            _profilePic.contentMode = .scaleAspectFill
            _profilePic.clipsToBounds = true
            _profilePic.layer.cornerRadius = 30
            let imageData = resizedImage.pngData()
            self.profilePic = PFFileObject(name: "profilePic.png", data: imageData!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        let email = _email.text
        let username = _username.text
        let password = _password.text
        
        if (email == "") {
            let alertController = UIAlertController(title:"Sign Up error",
                                                    message: "Email must not be empty",
                                                    preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                    handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        
        else if (username == "") {
            let alertController = UIAlertController(title:"Sign Up error",
                                                    message: "Username must not be empty",
                                                    preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                    handler: nil))
            present(alertController, animated: true, completion: nil)
        }
            
        else if (password == "") {
            let alertController = UIAlertController(title:"Sign Up error",
                                                    message: "Password must not be empty",
                                                    preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                    handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            DoSignUp(email: email!, username: username!, password: password!)
        }
    }
    
    @IBAction func facebookSignup (sender: UIButton) {
        let permissions = ["public_profile", "email"]
        
        disableUserInput()
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let centerHorizontally = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerVertically = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let aspectRatio = NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: activityIndicator, attribute: .height, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        
        activityIndicator.addConstraint(aspectRatio)
        view.addConstraints([centerHorizontally,
                             centerVertically,
                             widthConstraint])
        
        activityIndicator.startAnimating()
        
        PFFacebookUtils.logInInBackground(withReadPermissions: permissions) {
            (user: PFUser?, error: Error?) -> Void in
            if let user = user {
                if user.isNew {
                    
                    Profile.loadCurrentProfile {
                        (profile: Profile?, error: Error?) -> Void in
                        let firstName = profile?.firstName
                        let lastName = profile?.lastName
                        /*
                        user.createDefaultInventory() */
                        
                        if let firstName = firstName, let lastName = lastName {
                            user.username = firstName + "." + lastName
                            user["ARCoin"] = 100
                            user["PrivateAccount"] = false
                            
                            // Set Profile Picture for user
                            if let imageURL = profile?.imageURL(forMode: .normal, size: CGSize.init(width: 512, height:512)) {
                                URLSession.shared.dataTask(with: imageURL) {
                                    (data: Data?, urlResponse: URLResponse?, error: Error?) in
                                    if let data = data {
                                        let imageFile = PFFileObject(data: data)
                                        user["profilePic"] = imageFile
                                        user.saveInBackground()
                                       // user.createDefaultInventory() 
                                        
                                    }
                                    }.resume()
                            }
                            
                            user.saveInBackground {
                                (succeed, error) in
                                if succeed == true {
                                    activityIndicator.stopAnimating()
                                    activityIndicator.removeFromSuperview()
                                    
                                    
                                     if let pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughPageViewController {
                                     self.present(pageViewController, animated: true, completion: nil)
                                     }
                                    //self.performSegue(withIdentifier: "SignupToAR", sender: self)
                                }
                            }
                        } else {
                            user["ARCoin"] = 100
                            user["PrivateAccount"] = false
                            user.saveEventually()
                            
                            
                             if let pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughPageViewController {
                             self.present(pageViewController, animated: true, completion: nil)
                             }
                            
                            //self.performSegue(withIdentifier: "SignupToAR", sender: self)
                        }
                    }
                } else if !user.isNew {
                    
                }
                else if let error = error {
                    
                    self.enableUserInput()
                    
                    let errorString = error.localizedDescription
                    let alertController = UIAlertController(title:"Login error",
                                                            message: errorString,
                                                            preferredStyle: UIAlertController.Style.alert)
                    alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                            handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    @IBAction func login(sender: UIButton) {
        _loginButton.isEnabled = false
        self.performSegue(withIdentifier: "SignupToLogin", sender: self)
    }
    
    // MARK: - Helper Methods
    
    func disableUserInput() {
        _email.isUserInteractionEnabled = false
        _username.isUserInteractionEnabled = false
        _password.isUserInteractionEnabled = false
        _showPasswordButton.isUserInteractionEnabled = false
        _signup_button.isUserInteractionEnabled = false
        _facebookSignupButton.isUserInteractionEnabled = false
        _loginButton.isUserInteractionEnabled = false
        _profilePic.isUserInteractionEnabled = false
    }
    
    func enableUserInput() {
        _email.isUserInteractionEnabled = true
        _username.isUserInteractionEnabled = true
        _password.isUserInteractionEnabled = true
        _showPasswordButton.isUserInteractionEnabled = true
        _signup_button.isUserInteractionEnabled = true
        _facebookSignupButton.isUserInteractionEnabled = true
        _loginButton.isUserInteractionEnabled = true
        _profilePic.isUserInteractionEnabled = true
    }
    
    func DoSignUp(email: String, username: String, password: String) {
        if let profilePic = self.profilePic {
            
            disableUserInput()
            
            let user = PFUser()
            user.username = username
            user.password = password
            user.email = email
            user["ARCoin"] = 100
            user["PrivateAccount"] = false
            user["profilePic"] = self.profilePic
            
            user.signUpInBackground {
                (succeed: Bool?, error: Error?) -> Void in
                if let error = error {
                    
                    self.enableUserInput()
                    
                    let errorString = error.localizedDescription
                    let alertController = UIAlertController(title:"Sign Up error",
                                                            message: errorString,
                                                            preferredStyle: UIAlertController.Style.alert)
                    alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                            handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                if let _ = succeed {
                    self.user = user
                    
                    // link the current installation to the current user
                    let currentInstallation = PFInstallation.current()
                    currentInstallation?["user"] = user
                    currentInstallation?.saveInBackground()
                    /*
                    // Create default Inventory for the user
                    user.createDefaultInventory() */
                    
                    if let pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughPageViewController {
                        self.present(pageViewController, animated: true, completion: nil)
                    }
                    
                    //self.performSegue(withIdentifier: "SignupToAR", sender: self)
                }
            }
        } else {
            
            let alertMessage = UIAlertController(title: "Profile Picture", message: "Please set a profile picture.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alertMessage, animated: true, completion: nil)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.returnKeyType == .next {
            
            switch textField.tag {
            case 0:
                _username.becomeFirstResponder()
            case 1:
                _password.becomeFirstResponder()
            default:
                break
            }
        } else if textField.returnKeyType == .go {
            
            let username = self._username.text
            let password = self._password.text
            let email = self._email.text
            
            if let username = username, let password = password, let email = email {
                self.DoSignUp(email: email, username: username, password: password)
            }
        }
        return true
    }
    

        override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if (textField.tag == 2) {
            
            _showPasswordButton.setImage(UIImage(named: "Show"), for: .normal)
            textField.isSecureTextEntry = true
        }
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
 

}
