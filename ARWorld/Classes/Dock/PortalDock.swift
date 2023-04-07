//
//  PortalDock.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/4/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class PortalDock: OptionsDock {
    // MARK: - Types
    
    enum Option {
        case decoration
        case treasure
        
        var image: UIImage {
            get {
                switch self {
                case .decoration:
                    return UIImage(named: "DecorationMode")!
                case .treasure:
                    return UIImage(named: "Chest")!
                }
            }
        }
        static var all: [Option] {
            get {
                return [.decoration, .treasure]
            }
        }
    }
    
    // MARK: - Configuration
    
    let icon = UIImage(named: "ARPortal")!
    
    // MARK: - Properties
    
    var options = Option.all
    
    var portalDockDelegate: PortalDockDelegate?
    
    // MARK: Initialization
    
    init() {
        super.init(icon: icon)
        
        for option in options {
            let (button, _) = addButtonToScrollView(icon: option.image)
            button.addTarget(self, action: #selector(optionTapped(sender:)), for: .touchUpInside)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: User Interaction
    
    @objc func optionTapped(sender: UIButton) {
        if let index = buttons.index(of: sender) {
            let selectedOption = options[index]
            portalDockDelegate?.portalDock(self, didSelect: selectedOption)
        }
    }
}

protocol PortalDockDelegate {
    func portalDock(_ dock: PortalDock, didSelect option: PortalDock.Option)
}
