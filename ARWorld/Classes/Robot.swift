//
//  Robot.swift
//  ARWorld
//
//  Created by Reza Hemadi on 2/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import AVFoundation
import ARKit

class Robot: NSObject {
    
    // MARK: - Properties
    var node = SCNNode()
    
    var eye: SCNNode
    
    var isAdded: Bool = false {
        didSet {
            if isAdded {
                // Play Drone sound
                let soundURL = Bundle.main.url(forResource: "SpherySound", withExtension: "wav", subdirectory: "art.scnassets/Robot")!
                let audioSource = SCNAudioSource(url: soundURL)!
                audioSource.load()
                audioSource.loops = true
                audioSource.volume = 0.03
                let soundAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
                self.node.runAction(soundAction)
            }
        }
    }
    
    var greeting = [AVSpeechUtterance]()
    
    var anchor: ARAnchor?

    var synthesizer = AVSpeechSynthesizer()
    
    var player: SCNAudioPlayer!
    
    var hints = [AVSpeechUtterance]()
    
    var utterQueue: [AVSpeechUtterance] = []
    
    var randomDialouges: [String] = ["If you are inside a building you can call AR table by touching top left blue button",
                                     "If you are outside the building you can select the ar table of venue by tapping the ARTable",
                                     "If a person follow you you will receive 50 AR Coin",
                                     "By following each user you will receive  10 AR coin my master",
                                     "my master, have you seen sky writings in the sky?Sky-writing is possible only if you are outdoor"]
    
    // MARK: - Initialization
    
    override init() {
        
        let url = Bundle.main.url(forResource: "SpheryCopter", withExtension: "scn", subdirectory: "art.scnassets/Robot")!
        let referenceNode = SCNReferenceNode(url: url)!
        
        referenceNode.load()
            
        referenceNode.adjustPivot(to: .center)
        referenceNode.scale = SCNVector3Make(0.3, 0.3, 0.3)
        referenceNode.eulerAngles = SCNVector3Make(-.pi / 2, .pi, 0)
        self.node.addChildNode(referenceNode)
        
        eye = node.childNode(withName: "Eye", recursively: true)!
        eye.geometry?.firstMaterial?.shininess = 100
            
        let bladeNames = ["Blade00", "Blade01", "Blade02", "Blade03"]
        var blades: [SCNNode] = []
        for bladeName in bladeNames {
            let node = referenceNode.childNode(withName: bladeName, recursively: true)!
            blades.append(node)
        }
            
        for blade in blades {
            let (min, max) = blade.boundingBox
            let x = min.x + 0.5 * (max.x - min.x)
            let y = min.y + 0.5 * (max.y - min.y)
            let z = min.z + 0.5 * (max.z - min.z)
            
            let center = SCNVector3Make(x, y, z)
                
            blade.pivot = SCNMatrix4MakeTranslation(x, y, z)
            blade.position = center
                
            let rotationAction = SCNAction.rotate(by: 2 * .pi, around: SCNVector3Make(0, 0, 1), duration: 0.25)
            let action = SCNAction.repeatForever(rotationAction)
            blade.runAction(action)
        }
            
        self.node.name = "SphericalRobot"
        self.node.categoryBitMask = NodeCategories.drone.rawValue
        
        
        
        
            
            
        self.greeting.append(AVSpeechUtterance.init(string: "Hi my master. I’m you servant in AR world"))
        self.greeting.append(AVSpeechUtterance.init(string: "Welcome to AR world!"))
        self.greeting.append(AVSpeechUtterance.init(string: "Are you ready for an adventure? Let's explore the world."))
            
        for dialouge in self.randomDialouges {
            
            self.hints.append(AVSpeechUtterance.init(string: dialouge))
        }
        
        super.init()
    }
    
    // MARK: - Speech
    
    func setupSound () {
        
        let source = SCNAudioSource.init()
        self.player = SCNAudioPlayer(source: source)
        self.node.addAudioPlayer(self.player)
        
        for greeting in self.greeting {
            
            greeting.preUtteranceDelay = TimeInterval.init(2)
            greeting.rate = 0.4
            greeting.pitchMultiplier = 1
            greeting.volume = 0.75
        }
    }
    
