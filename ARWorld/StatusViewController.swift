//
//  StatusViewController.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/6/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import UIKit
import ARKit

class StatusViewController: UIViewController {
    // MARK: - Interface Outlets
    
    @IBOutlet var label: UILabel!
    
    // MARK: - Types
    
    enum MessageType {
        case trackingStateEscalation
        case planeEstimation
        case contentPlacement
        case focusSquare
        case appMode
        
        static var all: [MessageType] = [
            .trackingStateEscalation,
            .planeEstimation
        ]
    }
    
    // MARK: - Properties
    
    /// Seconds before the timer message should fade out. Adjust if the app needs longer transient messages.
    private let displayDuration: TimeInterval = 6
    
    /// Timer for hiding messages
    private var messageHideTimer: Timer?
    
    private var timers: [MessageType: Timer] = [:]
    
    /// String to hold persistent messages
    private var persistentMessage: String?
    
    var delegate: StatusViewControllerDelegate?
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.isUserInteractionEnabled = true
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        
        label.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        label.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - Message Handling
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        // Cancel any previous hide timer.
        messageHideTimer?.invalidate()
        
        DispatchQueue.main.async {
            self.label.text = text
        }
        
        // Make sure status is showing.
        setMessageHidden(false, animated: true)
        
        if autoHide {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false, block: { [weak self] _ in
                
                DispatchQueue.main.async {
                    // check if there's a persistent message
                    if self?.persistentMessage != nil {
                        self?.label.text = self?.persistentMessage
                    } else {
                        self?.setMessageHidden(true, animated: true)
                    }
                }
            })
        } else {
            // It is a persistent message
            persistentMessage = text
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] timer in
            self?.showMessage(text)
            timer.invalidate()
        })
        
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(`for` messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessages() {
        for messageType in MessageType.all {
            cancelScheduledMessage(for: messageType)
        }
    }
    
    // MARK: - Label Visibility
    
    private func setMessageHidden(_ hide: Bool, animated: Bool) {
        // The label starts out hidden, so show it before animating opacity.
        DispatchQueue.main.async {
            self.label.isHidden = false
        }
        
        guard animated else {
            label.alpha = hide ? 0 : 1
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
            DispatchQueue.main.async {
                self.label.alpha = hide ? 0 : 1
            }
        }, completion: nil)
    }
    
    // MARK: - ARKit
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [unowned self] _ in
            self.cancelScheduledMessage(for: .trackingStateEscalation)
            
            var message = trackingState.presentationString
            if let recommendation = trackingState.recommendation {
                message.append(": \(recommendation)")
            }
            
            self.showMessage(message, autoHide: true)
        })
        
        timers[.trackingStateEscalation] = timer
    }
    
    // MARK: - Gesture Recognizer Handlers
    
    @objc func labelTapped() {
        delegate?.statusViewController(self, labelTapped: label.text)
        persistentMessage = nil
        setMessageHidden(true, animated: true)
    }
    
    func hide() {
        persistentMessage = nil
        setMessageHidden(true, animated: true)
    }
    
    func setBackgroundColor(_ color: UIColor) {
        DispatchQueue.main.async {
            self.label.backgroundColor = color
        }
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(.excessiveMotion):
            return "TRACKING LIMITED - Excessive motion"
        case .limited(.insufficientFeatures):
            return "TRACKING LIMITED - Low detail"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.relocalizing):
            return "Recovering from interruption"
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        case .limited(.relocalizing):
            return "Return to the location where you left off or try resetting the session."
        default:
            return nil
        }
    }
}
