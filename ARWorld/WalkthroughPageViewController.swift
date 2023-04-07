//
//  WalkthroughPageViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 2/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class WalkthroughPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var pageHeadings = ["BeyondPass",
                        "Portal",
                        "Treasure",
                        "Personal Pinboard",
                        "BackPack",
                        "Store"]
    var pageImages = ["LoginLogo",
                      "ARPortal",
                      "TreasureIcon",
                      "PersonalPinBoardIcon",
                      "Backpack",
                      "InAppPurchases"]
    var pageContent = ["BeyondPass gives you access to Arcanum, a parallel world in which you can play and socialize.",
                       "Let’s you access your portal, which is your virtual home and your friends can enter.",
                       "When you see this icon on your compass move to its direction, there are various trophies to show off in the BeyondPass World.",
                       "This button will call your personal pinboard and You can place Voice badges, Photos and Notes on it.",
                       "in sandbox mode you can play around with your backpack items easily.",
                       "Don't forget to check out BeyondPass Store."]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataSource = self
        
        if let startingViewController = contentViewController(at: 0) {
            
            setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! WalkthroughContentViewController).index
        index += 1
        
        return contentViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! WalkthroughContentViewController).index
        index -= 1
        
        return contentViewController(at: index)
    }
    
    func contentViewController(at index: Int) -> WalkthroughContentViewController? {
        
        if index < 0 || index >= pageHeadings.count {
            
            return nil
        }
        
        // create a new view controller and pass suitable data
        if let pageContentViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughContentViewController") as? WalkthroughContentViewController {
            
            pageContentViewController.imageFile = pageImages[index]
            pageContentViewController.heading = pageHeadings[index]
            pageContentViewController.content = pageContent[index]
            pageContentViewController.index = index
            
            return pageContentViewController
        }
        return nil
    }
    
    /*
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        
        return pageHeadings.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        
        if let pageContentViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughContentViewController") as? WalkthroughContentViewController {
            
            return pageContentViewController.index
        }
        
        return 0
    }
 */
    
    func forward(index: Int) {
        
        if let nextViewController = contentViewController(at: index + 1) {
            
            setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
        }
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
