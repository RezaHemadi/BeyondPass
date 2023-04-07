//
//  WalkthroughContentViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 2/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class WalkthroughContentViewController: UIViewController {
    
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var contentImageView: UIImageView!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var pageControl: UIPageControl!
    
    var index = 0
    var heading = ""
    var imageFile = ""
    var content = ""
    var tempText: String = ""
    var currentCharacter: Int = 0
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        headingLabel.text = heading
        contentLabel.text = content
        contentImageView.image = UIImage(named: imageFile)
        pageControl.currentPage = index
        
        switch index {
        case 0:
            forwardButton.setTitle("NEXT", for: .normal)
            contentLabel.text = tempText
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                guard !self.content.isEmpty else { self.timer?.invalidate(); return }
                DispatchQueue.main.async {
                    self.contentLabel.text?.append(self.content.first!)
                    self.content.removeFirst()
                }
            })
        case 1 ... 4:
            forwardButton.setTitle("NEXT", for: .normal)
        case 5: forwardButton.setTitle("DONE", for: .normal)
        default: break
        }
    }
    
    @IBAction func nextButtonTapped(sender: UIButton) {
        
        switch index {
            
        case 0 ... 4:
            let pageViewController = parent as! WalkthroughPageViewController
            pageViewController.forward(index: index)
            
        case 5:
            UserDefaults.standard.set(true, forKey: "hasViewedWalkthrough")
            self.performSegue(withIdentifier: "WalkthroughToMain", sender: self)
            
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}
