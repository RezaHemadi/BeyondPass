//
//  bearingToLocationDegrees.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/23/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation

func bearingToLocationDegrees(userLocation: CLLocation, destinationLocation:CLLocation) -> Double {
    return   radiansToDegrees(bearingToLocationRadian(userLocation, destinationLocation))
}
