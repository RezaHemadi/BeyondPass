//
//  transaction.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/26/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

func transaction(_ coinTransaction: CoinTransaction) -> (Int, String) {
    
    switch coinTransaction {
    case .NewFollower:
        return (50, "New follower")
        
    case .FollowedUser:
        return (10, "Followed a user")
        
    case .Visit:
        return (10, "Visited a new Plaza")
        
    case .ReVisit:
        return (-2, "Re-Visited Plaza")
        
    case .SkyWriting:
        return (-15, "Added SkyWriting")
        
    case .MessageBottle:
        return (-15, "Added Message Bottle")
        
    case .Object:
        return (-15, "Added an Object")
        
    case .AddVoice:
        return (-20, "Added voice message")
        
    case .ListenVoice:
        return (2, "Listened to voice message")
        
    case .ReadBottle:
        return (2, "Read Message Bottle")
    }
}
