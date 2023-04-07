//
//  HintsController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class HintsController {
    
    // MARK: - Types
    
    enum Tracker {
        case mainView
        case openLeftDock
    }
    
    enum Hint: String {
        case swipe
    }
    
    // MARK: - Properties
    
    lazy var swipeHintImageView = UIImageView(image: UIImage(named: "swipe_hint")!)
    
    var displayedHint: UIImageView?
    
    var tracker: Tracker? {
        didSet {
            switch tracker! {
            case .mainView:
                if !swipe {
                    delegate?.hintsController(self, showHint: swipeHintImageView)
                    swipe = true
                    UserDefaults.standard.set(true, forKey: Hint.swipe.rawValue)
                    hintDisplayed = true
                }
            case .openLeftDock:
                if hintDisplayed {
                    delegate?.hintsController(self, removeHint: swipeHintImageView)
                    hintDisplayed = false
                }
            }
        }
    }
    
    var swipe: Bool = false // If true the hint is shown before
    
    var hintDisplayed: Bool = false
    
    var delegate: HintsControllerDelegate?
    
    init() {
        swipe = UserDefaults.standard.bool(forKey: Hint.swipe.rawValue)
    }
}
extension HintsController {
    static private var singleton: HintsController = HintsController()
    
    static func sharedInstance() -> HintsController {
        return singleton
    }
}
protocol HintsControllerDelegate {
    func hintsController(_ controller: HintsController, showHint: UIImageView)
    func hintsController(_ controller: HintsController, removeHint: UIImageView)
}
