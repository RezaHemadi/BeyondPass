//
//  ARGiftTableViewCellDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/12/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol ARGiftTableViewCellDelegate {
    func arGiftTableViewCell(_ cell: ARGiftTableViewCell, didChangeGiftingAmount amount: Int)
}
