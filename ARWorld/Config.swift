//
//  Config.swift
//  ARWorld
//
//  Created by Reza Hemadi on 2/15/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

struct Conf {
    
    let ObjectsRadius: Double = 30
    let BannersRadius: Double = 500
    let PrefferedLocationAccuracy: Int = 10
    let LocationManagerDistanceFilter: Double = 1
    let LocationManagerHeadingFilter: Double = 5
    let LocationUpdateHowRecentTolerance: Double = 10
    let OutdoorLocationAccuracySensitivity: Int = 6
    let BannerScalingFactorConstant: Double = 200
    let ButtonsAnimationDuration: Double = 0.3
    let FoursquareVenueLimit: Int = 5
    let FoursquareVenueRadius: Double = 100
    let VenueDistanceLimit: Double = 100
    let DroneDistanceFollowQue: Double = 2
}
