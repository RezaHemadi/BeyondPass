//
//  CompassMarker.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/1/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class CompassMarker {
    
    // MARK: - Types
    
    enum Style {
        case user
        case whisper
        
        var image: UIImage {
            get {
                switch self {
                case .user:
                    return UIImage(named: "UserMarker")!
                case .whisper:
                    return UIImage(named: "WhisperMarker")!
                }
            }
        }
    }
    
    // MARK: - Properties
    
    var bearing: CLLocationDirection
    
    var image: UIImage
    
    var style: Style?
    
    // MARK: - Initializers
    
    init(bearing: CLLocationDirection, style: Style) {
        self.bearing = bearing
        self.style = style
        self.image = style.image
    }
    
    init(bearing: CLLocationDirection, image: UIImage) {
        self.bearing = bearing
        self.image = image
    }
}
