//
//  CreditsViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class CreditsViewController: UIViewController {
    
    // MARK: - Interface Outlets
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var creditsBody: UITextView!
    
    @IBOutlet var closeButton: UIButton!
    
    // MARK : - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        closeButton.layer.cornerRadius = 5
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Actions
    
    @IBAction func close(_ sender: UIButton) {
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
