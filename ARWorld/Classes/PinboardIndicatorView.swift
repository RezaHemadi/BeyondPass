//
//  PinboardIndicatorView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/22/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class PinboardIndicatorView: UIView {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        UIColor(red: 39/255, green: 63/255, blue: 70/255, alpha: 1.0).setFill()
        
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.close()
        path.fill()
    }
    

}
