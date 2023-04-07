//
//  SprayCan.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class SprayCan: SCNReferenceNode {
    
    // MARK: - Types
    
    enum State {
        case holstered
        case equipped
    }
    
    // MARK: - Properties
    
    var color: UIColor = UIColor.yellow {
        didSet {
            self.colorMaterial?.diffuse.contents = color
        }
    }
    
    var animating: Bool = false
    
    var isAdded: Bool = false
    
    var state: State = .holstered
    
    var colorMaterial: SCNMaterial?
    
    private let sprayAudioURL = Bundle.main.url(forResource: "Spray", withExtension: "wav", subdirectory: "art.scnassets")!
    
    private let sprayShakeURL = Bundle.main.url(forResource: "SprayShake", withExtension: "wav", subdirectory: "art.scnassets")!
    
    var sprayAudioSource: SCNAudioSource
    
    var sprayShakeAudioSource: SCNAudioSource
    
    var isSpraySoundPlaying: Bool = false
    
    // MARK: - Initialization
    
    init() {
        let url = Bundle.main.url(forResource: "Spraycan2", withExtension: "scn", subdirectory: "art.scnassets")!
        sprayAudioSource = SCNAudioSource(url: sprayAudioURL)!
        sprayShakeAudioSource = SCNAudioSource(url: sprayShakeURL)!
        super.init(url: url)!
        isHidden = false
        scale = SCNVector3Make(0.6, 0.6, 0.6)
        eulerAngles = SCNVector3Make(0, .pi, .pi / 8)
        position = SCNVector3Make(0.026, -0.53, -0.5)
        loadingPolicy = .onDemand
        
        DispatchQueue.global(qos: .background).async {
            self.load()
            self.sprayAudioSource.load()
            self.sprayShakeAudioSource.load()
            
            let colorNode = self.childNode(withName: "SkinColor", recursively: true)!
            self.colorMaterial = colorNode.geometry?.materials.first
            self.colorMaterial?.diffuse.contents = self.color
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func holster() {
        DispatchQueue.main.async {
            self.state = .holstered
            self.animating = true
            let action = SCNAction.move(by: SCNVector3Make(0, -0.3, 0), duration: 0.3)
            self.runAction(action) {
                self.animating = false
            }
        }
    }
    
    func equip() {
        DispatchQueue.main.async {
            self.state = .equipped
            self.animating = true
            let action = SCNAction.move(by: SCNVector3Make(0, +0.3, 0), duration: 0.3)
            self.runAction(action) {
                self.animating = false
            }
        }
    }
    
    func playShakeSound() {
        let action = SCNAction.playAudio(sprayShakeAudioSource, waitForCompletion: true)
        runAction(action)
    }
    
    func playSpraySound() {
        guard !isSpraySoundPlaying else { return }
        
        isSpraySoundPlaying = true
        let action = SCNAction.playAudio(sprayAudioSource, waitForCompletion: true)
        runAction(action) {
            self.isSpraySoundPlaying = false
        }
    }
}
