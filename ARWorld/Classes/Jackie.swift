//
//  Jackie.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension Story {
    class Jackie: NSObject, Character, CAAnimationDelegate {
        
        var model: SCNNode
        
        private var hips: SCNNode
        
        private var animations: [CAAnimation] = []
        
        private var animationKeys: [String] = ["SwingToLand", "Standing", "Talking"]
        
        private var animationTranslations: [float3] = [float3(10, 0, 380), float3(0, 0, 0)]
        
        private var root: SCNNode
        
        var isActive: Bool = false
        
        var delegate: JackieDelegate?
        
        
        
        override init() {
            let url = Bundle.main.url(forResource: "Standing", withExtension: "scn", subdirectory: "art.scnassets/Story/Jackie")!
            let sceneSource = SCNSceneSource(url: url, options: nil)!
            let scene = try! sceneSource.scene(options: nil)
            
            model = SCNNode()
            
            for childNode in scene.rootNode.childNodes {
                model.addChildNode(childNode)
            }
            
            hips = model.childNode(withName: "Hips", recursively: true)!
            root = model.childNode(withName: "root", recursively: true)!
            
            /*
            let (min, max) = model.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y
            let dz = max.z
            
            model.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            */
            model.scale = SCNVector3Make(0.014, 0.014, 0.014)
            
            super.init()
            
            for key in animationKeys {
                let animationURL = Bundle.main.url(forResource: key, withExtension: "scnanim", subdirectory: "art.scnassets/Story/Jackie")!
                let animation = SCNAnimation(contentsOf: animationURL)
                let caAnimation = CAAnimation(scnAnimation: animation)
                if key == "Talking" {
                    caAnimation.repeatCount = .infinity
                } else {
                    caAnimation.repeatCount = 1
                }
                caAnimation.fillMode = CAMediaTimingFillMode.forwards
                caAnimation.delegate = self

                animations.append(caAnimation)
            }

        }
        func swingToLand() {
            hips.addAnimation(animations[0], forKey: animationKeys[0])
        }
        
        func activate() {
            print("jackie activated")
            swingToLand()
            isActive = true
        }
        
        func elettraIntroSpeechCompleted() {
            delegate?.elettra(self, completedIntroSpeech: true)
        }
        
        func animationDidStart(_ anim: CAAnimation) {
            let index = animations.index(of: anim)!
            let duration = anim.duration
            let when = DispatchTime.now() + duration - 0.5
            
            switch index {
            case 1:
                // Elettra began standing up
                delegate?.elettra(self, didBeginStanding: true)
            case 2:
                // Start talking
                let audioURL = Bundle.main.url(forResource: "Elettra_intro", withExtension: "wav", subdirectory: "art.scnassets/Story/Jackie")!
                let audioSource = SCNAudioSource(url: audioURL)!
                DispatchQueue.global(qos: .default).async {
                    audioSource.load()
                    let audioPlayer = SCNAudioPlayer.init(source: audioSource)
                    audioPlayer.didFinishPlayback = self.elettraIntroSpeechCompleted
                    self.model.addAudioPlayer(audioPlayer)
                }
            default:
                break
            }
            
            DispatchQueue.main.asyncAfter(deadline: when) {
                if self.animationTranslations.indices.contains(index) {
                    self.root.simdPosition = self.root.simdPosition + self.animationTranslations[index]
                }
                if self.animations.indices.contains(index + 1) {
                    self.hips.addAnimation(self.animations[index + 1], forKey: self.animationKeys[index + 1])
                }
                if self.animations.indices.contains(index + 1) {
                    self.hips.removeAnimation(forKey: self.animationKeys[index], blendOutDuration: 0.5)
                }
            }
        }
        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            /*
            let index = animations.index(of: anim)!
            if animations.indices.contains(index + 1) {
                /*
                let dz = (hips.simdTransform.translation.z - hips.presentation.simdTransform.translation.z)
                root.simdPosition = root.simdPosition + float3(0, 0, -dz)
 */
                root.simdPosition = root.simdPosition + animationTranslations[index]
                hips.addAnimation(animations[index + 1], forKey: animationKeys[index + 1])
 
            } */
        }
    }
}
protocol JackieDelegate {
    func elettra(_ elettra: Story.Jackie, completedIntroSpeech: Bool)
    func elettra(_ elettra: Story.Jackie, didBeginStanding: Bool)
}
