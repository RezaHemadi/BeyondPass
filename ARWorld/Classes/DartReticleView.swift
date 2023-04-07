//
//  DartReticleView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class DartReticleView: UIButton {
    
    // MARK: - Configuration
    
    let outerCircleColor = UIColor(red: 132/255.0, green: 126/255.0, blue: 125/255.0, alpha: 1)
    let innerCircleColor = UIColor(red: 204/255.0, green: 101/255.0, blue: 87/255.0, alpha: 0.7)
    let outerCircleLineWidth: CGFloat = 5
    let innerCircleRatio: CGFloat = 0.7
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let outerRect = rect.insetBy(dx: outerCircleLineWidth / 2, dy: outerCircleLineWidth / 2)
        let path1 = UIBezierPath(roundedRect: outerRect, cornerRadius: outerRect.width / 2)
        outerCircleColor.setStroke()
        path1.lineWidth = 3
        path1.stroke()
        
        let innerRect = rect.insetBy(dx: (1 - innerCircleRatio) * rect.width / 2, dy: (1 - innerCircleRatio) * rect.width / 2)
        let path2 = UIBezierPath(roundedRect: innerRect, cornerRadius: innerRect.width / 2)
        innerCircleColor.setFill()
        path2.fill()
    }

}
