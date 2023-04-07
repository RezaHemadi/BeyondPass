//
//  modifyARCoins.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import Parse

func modifyARCoins(_ coinTransaction: CoinTransaction) {

    let user = PFUser.current()
    let currentCoins = user!["ARCoin"] as! Int
    
    let (amount, _) = transaction(coinTransaction)
  
    let newCoins = currentCoins + amount
    user!["ARCoin"] = newCoins
        
    user!.saveInBackground {
        (succeed: Bool?, error: Error?) -> Void in
            
        if let _ = succeed {
            
        }
    }
    
}
