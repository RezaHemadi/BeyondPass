//
//  bearingToLocationRadian.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/23/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
func bearingToLocationRadian(_ userLocation: CLLocation, _ destinationLocation:CLLocation) -> Double {
    
    let lat1 = degreesToRadians(userLocation.coordinate.latitude)
    let lon1 = degreesToRadians(userLocation.coordinate.longitude)
    
    let lat2 = degreesToRadians(destinationLocation.coordinate.latitude);
    let lon2 = degreesToRadians(destinationLocation.coordinate.longitude);
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2);
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    let radiansBearing = atan2(y, x)
    
    return radiansBearing
}
