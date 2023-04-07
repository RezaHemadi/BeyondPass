//
//  UIColorPickerView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class UIColorPickerView: UIView {
    
    var color: UIColor = UIColor.yellow
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        let tempRect = bounds.insetBy(dx: 5, dy: 5)
        
        let path = UIBezierPath()
        let center = CGPoint.init(x: bounds.width / 2, y: bounds.height / 2)
        path.addArc(withCenter: center, radius: tempRect.width / 2, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        color.setFill()
        path.fill()
        UIColor.white.setStroke()
        path.lineWidth = 3.0
        path.stroke()
    }
    

}
