//
//  OptionsDock.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/5/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class OptionsDock: UIImageView {
    
    var scrollView: UIScrollView!
    let collapsedX: CGFloat = 30
    let expandedX: CGFloat = 0
    let hiddenX: CGFloat = 50
    var moving: Bool! = false
    var constraint: NSLayoutConstraint?
    var buttons = [UIButton]()
    var state: State = .expanded
    var iconView: UIImageView!
    
    enum State {
        case expanded
        case collapsed
        case hidden
    }
    
    private var buttonOffset: Double = 0
    
    var delegate: OptionsDockDelegate?
    
    init(icon: UIImage) {
        super.init(image: UIImage(named: "RightDock")!)
        
        self.isUserInteractionEnabled = true
        addScrollView()
        addMainIcon(icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addMainIcon(_ icon: UIImage) {
        
        iconView = UIImageView(image: icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(iconView)
        
        let heightConstraint = NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        let widthConstraint = NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        let topConstraint = NSLayoutConstraint(item: iconView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let centerHorizontallyConstraint = NSLayoutConstraint(item: iconView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        
        self.addConstraints([topConstraint, centerHorizontallyConstraint])
        iconView.addConstraints([heightConstraint, widthConstraint])
        
    }
    
    func addScrollView() {
        scrollView = UIScrollView()
        scrollView.isUserInteractionEnabled = true
        scrollView.isScrollEnabled = true
        
        let height = frame.height
        scrollView.frame = CGRect(x: 13, y: 50, width: frame.width - 17, height: height - 70)
        //scrollView.contentSize = CGSize(width: frame.width, height: 500)
        //scrollView.backgroundColor = UIColor.red
        
        self.addSubview(scrollView)
    }
    
    @discardableResult
    
    func addButtonToScrollView(icon: UIImage, count: Int! = nil)  -> (UIButton, UILabel?) {
        
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.frame = CGRect(x: 0, y: buttonOffset, width: 30, height: 30)
        buttonOffset += 40
        scrollView.addSubview(button)
        
        // Adjust the content size of the scroll view
        let contentHeight = CGFloat(buttonOffset + 30)
        scrollView.contentSize = CGSize(width: frame.width - 17, height: contentHeight)
        
        self.buttons.append(button)
        
        // Add badge number
        guard let count = count else { return (button, nil) }
        
        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(badgeLabel)
        badgeLabel.font = UIFont(name: "HelvetivaNeue", size: 1)
        badgeLabel.textColor = UIColor.white
        badgeLabel.text = String(count)
        badgeLabel.adjustsFontSizeToFitWidth = true
        
        let bottomConstraint = NSLayoutConstraint(item: badgeLabel, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1, constant: 6)
        let centerHorizontallyConstraint = NSLayoutConstraint(item: badgeLabel, attribute: .centerX, relatedBy: .equal, toItem: button, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: badgeLabel, attribute: .width, relatedBy: .equal, toItem: button, attribute: .width, multiplier: 0.4, constant: 0)
        
        scrollView.addConstraints([bottomConstraint, centerHorizontallyConstraint, widthConstraint])
        
        return (button, badgeLabel)
    }
    
    func expand() {
        
        guard state != .expanded && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.transform = CGAffineTransform.identity
                        self.moving = true
        }, completion: {
            (succeed) in
            self.moving = false
            self.state = .expanded
            self.isUserInteractionEnabled = true
            //self.constraint?.constant = self.expandedX
            self.delegate?.dockDidExpand(self)
        })
    }
    
    func collapse() {
        
        guard state != .collapsed && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.transform = CGAffineTransform.init(translationX: 30, y: 0)
                        self.moving = true
        }, completion: {
            (succeed) in
            self.moving = false
            self.state = .collapsed
            self.isUserInteractionEnabled = true
            //self.constraint?.constant = self.collapsedX
            self.delegate?.dockDidCollapse(self)
        })
    }
    
    func hide() {
        
        guard state != .hidden && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.transform = CGAffineTransform.init(translationX: 50, y: 0)
                        self.moving = true
        }, completion: {
            (succeed) in
            self.moving = false
            self.state = .hidden
            self.isUserInteractionEnabled = true
            self.constraint?.constant = self.hiddenX
        })
    }
    
    @objc func dockPanned(sender: UIScreenEdgePanGestureRecognizer) {
        switch state {
            
        case .collapsed:
            
            expand()
        case .expanded:
            
            collapse()
        default:
            return
        }
    }
    
    @objc func swipedRight(sender: UISwipeGestureRecognizer) {
        collapse()
    }
    
    func drawSeperatorLines() {
        
        let count = buttons.count - 1
        
        guard count > 0, let scrollView = self.scrollView else { return }
        
        var yTranslation: CGFloat = 35
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 2))
        let img1 = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(1)
                
            ctx.cgContext.move(to: CGPoint(x: 0, y: 1))
            ctx.cgContext.addLine(to: CGPoint(x: 30, y: 1))
            
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        
        // Add the line to scroll view count times
        for _ in 1 ... count {
            
            let imageView = UIImageView(image: img1)
            imageView.frame = CGRect(x: 0, y: yTranslation, width: 30, height: 2)
            scrollView.addSubview(imageView)
            
            yTranslation += 40
        }
    }
}
