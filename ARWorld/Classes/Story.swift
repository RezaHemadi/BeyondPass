//
//  Story.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/8/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import AVFoundation
import ARKit

class Story: NSObject {
    
    // MARK: - Directional Planes
    
    struct DirectionalPlane {
        var plane: SurfacePlane
        var yaw: Float
    }
    
    // MARK: - Properties
    
    var level: Int = 1
    
    var delegate: StoryDelegate?
    
    var jackie: Jackie = Jackie()
    
    var portal: SCNNode?
    
    var levelOneUtterances: [AVSpeechUtterance] = []
    var levelOneUtteranceDelays: [TimeInterval] = [1, 1, 1, 1]
    
    var synthesizer = AVSpeechSynthesizer()
    
    var callBackUtterance: AVSpeechUtterance?
    
    var activeDirectionalPlanes: [DirectionalPlane] = []
    var activePlaneNodes: [SurfacePlane] = []
    
    init(level: Int) {
        self.level = level
        super.init()
        synthesizer.delegate = self
        jackie.delegate = self
        
        levelOneUtterances.append(AVSpeechUtterance(string: "Hi."))
        levelOneUtterances.append(AVSpeechUtterance(string: "Welcome to our parallel world."))
        levelOneUtterances.append(AVSpeechUtterance(string: "my name is Phairy and I'm at your service in this world."))
        levelOneUtterances.append(AVSpeechUtterance(string: "There is a lot to explore in our world"))
        
        switch level {
        case 1:
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.playLevel1()
            }
        default:
            break
        }
    }
    
    private func playLevel1() {
        delegate?.story(self, summonPhairy: true, completion: { (succeed) in
            self.delegate?.phairyShouldLookAtUser(completion: {
                DispatchQueue.main.async {
                    self.levelOneUtterances[0].postUtteranceDelay = self.levelOneUtteranceDelays[0]
                    self.synthesizer.speak(self.levelOneUtterances[0])
                }
            })
        })
    }
    
    // MARK: - Handling Story Delegation Events
    
    func delegateFoundPlane(plane: SurfacePlane, yaw: Float? = nil) {
        if let yaw = yaw {
            let directionalPlane = DirectionalPlane(plane: plane, yaw: yaw)
            activeDirectionalPlanes.append(directionalPlane)
        } else {
            activePlaneNodes.append(plane)
        }
        
        switch level {
        case 1:
            // Play knock knock sound after which Jackie appears
            let url = Bundle.main.url(forResource: "knock_knock_knock", withExtension: "wav", subdirectory: "art.scnassets/Story")!
            let audioSource = SCNAudioSource(url: url)!
            audioSource.load()
            let audioPlayer = SCNAudioPlayer(source: audioSource)
            self.delegate?.phairyShouldGetAlaramed()
            audioPlayer.didFinishPlayback = {
                /// Phairy should turn towards the sound
                self.delegate?.phairyShouldLookAtPortal {
                    /// Phairy Says "Who's There"
                    /// utterance index = 4
                    /// And should look at portal at the same time
                    self.levelOneUtterances.append(AVSpeechUtterance(string: "Who's there?"))
                    self.levelOneUtteranceDelays.append(1.0)
                    self.levelOneUtterances.last?.preUtteranceDelay = 1.0
                    self.levelOneUtterances.last?.rate = AVSpeechUtteranceMaximumSpeechRate * 0.6
                    self.synthesizer.speak(self.levelOneUtterances.last!)
                }
            }
            plane.addAudioPlayer(audioPlayer)
            
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func enterJackie(node: SCNNode) {
        
    }
}
extension Story: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance.isEqual(callBackUtterance) {
            self.delegate?.story(self, didFinishEpisode: 1)
        }
        if let index = levelOneUtterances.index(of: utterance) {
            if index == 2 {
                delegate?.phairyShouldBeep({
                    DispatchQueue.main.async {
                        self.levelOneUtterances[3].postUtteranceDelay = self.levelOneUtteranceDelays[3]
                        self.levelOneUtterances[3].preUtteranceDelay = 2
                        self.synthesizer.speak(self.levelOneUtterances[3])
                    }
                })
                return
            }
            if index == 3 {
                // Play knock knock sound when a plane is found
                self.delegate?.storyNeedsPlane(self, screenCenter: false)
            }
            if index == 4 {
                // Portal should open
                delegate?.openPortal(for: self, completion: {
                    self.delegate?.story(self, placeCharacter: self.jackie)
                })
            }
            if levelOneUtterances.indices.contains(index + 1) {
                DispatchQueue.main.async {
                    self.levelOneUtterances[index + 1].postUtteranceDelay = self.levelOneUtteranceDelays[index + 1]
                    synthesizer.speak(self.levelOneUtterances[index + 1])
                }
            }
        }
    }
}
extension Story: JackieDelegate {
    func elettra(_ elettra: Story.Jackie, completedIntroSpeech: Bool) {
        /// Hide Elettra and the portal
        portal?.removeFromParentNode()
        jackie.model.removeFromParentNode()
        
        /// Phairy Should Look at the user and cry
        delegate?.phairyShouldLookAtUser {
            self.delegate?.phairyShouldPlayDistressSignal({ (succeed) in
                if succeed == true {
                    DispatchQueue.main.async {
                        var utterances: [AVSpeechUtterance] = []
                        utterances.append(AVSpeechUtterance.init(string: "Elettra has location dimension sickness"))
                        utterances[0].postUtteranceDelay = 0.2
                        
                        utterances.append(AVSpeechUtterance.init(string: "she cant keep herself in a certain position for a long time"))
                        utterances[1].postUtteranceDelay = 0.2
                        utterances.append(AVSpeechUtterance.init(string: "but I'm with you and I will help you"))
                        
                        self.callBackUtterance = utterances[2]
                        
                        for utterance in utterances {
                            self.synthesizer.speak(utterance)
                        }
                    }
                }
            })
        }
    }
    func elettra(_ elettra: Story.Jackie, didBeginStanding: Bool) {
        /// Phairy should go next to Eletra
        delegate?.phairyShouldMoveNextToElettra { (succeed: Bool?) -> Void in
            if succeed == true {
                self.delegate?.phairyShouldLookAtElettra({ (succeed) in
                    if succeed == true {
                        self.delegate?.phairyShouldGetUnAlarmed()
                    }
                })
            }
        }
    }
}

protocol StoryDelegate {
    func phairyShouldLookAtUser(completion: @escaping () -> Void)
    func phairyShouldBeep(_ completion: @escaping () -> Void)
    func storyNeedsPlane(_ story: Story, screenCenter: Bool)
    func story(_ story: Story, placeCharacter: Story.Jackie)
    func phairyShouldLookAtPortal(completion: @escaping () -> Void)
    func openPortal(for story: Story, completion: @escaping () -> Void)
    func phairyShouldGetAlaramed()
    func phairyShouldGetUnAlarmed()
    func phairyShouldMoveNextToElettra(_ completion: @escaping (_ succeed: Bool?) -> Void)
    func phairyShouldLookAtElettra(_ completion: @escaping (_ succeed: Bool?) -> Void)
    func phairyShouldPlayDistressSignal(_ completion: @escaping (_ succeed: Bool?) -> Void)
    func story(_ story: Story, didFinishEpisode episode: Int)
    func story(_ story: Story, summonPhairy: Bool, completion: @escaping (_ succeed: Bool?) -> Void)
}