    func utter(_ utterance: [AVSpeechUtterance]) {
        for i in utterance {
            DispatchQueue.main.async {
                self.synthesizer.speak(i)
            }
        }
    }
    
    func greet() {
        
        let audioSource = SCNAudioSource(fileNamed: "art.scnassets/Robot/DroneWelcomeSound.wav")!
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        
        self.node.addAudioPlayer(audioPlayer)
        
        for greet in self.greeting {
            
            self.synthesizer.speak(greet)
        }
    }
    
    func follow(position: SCNVector3) {
        /*
        let animation = CABasicAnimation(keyPath: "position")
        animation.toValue = SCNVector3.init(position.x + self.initPosition.x, position.y + self.initPosition.y, position.z + self.initPosition.z)
        animation.duration = 2.0
        animation.autoreverses = true
        self.node.addAnimation(animation, forKey: nil)
 */
    }
    
    func stop() {
        
        self.node.removeAllAnimations()
    }
    
    func playSound() {
        
        let audioSource = SCNAudioSource(fileNamed: "art.scnassets/Robot/DroneTouch.wav")!
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        
        audioPlayer.didFinishPlayback = hint
        
        self.node.addAudioPlayer(audioPlayer)
    }
    
    func beep(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let audioSource = SCNAudioSource(fileNamed: "art.scnassets/Robot/DroneTouch.wav")!
            let audioPlayer = SCNAudioPlayer(source: audioSource)
            audioPlayer.didFinishPlayback = completion
            self.node.addAudioPlayer(audioPlayer)
        }
    }
    
    func hint() {
        
        let totalHints = self.hints.count
        let index = arc4random_uniform(UInt32(totalHints))
        self.synthesizer.speak(self.hints[Int(index)])
    }
    
    // MARK: - Actions
    func alarmed() {
        eye.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        eye.geometry?.firstMaterial?.selfIllumination.contents = UIColor.red
        eye.geometry?.firstMaterial?.lightingModel = .physicallyBased
    }
    
    func unAlarmed() {
        eye.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        eye.geometry?.firstMaterial?.specular.contents = UIColor.white
        eye.geometry?.firstMaterial?.emission.intensity = 1
        eye.geometry?.firstMaterial?.lightingModel = .physicallyBased
    }
    
    func lookAtPosition(_ position: float3, animationDuration: Double = 2, completion: @escaping () -> Void) {
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2
        
        let normalizedDirection = simd_normalize(position)
        
        let teta = acos(simd_dot(float3(normalizedDirection.x, 0, normalizedDirection.z), float3(0, 0, 1)))
        if normalizedDirection.x < 0 {
            node.simdEulerAngles += float3(0, -teta, 0)
        } else {
            node.simdEulerAngles += float3(0, teta, 0)
        }
        
        let projectedToYPlane = float3(normalizedDirection.x, 0,
                                       normalizedDirection.z)
        let normalizedProjectedToYPlane = simd_normalize(projectedToYPlane)
        
        let tilt = acos(simd_dot(normalizedDirection, normalizedProjectedToYPlane))
        
        if normalizedDirection.y < 0 {
            node.simdEulerAngles += float3(tilt, 0, 0)
        } else {
            node.simdEulerAngles += float3(-tilt, 0, 0)
        }
        
        SCNTransaction.completionBlock = {
            completion()
        }
        
        SCNTransaction.commit()
    }
    
    func move(to position: float3, speed: Float = 0.5, completion: @escaping (_ succeed: Bool?) -> Void) {
        let currentPosition = node.presentation.simdPosition
        let travelDistance = distance(from: currentPosition, to: position)
        let animationTime: Double = Double(travelDistance / speed)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animationTime
        
        SCNTransaction.completionBlock = { completion(true) }
        
        node.simdPosition = position
        
        SCNTransaction.commit()
    }
    
    // MARK: - Helper Methods
    
    private func distance(from: float3, to: float3) -> Float {
        return simd_length(to - from)
    }
}
extension Robot: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
    }
}
