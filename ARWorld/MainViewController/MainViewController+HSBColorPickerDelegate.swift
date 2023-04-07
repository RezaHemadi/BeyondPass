//
//  MainViewController+HSBColorPickerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension MainViewController: HSBColorPickerDelegate {
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        colorPicker.color = color
        colorPicker.setNeedsDisplay()
    }
}
