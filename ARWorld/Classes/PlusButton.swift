//
//  PlusButton.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/17/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class PlusButton: UIButton {
    // MARK: - Configuration
    let color = UIColor(red: 86/255.0, green: 193/255.0, blue: 44/255.0, alpha: 0.8)
    let lineWidth: CGFloat = 3
    
    // MARK: Properties
    
    var interfaceHidden: Bool = false
    
    // Mark: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        transform = CGAffineTransform.init(scaleX: 0, y: 0)
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        color.setStroke()
        path.lineWidth = lineWidth
        
        let middleLeft = CGPoint(x: bounds.minX, y: bounds.midY)
        let middleRight = CGPoint(x: bounds.maxX, y: bounds.midY)
        let middleTop = CGPoint(x: bounds.midX, y: bounds.minY)
        let middleBottom = CGPoint(x: bounds.midX, y: bounds.maxY)
        
        path.move(to: middleLeft)
        path.addLine(to: middleRight)
        path.move(to: middleTop)
        path.addLine(to: middleBottom)
        
        path.lineCapStyle = .round
        
        path.stroke()
    }
}
