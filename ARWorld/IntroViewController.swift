//
//  IntroViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 11/12/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse

class IntroViewController: UIViewController {
    
    var user: PFUser!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let user = PFUser.current()
        if (user != nil) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "introToAR", sender: self)
            }
        } else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "IntroToSignup", sender: self)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
    }
    

}
