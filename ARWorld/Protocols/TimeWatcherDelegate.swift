//
//  TimeWatcherDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/2/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol TimeWatcherDelegate {
    func timeWatcherShouldTrigger(_ timeWatcher: TimeWatcher, at time: TimeInterval)
}
