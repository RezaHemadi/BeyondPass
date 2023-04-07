//
//  CompassBar.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import CoreGraphics

class CompassBar: UIView {
    // MARK: - Types
    enum GeoDirection: CLLocationDirection {
        case north = 01
        case east = 90
        case south = 180
        case west = 270
        
        var label: String {
            get {
                switch self {
                case .north:
                    return "N"
                case .east:
                    return "E"
                case .south:
                    return "S"
                case .west:
                    return "W"
                }
            }
        }
        
        static var all: [GeoDirection] = [.north, .east, .south, .west]
    }
    
    // MARK: - Configuration
    let barColor = UIColor(red: 96/255, green: 183/255, blue: 250/255, alpha: 0.6)
    let compassViewAngle: Int = 60
    let labelColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
    let labelFontSize: CGFloat = 17
    
    // MARK: - Properties
    var heading: CLLocationDirection? {
        didSet{
            guard heading != nil else { lowerLimit = nil; upperLimit = nil; return }
            
            // Calculate lower limit
            if (heading! - halfViewAngle) < 0 {
                lowerLimit = 360 + (heading! - halfViewAngle)
            } else {
                lowerLimit = heading! - halfViewAngle
            }
            
            // Calculate upper Limit
            if (heading! + halfViewAngle) > 360 {
                upperLimit = (heading! + halfViewAngle) - 360
            } else {
                upperLimit = (heading! + halfViewAngle)
            }
            setNeedsDisplay()
        }
    }
    
    var bearingToPinBoard: [CGFloat] = []
    
    var bearingToTreasure: CGFloat?
    
    var markers: [String: CompassMarker] = [:]
    
    var halfViewAngle: Double {
        return Double(compassViewAngle / 2)
    }
    
    var sliderWidth: CGFloat!
    
    var lowerLimit: CLLocationDirection?
    
    var upperLimit: CLLocationDirection?
    
    var step: CGFloat!
    
    var currentGeoDirections: [GeoDirection] {
        var directions = [GeoDirection]()
        
        guard heading != nil else { return directions }
        
        for direction in GeoDirection.all {
            if isCompassEnclosing(direction.rawValue) == true {
                directions.append(direction)
            }
        }
        return directions
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 10))
        
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        drawBar()
        step = bounds.width / CGFloat(compassViewAngle)
        
        // Draw any Geo Directions if available
        drawGeoDirections()
        
        drawMarkers()
        drawPinBoards()
        drawTreasure()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    private func drawBar() {
        let context = UIGraphicsGetCurrentContext()!
        
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8.0, height: 8.0))
        path.addClip()
        
        let colors = [UIColor.clear.cgColor, barColor.cgColor, UIColor.clear.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 0.5, 1.0]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x: 0, y: bounds.height)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }
    private func drawGeoDirections() {
        for direction in currentGeoDirections {
            let angle = direction.rawValue
            let offSet = calculateOffSet(for: angle)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont.systemFont(ofSize: labelFontSize),
                              NSAttributedString.Key.foregroundColor : labelColor,
                              ]
            
            let myText = direction.label
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            let rt = CGRect(x: offSet - 10, y: 5, width: 20, height: bounds.height)
            attrString.draw(in: rt)
        }
    }
    
    private func drawMarkers() {
        for (_ , marker) in markers {
            let offset = calculateOffSet(for: marker.bearing)
            let imageSize = marker.image.size
            let viewHeight = bounds.height - 3
            let scale: CGFloat = viewHeight / imageSize.height
            let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let rt = CGRect(x: offset - scaledImageSize.width / 2, y: 5, width: scaledImageSize.width, height: scaledImageSize.height)
            marker.image.draw(in: rt)
        }
    }
    
    private func drawPinBoards() {
        guard !bearingToPinBoard.isEmpty else { return }
        
        let templeIcon = UIImage(named: "ARTempleIcon")!
        
        for bearing in bearingToPinBoard {
            let offset = calculateOffsetFromMiddle(angle: bearing)
            let imageSize = templeIcon.size
            let viewHeight = bounds.height - 3
            let scale: CGFloat = viewHeight / imageSize.height
            let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let rt = CGRect(x: bounds.midX + offset - scaledImageSize.width / 2, y: 5, width: scaledImageSize.width, height: scaledImageSize.height)
            templeIcon.draw(in: rt)
        }
    }
    
    private func drawTreasure() {
        guard bearingToTreasure != nil else { return }
        
        let treasureIcon = UIImage(named: "TreasureIcon")!
        
        let offset = calculateOffsetFromMiddle(angle: bearingToTreasure!)
        let imageSize = treasureIcon.size
        let viewHeight = bounds.height - 3
        let scale: CGFloat = viewHeight / imageSize.height
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let rt = CGRect(x: bounds.midX + offset - scaledImageSize.width / 2, y: 5, width: scaledImageSize.width, height: scaledImageSize.height)
        treasureIcon.draw(in: rt)
    }
    
    // MARK: Helper Methods
    private func isCompassEnclosing(_ direction: CLLocationDirection) -> Bool? {
        guard heading != nil, upperLimit != nil, lowerLimit != nil else { return nil }
        
        if upperLimit! > lowerLimit! {
            if (lowerLimit! < direction && direction < upperLimit!) {
                return true
            }
        } else {
            if (direction > lowerLimit! || direction < upperLimit!) {
                return true
            }
        }
        return false
    }
    /*
    private func calculateOffSet(for angle: CLLocationDirection) -> CGFloat {
        let distanceDegrees = angle - heading!
        let middle = bounds.width / 2
        
        return middle + (step * CGFloat(distanceDegrees))
    }
 */
    
    private func calculateOffSet(for angle: CLLocationDirection) -> CGFloat {
        if angle > lowerLimit! {
            let distanceDegrees = angle - lowerLimit!
            return step * CGFloat(distanceDegrees)
        }
        let distanceDegrees = ( 360 - lowerLimit! ) + angle
        return step * CGFloat(distanceDegrees)
    }
    
    private func calculateOffsetFromMiddle(angle: CGFloat) -> CGFloat {
        return step * angle
    }
    
    func removeWhisperMarkers() {
        var ids: [String] = []
        
        for (id, value) in markers {
            if value.style != nil {
                switch value.style! {
                case .whisper:
                    ids.append(id)
                default:
                    continue
                }
            }
        }
        for id in ids {
            markers[id] = nil
        }
    }
}
extension CompassBar: WhisperMarkerManagerDelegate {
    func addMarker(_ marker: CompassMarker, with id: String, for whisperMarkerManager: WhisperMarkerManager) {
        markers[id] = marker
    }
    
    func updateMarker(_ marker: CompassMarker, with id: String, for whisperMarkerManager: WhisperMarkerManager) {
        markers.updateValue(marker, forKey: id)
    }
}
