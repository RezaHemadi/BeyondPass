//
//  AddToReality.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/17/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class AddToReality: UIView {
    
    // MARK: - Configuration
    let addToRealityColor = UIColor(red: 218/255.0, green: 225/255.0, blue: 239/255.0, alpha: 0.9)

    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width / 2)
        path.addClip()
        
        UIImage(named: "Polished_Silver")!.draw(in: rect, blendMode: .normal, alpha: 0.6)
        
        
        // Draw Add to reality
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                          NSAttributedString.Key.font            :   UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.foregroundColor : addToRealityColor,
                          ]
        
        let myText = "Add to Reality"
        let attrString = NSAttributedString(string: myText,
                                            attributes: attributes)
        
        
        attrString.draw(in: rect.offsetBy(dx: 0, dy: rect.width / 5.2))
    }

}
