//
//  removeSpecialCharacters.swift
//  ARWorld
//
//  Created by Reza Hemadi on 1/29/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

func removeSpecialCharsFromString(text: String) -> String {
    let okayChars =
        String("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
    return String(text.filter {okayChars.contains($0) })
}
