//
//  Dock.swift
//  ARWorld
//
//  Created by Reza Hemadi on 3/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class Dock: UIImageView {
    
    let scrollView = UIScrollView()
    let collapsedX: CGFloat = -30
    let expandedX: CGFloat = 0
    let hiddenX: CGFloat = -50
    private let buttonsXOffset: CGFloat = 2
    var moving: Bool! = false
    var constraint: NSLayoutConstraint?
    var buttons = [UIButton]()
    var state: State = .collapsed
    var delegate: DockDelegate?
    
    enum State {
        case expanded
        case collapsed
        case hidden
    }
    
    private var buttonOffset: Double = 0
    
    init() {
        super.init(image: UIImage(named: "MainDock")!)
        
        isUserInteractionEnabled = true
        addScrollView()
        addProfilePicButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addScrollView() {
        
        let height = frame.height
        scrollView.frame = CGRect(x: 0, y: 30, width: 45, height: height - 58)
        //scrollView.contentSize = CGSize(width: 45, height: height - 88)
        self.addSubview(scrollView)
        
        // Add scrollView Buttons
        addButtonToScrollView(icon: UIImage(named: "ARPortal")!, action: #selector(MainViewController.arPortalTapped))
        addButtonToScrollView(icon: UIImage(named: "SandBox")!, action: #selector(MainViewController.sandboxTapped(sender:)))
        addButtonToScrollView(icon: UIImage(named: "PersonalPinBoardIcon")!, action: #selector(MainViewController.personalPinboardIconTapped))
        addButtonToScrollView(icon: UIImage(named: "Backpack")!, action: #selector(MainViewController.chestTapped(sender:)))
        addButtonToScrollView(icon: UIImage(named: "Chest")!, action: #selector(MainViewController.treasureIconTapped))
        addButtonToScrollView(icon: UIImage(named: "InAppPurchases")!, action: #selector(MainViewController.mainStoreButtonTapped))
        addButtonToScrollView(icon: UIImage(named: "Credits")!, action: #selector(MainViewController.creditsTapped))
        //addButtonToScrollView(icon: UIImage(named: "Games")!)
        //addButtonToScrollView(icon: UIImage(named: "Stories")!)
    }
    
    func addProfilePicButton() {
        
        let button = UIButton()
        button.setImage(UIImage(named: "ProfilePic")!, for: .normal)
        button.frame = CGRect(x: buttonsXOffset, y: frame.height - 60, width: 30, height: 30)
        
        // Add action for the button
        button.addTarget(nil, action: #selector(MainViewController.showMyProfile(sender:)), for: .touchDown)
        
        self.addSubview(button)
    }
    
    private func addButtonToScrollView(icon: UIImage, action: Selector? = nil) {
        
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.frame = CGRect(x: Double(buttonsXOffset), y: buttonOffset, width: 30, height: 30)
        buttonOffset += 40
        scrollView.addSubview(button)
        
        // Add action for the button
        if let action = action {
            button.addTarget(nil, action: action, for: .touchUpInside)
        }
        
        self.buttons.append(button)
    }
    
    func expand() {
        
        guard state != .expanded && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        
                        switch self.state {
                        case .collapsed:
                            self.transform = CGAffineTransform.init(translationX: 30, y: 0)
                        case .hidden:
                            self.transform = CGAffineTransform.init(translationX: 50, y: 0)
                        default:
                            return
                        }
                        
                        self.moving = true
                    }, completion: {
                        (succeed) in
                        self.moving = false
                        self.state = .expanded
                        self.isUserInteractionEnabled = true
                        self.delegate?.dock(self, didExpande: true)
                    })
    }
    
    func collapse() {
        
        guard state != .collapsed && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.transform = CGAffineTransform.identity
                        self.moving = true
                    }, completion: {
                        (succeed) in
                        self.moving = false
                        self.state = .collapsed
                        self.isUserInteractionEnabled = true
                        self.delegate?.dock(self, didCollapse: true)
                    })
    }
    
    func hide() {
        
        guard state != .hidden && !moving else { return }
        
        isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        
                        switch self.state {
                        case .collapsed:
                            self.transform = CGAffineTransform.init(translationX: -20, y: 0)
                        case .expanded:
                            self.transform = CGAffineTransform.init(translationX: -50, y: 0)
                        default:
                            return
                        }
                        self.moving = true
        }, completion: {
            (succeed) in
            self.moving = false
            self.state = .hidden
            self.isUserInteractionEnabled = true
            self.delegate?.dock(self, didHide: true)
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
    
    @objc func swipedLeft(sender: UISwipeGestureRecognizer) {
        collapse()
    }
}
protocol DockDelegate {
    func dock(_ dock: Dock, didCollapse: Bool)
    func dock(_ dock: Dock, didExpande: Bool)
    func dock(_ dock: Dock, didHide: Bool)
}
