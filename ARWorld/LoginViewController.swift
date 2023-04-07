//
//  LoginViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 9/28/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse
import CoreLocation

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var _username: UITextField!
    
    @IBOutlet var _password: UITextField!
    
    @IBOutlet var _login_button: UIButton!
    
    @IBOutlet var _forgotPassView: UIView!
    
    @IBOutlet var _forgotPassButton: UIButton!
    
    @IBOutlet var _cancelForgotPass: UIButton!
    
    @IBOutlet var _sendResetPass: UIButton!
    
    @IBOutlet var _resetEmail: UITextField!
    
    @IBOutlet var signUpButton: UIButton!
    
    // MARK: - Properties
    
    var user: PFUser!
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self._forgotPassView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        
        self._username.delegate = self
        self._password.delegate = self
        
        self._username.tag = 0
        self._password.tag = 1
        
        if view.traitCollection.horizontalSizeClass == .compact {
            _login_button.layer.cornerRadius = 15
        } else {
            _login_button.layer.cornerRadius = 25
        }
        _login_button.clipsToBounds = true
        
        navigationController?.isNavigationBarHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Action Methods
    
    @IBAction func LoginButton(_ sender: Any) {
        let username = _username.text
        let password = _password.text
        
        if (username == "" || password == "") {
            let alertController = UIAlertController(title:"Login error",
                                                    message: "Username and Password must not be empty",
                                                    preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title:"OK", style: UIAlertAction.Style.default,
                                                    handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            DoLogin(username: username!, password: password!)
        }
    }
    
    
    @IBAction func resetPass(_ sender: UIButton) {
        
        view.bringSubviewToFront(_forgotPassView)
        
        UIView.animate(withDuration: 0.3) {
            
            self._forgotPassView.transform = CGAffineTransform.identity
        }
        self._resetEmail.isEnabled = true
    }
    
    @IBAction func cancelPassReset(_ sender: UIButton) {
        
        self._resetEmail.isEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            
            self._forgotPassView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
        }
    }
    
    @IBAction func confirmResetPassword(_ sender: UIButton) {
        
        if let email = self._resetEmail.text {
            
            if isValidEmail(testStr: email) {
                
                PFUser.requestPasswordResetForEmail(inBackground: email) {
                    (succeed: Bool?, error: Error?) -> Void in
                    
                    if let _ = succeed {
                        
                        let alertMessage = UIAlertController(title: "Password Reset", message: "An email will be sent to you in order to reset your password", preferredStyle: .alert)
                        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        
                        self.present(alertMessage, animated: true, completion: nil)
                    }
                }
                
            } else {
                
                let alertMessage = UIAlertController(title: "Invalid Email", message: "Please enter a valid email address", preferredStyle: .alert)
                alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self.present(alertMessage, animated: true, completion: nil)
            }
            
            
        } else {
            
            let alertMessage = UIAlertController(title: "No Email", message: "Please enter an email address", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alertMessage, animated: true, completion: nil)
        }
    }
    
    
    
    @IBAction func signUp(sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    
    func DoLogin(username: String, password: String) {
        self._login_button.isEnabled = false
        
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
        
        var _ = PFUser.logInWithUsername(inBackground: username, password: password) {
            (user: PFUser?, error: Error?) in
            if (user != nil) {
                self.user = user
                
                // link the current installation with the current user
                let currentInstallation = PFInstallation.current()
                currentInstallation?["user"] = user!
                currentInstallation?.saveInBackground()
                /*
                // Check if the user has inventory
                let inventoryQuery = PFQuery(className: "Inventory")
                inventoryQuery.whereKey("User", equalTo: user)
                inventoryQuery.findObjectsInBackground {
                    (objects, error) in
                    if let inventoryObjects = objects {
                        if inventoryObjects.count == 0 {
                            user!.createDefaultInventory()
                        }
                    }
                } */
                let userDefaults = UserDefaults.standard
                let hasViewedWalkthrough = userDefaults.bool(forKey: "hasViewedWalkthrough")
                if hasViewedWalkthrough {
                    self.performSegue(withIdentifier: "LoginToAR", sender: self)
                } else if let pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughPageViewController {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                    self.present(pageViewController, animated: true, completion: nil)
                }
                
                activityIndicator.stopAnimating()
        }
            else if let error = error {
                self._login_button.isEnabled = true
                
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
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
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.returnKeyType == .go {
            let username = self._username.text
            let password = self._password.text
            
            if let username = username, let password = password {
                DoLogin(username: username, password: password)
            }
            
        } else if textField.returnKeyType == .next {
            
            // try to find the next responder
            if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                
                nextField.becomeFirstResponder()
            } else {
                // Not found, so remove keyboard
                textField.resignFirstResponder()
            }
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            
            textField.isSecureTextEntry = true
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
    }
}
