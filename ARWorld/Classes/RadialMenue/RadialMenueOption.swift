//
//  RadialMenueOption.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/17/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class RadialMenueOption: UIView {
    
    // MARK: - Configuration
    let gradientColorOne = UIColor(red: 130/255.0, green: 130/255.0, blue: 130/255.0, alpha: 1)
    let gradientColorTwo = UIColor.white
    let optionsAngle: CGFloat = 100 * .pi / 180

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()!
        context.setAlpha(0.6)
        let arcCenter = CGPoint(x: bounds.midX, y: bounds.maxY)
        let outlinePath = UIBezierPath()
        outlinePath.addArc(withCenter: arcCenter, radius: 30, startAngle: (3 * .pi / 2) - optionsAngle / 2, endAngle: (3 * .pi / 2) + optionsAngle / 2, clockwise: true)
        outlinePath.addArc(withCenter: arcCenter, radius: bounds.height, startAngle: (3 * .pi / 2) + optionsAngle / 2, endAngle: (3 * .pi / 2) - optionsAngle / 2, clockwise: false)
        
        outlinePath.close()
        
        outlinePath.addClip()

        let colors = [gradientColorOne.cgColor, gradientColorTwo.cgColor, gradientColorOne.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.25, 0.5, 0.75]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as! CFArray, locations: colorLocations)!
        
        let startPoint = CGPoint(x: bounds.minX, y: bounds.midY)
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.midY)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }
}
