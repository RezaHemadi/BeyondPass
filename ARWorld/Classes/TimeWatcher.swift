//
//  TimeWatcher.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class TimeWatcher {
    
    // MARK: - Types
    enum Mode {
        case sandbox
    }
    
    // MARK: - Properties
    var currentTime: TimeInterval {
        didSet {
            // check if newValue is 1 ms greater than oldValue else return
            guard (currentTime - oldValue) > 0.001 else { return }
            
            // check if the delegate should fire
            if let lastTrigger = self.lastTriggerTime {
                // round currentTime
                let currentTimeRounded = round(currentTime * 1000) / 1000
                let timePassed = currentTimeRounded - lastTrigger
                
                if timePassed >= timeInterval {
                    delegate?.timeWatcherShouldTrigger(self, at: currentTime)
                    self.lastTriggerTime = currentTimeRounded
                }
            } else {
                // timer is triggering for the first time
                let timePassed = currentTime - initialTime
                let timePassedRounded = round(timePassed * 1000) / 1000
                
                if (timePassedRounded >= timeInterval) {
                    delegate?.timeWatcherShouldTrigger(self, at: currentTime)
                    lastTriggerTime = timePassedRounded
                }
            }
        }
    }
    
    var initialTime: TimeInterval
    
    private var timeInterval: Double
    
    private var lastTriggerTime: TimeInterval?
    
    var delegate: TimeWatcherDelegate?
    
    var tag: Int?
    
    // MARK: - Initializers
    init(type: Mode, initialTime: TimeInterval) {
        self.initialTime = initialTime
        self.currentTime = initialTime
        
        switch type {
        case .sandbox:
            self.timeInterval = (round(1 / SANDBOX_CLEANUP_REFRESH_RATE) * 1000) / 1000
        }
    }
    
    // MARK: - Helper Methods
    func updateTime(with time: TimeInterval) {
        currentTime = time
    }
}
