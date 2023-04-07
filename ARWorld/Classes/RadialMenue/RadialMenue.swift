//
//  RadialMenue.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/17/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class RadialMenue: UIView {
    // MARK: - Types
    enum Option {
        case addToReality
        case addText
        case addCassette
        case addObject
    }
    
    // MARK: - Configuration
    
    let addToRealityColor = UIColor(red: 218/255.0, green: 225/255.0, blue: 239/255.0, alpha: 0.9)
    let gradientColorOne = UIColor(red: 130/255.0, green: 130/255.0, blue: 130/255.0, alpha: 1)
    let gradientColorTwo = UIColor.white
    let optionsAngle: CGFloat = 100 * .pi / 180
    var smallArcRadius: CGFloat!
    let addToRealityRatio: CGFloat = 0.25
    let xTranslation: CGFloat = 44.5
    let yTranslation: CGFloat = 77.5
    
    // MARK: - Properties
    
    var addToRealityRect: CGRect!
    var addTextRect: CGRect!
    var addCassetteRect: CGRect!
    var addObjectRect: CGRect!
    
    var delegate: RadialMenueDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        drawAddToReality()
        drawAddText()
        drawAddCassette()
        drawAddObject()
        //drawLines()
    }
    
    private func drawAddToReality() {
        UIGraphicsPushContext(UIGraphicsGetCurrentContext()!)
        let inset = (1 - addToRealityRatio) * bounds.width / 2
        let rect = bounds.insetBy(dx: inset, dy: inset)
        addToRealityRect = rect
        smallArcRadius = rect.width * 0.6
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width / 2)
        path.addClip()
        
        UIImage(named: "Polished_Silver")!.draw(in: rect, blendMode: .normal, alpha: 0.6)
        
        
        // Draw Add to reality
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        if traitCollection.horizontalSizeClass == .compact {
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont.systemFont(ofSize: 14),
                              NSAttributedString.Key.foregroundColor : addToRealityColor,
                              ]
            
            let myText = "Add to Reality"
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            
            attrString.draw(in: rect.offsetBy(dx: 0, dy: rect.width / 5.2))
            UIGraphicsPopContext()
        } else if traitCollection.horizontalSizeClass == .regular {
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont.systemFont(ofSize: 25),
                              NSAttributedString.Key.foregroundColor : addToRealityColor,
                              ]
            
            let myText = "Add to Reality"
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            
            attrString.draw(in: rect.offsetBy(dx: 0, dy: rect.width / 5.2))
            UIGraphicsPopContext()
        }
    }
    
    private func drawAddText() {
        let context = UIGraphicsGetCurrentContext()!
        context.resetClip()
        context.setAlpha(0.6)
        let arcCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let outlinePath = UIBezierPath()
        outlinePath.addArc(withCenter: arcCenter, radius: smallArcRadius, startAngle: (3 * .pi / 2) - optionsAngle / 2, endAngle: (3 * .pi / 2) + optionsAngle / 2, clockwise: true)
        outlinePath.addArc(withCenter: arcCenter, radius: bounds.height / 2, startAngle: (3 * .pi / 2) + optionsAngle / 2, endAngle: (3 * .pi / 2) - optionsAngle / 2, clockwise: false)
        
        outlinePath.close()
        
        addTextRect = outlinePath.bounds
        
        outlinePath.addClip()
        
        let colors = [gradientColorOne.cgColor, gradientColorTwo.cgColor, gradientColorOne.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.25, 0.5, 0.75]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        
        let startPoint = CGPoint(x: bounds.minX, y: bounds.midY)
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.midY)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        
        // Draw A Large A
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        if traitCollection.horizontalSizeClass == .compact {
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont(name: "HelveticaNeue-Bold", size: 70),
                              NSAttributedString.Key.foregroundColor : UIColor.white,
                              ]
            
            let myText = "A"
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            
            attrString.draw(in: addTextRect)
            
        } else if traitCollection.horizontalSizeClass == .regular {
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont(name: "HelveticaNeue-Bold", size: 120),
                              NSAttributedString.Key.foregroundColor : UIColor.white,
                              ]
            
            let myText = "A"
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            
            attrString.draw(in: addTextRect)
            
        }
        
        UIColor(red: 104/255.5, green: 83/255.0, blue: 83/255.0, alpha: 1).setStroke()
        outlinePath.lineWidth = 3
        outlinePath.stroke()
    }
    
    private func drawAddCassette() {
        let context = UIGraphicsGetCurrentContext()!
        context.resetClip()
        let arcCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let outlinePath = UIBezierPath()
        outlinePath.addArc(withCenter: arcCenter, radius: smallArcRadius, startAngle: (.pi / 6) - optionsAngle / 2, endAngle: (.pi / 6) + optionsAngle / 2, clockwise: true)
        outlinePath.addArc(withCenter: arcCenter, radius: bounds.height / 2, startAngle: (.pi / 6) + optionsAngle / 2, endAngle: (.pi / 6) - optionsAngle / 2, clockwise: false)
        
        outlinePath.close()
        
        addCassetteRect = outlinePath.bounds
        
        outlinePath.addClip()
        
        let colors = [gradientColorOne.cgColor, gradientColorTwo.cgColor, gradientColorOne.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.25, 0.5, 0.75]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        
        let startPoint = CGPoint(x: addCassetteRect.maxX, y: addCassetteRect.minY)
        let endPoint = CGPoint(x: addCassetteRect.minX, y: addCassetteRect.maxY)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        
        // Draw Cassette Image
        let cassetteImage = UIImage(named: "RotatedCassette")
        let cassetteImageSize = CGSize(width: 261.368, height: 298.703)
        let imageWidth = addCassetteRect.width * 0.7
        let imageScale = (cassetteImageSize.width / imageWidth)
        let imageHeight = (cassetteImageSize.height / imageScale)
        let imageRect = addCassetteRect.insetBy(dx: (addCassetteRect.width - imageWidth) / 2, dy: (addCassetteRect.height - imageHeight) / 2)
        cassetteImage?.draw(in: imageRect)
        
        UIColor(red: 104/255.5, green: 83/255.0, blue: 83/255.0, alpha: 1).setStroke()
        outlinePath.lineWidth = 3
        outlinePath.stroke()
    }
    
    private func drawAddObject() {
        let context = UIGraphicsGetCurrentContext()!
        context.resetClip()
        let arcCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let outlinePath = UIBezierPath()
        outlinePath.addArc(withCenter: arcCenter, radius: smallArcRadius, startAngle: 5 * (.pi / 6) - optionsAngle / 2, endAngle: 5 * (.pi / 6) + optionsAngle / 2, clockwise: true)
        outlinePath.addArc(withCenter: arcCenter, radius: bounds.height / 2, startAngle: 5 * (.pi / 6) + optionsAngle / 2, endAngle: 5 * (.pi / 6) - optionsAngle / 2, clockwise: false)
        
        outlinePath.close()
        
        addObjectRect = outlinePath.bounds
        
        outlinePath.addClip()
        
        let colors = [gradientColorOne.cgColor, gradientColorTwo.cgColor, gradientColorOne.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.25, 0.5, 0.75]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        
        let startPoint = CGPoint(x: addObjectRect.minX, y: addObjectRect.minY)
        let endPoint = CGPoint(x: addObjectRect.maxX, y: addObjectRect.maxY)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        
        // Draw Cangle
        let cassetteImage = UIImage(named: "RotatedCandle")
        let cassetteImageSize = CGSize(width: 240.38, height: 180.07)
        let imageWidth = addObjectRect.width * 0.55
        let imageScale = (cassetteImageSize.width / imageWidth)
        let imageHeight = (cassetteImageSize.height / imageScale)
        let imageRect = addObjectRect.insetBy(dx: (addObjectRect.width - imageWidth) / 2, dy: (addObjectRect.height - imageHeight) / 2)
        cassetteImage?.draw(in: imageRect)
        
        UIColor(red: 104/255.5, green: 83/255.0, blue: 83/255.0, alpha: 1).setStroke()
        outlinePath.lineWidth = 3
        outlinePath.stroke()
    }

    private func drawLines() {
        let context = UIGraphicsGetCurrentContext()
        context?.resetClip()
        
        let initialPoint = CGPoint(x: 30 * cos(CGFloat.pi / 6) + bounds.midX, y: -(30 * sin(CGFloat.pi / 6)) + bounds.midY)
        let finalPoint = CGPoint(x: bounds.height / 2 * cos(CGFloat.pi / 6) + bounds.midX, y: -(bounds.height / 2 * sin(CGFloat.pi / 6)) + bounds.midY)
        
        let path = UIBezierPath()
        path.lineWidth = 3
        UIColor.gray.setStroke()
        path.move(to: initialPoint)
        path.addLine(to: finalPoint)
        path.stroke()
    }
    
    // MARK: - Handling Tap
    
    @objc private func viewTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        var tappedOption: Option?
        
        if addToRealityRect.contains(location) {
            tappedOption = .addToReality
        } else if addTextRect.contains(location) {
            tappedOption = .addText
        } else if addCassetteRect.contains(location) {
            tappedOption = .addCassette
        } else if addObjectRect.contains(location) {
            tappedOption = .addObject
        }
        delegate?.radialMenue(self, didSelect: tappedOption!)
    }
}
