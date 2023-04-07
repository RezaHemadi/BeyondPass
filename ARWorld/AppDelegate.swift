//
//  AppDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 9/26/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import UIKit
import Parse
import Bolts
import FBSDKCoreKit
import FBSDKLoginKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Parse.enableLocalDatastore()
        let configuration = ParseClientConfiguration {
            $0.applicationId = "0wL3QQu9zOuDX72PAIfZzTamjv3qLY1U5tvMkEBi"
            $0.clientKey = "jTK4yevAiEosY2W5chFKWxbPXxURRJ4ANPnST304"
            $0.server = "https://ar-world.info/parse/"
        }
        
        Parse.initialize(with: configuration)
        
        PFAnalytics.trackAppOpenedWithLaunchOptions(inBackground: launchOptions, block: nil)
        
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        UITabBar.appearance().backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0,
                                                  blue: 242.0/255.0, alpha: 0.5)
        
        registerForPushNotifications()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        /// Register an observer for SKTransactions
        SKPaymentQueue.default().add(Store.sharedInstance())
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let params = components.queryItems, params.first?.name == "userId" {
                if let id = params.first?.value {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let navController = storyboard.instantiateViewController(withIdentifier: "MainNav") as! UINavigationController
                    window?.rootViewController = navController
                    let mainViewController = navController.viewControllers[0] as! MainViewController
                    let userQuery = PFUser.query()
                    userQuery?.getObjectInBackground(withId: id, block: { (object, error) in
                        if error == nil {
                            if let user = object {
                                mainViewController.targetUserProfile = user as! PFUser
                                mainViewController.performSegue(withIdentifier: "MainToUsersProfile", sender: nil)
                            }
                        }
                    })
                }
            } else {
                
            }
        }
        
        return ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation:[UIApplication.LaunchOptionsKey.annotation])
    }
    
    func registerForPushNotifications() {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        
        UNUserNotificationCenter.current().getNotificationSettings {
            (settings) in
            
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else { return }
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        PFPush.handle(userInfo)
    }

}

