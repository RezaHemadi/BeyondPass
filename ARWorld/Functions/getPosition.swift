//
//  getPosition.swift
//  ARWorld
//
//  Created by Reza Hemadi on 12/23/17.
//  Copyright © 2017 ArvandGroup. All rights reserved.
//

import Foundation
func getPosition(userLocation: CLLocation, userHeading: CLLocationDirection, to: CLLocation) -> SCNVector3 {
    var bearing = bearingToLocationDegrees(userLocation: userLocation, destinationLocation: to)
    var z: Double!
    var x: Double!
            
    if (bearing.isLess(than: 0)) {
        bearing = 360 + bearing
    }
    let alpha = degreesToRadians(userHeading - bearing)
    
    let distance = userLocation.distance(from: to)
    
    if (alpha > 0 && alpha < Double.pi / 2) {
        z = distance * abs(cos(alpha))
        x = distance * abs(sin(alpha))
        x = -abs(x)
        z = -abs(z)
    }
    if ((alpha < 0) && (alpha > -(Double.pi / 2))) {
        z = distance * abs(cos(alpha))
        x = distance * abs(sin(alpha))
        z = -abs(z)
    }
    if ((alpha > Double.pi / 2) && (alpha < Double.pi)) {
        z = distance * abs(sin(alpha - (Double.pi / 2)))
        x = distance * abs(cos(alpha - (Double.pi / 2)))
        x = -abs(x)
    }
    if ((alpha > Double.pi) && (alpha < 3 * (Double.pi) / 2)) {
        x = distance * abs(cos(alpha - (3 * (Double.pi) / 2)))
        z = distance * abs(sin(alpha - (3 * (Double.pi) / 2)))
        x = abs(x)
        z = abs(z)
    }
    if ((alpha > -(Double.pi)) && (alpha < -((Double.pi) / 2))) {
        x = distance * abs(cos(alpha - (Double.pi / 2)))
        z = distance * abs(sin(alpha - (Double.pi / 2)))
    }
    if ((alpha > 3 * (Double.pi / 2)) && (alpha < 2 * Double.pi)) {
        x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
        z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
        z = -abs(z)
    }
    if ((alpha > (-2 * Double.pi)) && (alpha < (-3 * Double.pi / 2)))  {
        x = distance * abs(cos(alpha - (3 * (Double.pi / 2))))
        z = distance * abs(sin(alpha - (3 * (Double.pi / 2))))
        x = -abs(x)
        z = -abs(z)
    }
    if ((alpha > (-3 * (Double.pi / 2))) && (alpha < -(Double.pi))) {
        x = distance * abs(cos((3 * (Double.pi) / 2) - alpha))
        z = distance * abs(sin((3 * (Double.pi) / 2) - alpha))
        x = -abs(x)
    }
    return SCNVector3.init(Float(x), 0, Float(z))
}
