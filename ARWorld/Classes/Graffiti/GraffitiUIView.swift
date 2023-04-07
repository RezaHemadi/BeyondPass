//
//  GraffitiUIView.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit

class GraffitiUIView: UIView {
    
    var delegate: GraffitiUIDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        UIColor.red.withAlphaComponent(0.8).setFill()
        let center: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: bounds.width, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.fill()
    } */
    
    // MARK: - Touch Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("Touch began")
            delegate?.graffitiUI(self, didBeginTouch: true)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            delegate?.graffitiUI(self, didContinueSpraying: true)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("Touch ended")
            delegate?.graffitiUI(self, didFinishSpraying: true)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("Touch ended")
            delegate?.graffitiUI(self, didFinishSpraying: true)
        }
    }
}

protocol GraffitiUIDelegate {
    func graffitiUI(_ graffitiUI: GraffitiUIView, didBeginTouch: Bool)
    func graffitiUI(_ graffitiUI: GraffitiUIView, didContinueSpraying: Bool)
    func graffitiUI(_ graffitiUI: GraffitiUIView, didFinishSpraying: Bool)
}
