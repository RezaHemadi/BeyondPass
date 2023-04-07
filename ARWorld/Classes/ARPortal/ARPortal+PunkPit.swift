//
//  ARPortal+PunkPit.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/18/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class PunkPit {
        
        // MARK: -Properties
        
        var user: PFUser?
        
        let node: SCNNode
        
        let largeLeftGear: SCNNode
        
        let rightLargeGear: SCNNode
        
        let rightSmallGear: SCNNode
        
        let leftSmallGear: SCNNode
        
        let followersNeedle: SCNNode
        
        let leftGaugePin: SCNNode
        
        let rightGaugePin: SCNNode
        
        let followingNeedle: SCNNode
        
        let leftInnerLargeGear: SCNNode
        
        let rightInnerLargeGear: SCNNode
        
        let defaultSoundAction: SCNAction = {
            // Play Sound
            let audioURL = Bundle.main.url(forResource: "PunkPit_Sound", withExtension: "mp3", subdirectory: "art.scnassets/Portal/PunkPit")!
            let audioSource = SCNAudioSource(url: audioURL)!
            audioSource.load()
            audioSource.volume = 1.0
            let playAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
            return SCNAction.repeatForever(playAction)
        }()
        
        var pausedActions: [String:SCNAction] = [:]
        
        var gears: [SCNNode] {
            get {
                return [leftSmallGear, largeLeftGear, rightLargeGear, rightSmallGear, leftInnerLargeGear, rightInnerLargeGear]
            }
        }
        
        // MARK: -Initialization
        
        init(node: SCNNode) {
            // Get Components
            self.node = node
            largeLeftGear = node.childNode(withName: "LargeGear", recursively: true)!
            leftSmallGear = node.childNode(withName: "SmallGear", recursively: true)!
            rightLargeGear = node.childNode(withName: "RightLargeGear", recursively: true)!
            rightSmallGear = node.childNode(withName: "RightSmallGear", recursively: true)!
            followersNeedle = node.childNode(withName: "LeftGuageNeedle", recursively: true)!
            leftGaugePin = node.childNode(withName: "LeftGuagePin", recursively: true)!
            rightGaugePin = node.childNode(withName: "RightGaugePin", recursively: true)!
            followingNeedle = node.childNode(withName: "RightGaugeNeedle", recursively: true)!
            leftInnerLargeGear = node.childNode(withName: "Inner-LargeGear", recursively: true)!
            rightInnerLargeGear = node.childNode(withName: "RightInnerLargeGear", recursively: true)!
            
            // Turn the wheels
            rotateWheels()
            
            
            self.node.runAction(defaultSoundAction, forKey: "defaultSound")
        }
        
        // MARK: - Configure Internal nodes
        
        func rotateWheels() {
            let smallWheels: [SCNNode] = [largeLeftGear, rightLargeGear]
            let largeWheels: [SCNNode] = [rightSmallGear, leftSmallGear]
            let innerGears: [SCNNode] = [leftInnerLargeGear, rightInnerLargeGear]
            
            for wheel in smallWheels {
                let (gearMin, gearMax) = wheel.boundingBox
                let dx = gearMin.x + 0.5 * (gearMax.x - gearMin.x)
                let dy = gearMin.y + 0.5 * (gearMax.y - gearMin.y)
                let dz = gearMin.z + 0.5 * (gearMax.z - gearMin.z)
                
                let center = float3(dx, dy, dz)
                wheel.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                wheel.simdPosition = center
                //let axis = leftLargeGear.simdWorldFront + center
                let rotationAction = SCNAction.repeatForever(SCNAction.rotate(by: 2 * .pi, around: wheel.worldFront, duration: 6))
                wheel.runAction(rotationAction, forKey: "rotate")
            }
            
            for wheel in largeWheels {
                let (gearMin, gearMax) = wheel.boundingBox
                let dx = gearMin.x + 0.5 * (gearMax.x - gearMin.x)
                let dy = gearMin.y + 0.5 * (gearMax.y - gearMin.y)
                let dz = gearMin.z + 0.5 * (gearMax.z - gearMin.z)
                
                let center = float3(dx, dy, dz)
                wheel.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                wheel.simdPosition = center
                //let axis = leftLargeGear.simdWorldFront + center
                let rotationAction = SCNAction.repeatForever(SCNAction.rotate(by: -2 * .pi, around: wheel.worldFront, duration: 6))
                wheel.runAction(rotationAction, forKey: "rotate")
            }
            
            for innerGear in innerGears {
                let (gearMin, gearMax) = innerGear.boundingBox
                let dx = gearMin.x + 0.5 * (gearMax.x - gearMin.x)
                let dy = gearMin.y + 0.5 * (gearMax.y - gearMin.y)
                let dz = gearMin.z + 0.5 * (gearMax.z - gearMin.z)
                
                let center = float3(dx, dy, dz)
                innerGear.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
                innerGear.simdPosition = center
                //let axis = leftLargeGear.simdWorldFront + center
                let rotationAction = SCNAction.repeatForever(SCNAction.rotate(by: 2 * .pi, around: innerGear.worldFront, duration: 6))
                innerGear.runAction(rotationAction, forKey: "rotate")
            }
        }
        private func adjustFollowersGuage() {
            let (pinMin, pinMax) = leftGaugePin.boundingBox
            let x = pinMin.x + 0.5 * (pinMax.x - pinMin.x)
            let y = pinMin.y + 0.5 * (pinMax.y - pinMin.y)
            let z = pinMin.z + 0.5 * (pinMax.z - pinMin.z)
            let pivotPosition = leftGaugePin.convertPosition(SCNVector3Make(x, y, z), to: followersNeedle)
            followersNeedle.pivot = SCNMatrix4MakeTranslation(pivotPosition.x, pivotPosition.y, pivotPosition.z)
            
            followersNeedle.position = pivotPosition
            
            let simdRotationAxis = float3(0.25, -1, 0)
            
            let rotationAxis = SCNVector3Make(simdRotationAxis.x, simdRotationAxis.y, simdRotationAxis.z)
            
            let maxAngle: CGFloat = 270 * .pi / 180
            let anglePerFollower = maxAngle / 300
            
            // Get the number of followers
            if let currentUser = user {
                let followersRelation = currentUser.relation(forKey: "Followers")
                let followersQuery = followersRelation.query()
                followersQuery.countObjectsInBackground {
                    (followerCount: Int32?, error: Error?) in
                    if error == nil {
                        let angle: CGFloat = anglePerFollower * CGFloat(followerCount!)
                        let rotationAction = SCNAction.rotate(by: angle, around: rotationAxis, duration: 10).reversed()
                        self.followersNeedle.runAction(rotationAction)
                    }
                }
            }
        }
        private func adjustFollowingGauge() {
            let (pinMin, pinMax) = rightGaugePin.boundingBox
            let x = pinMin.x + 0.5 * (pinMax.x - pinMin.x)
            let y = pinMin.y + 0.5 * (pinMax.y - pinMin.y)
            let z = pinMin.z + 0.5 * (pinMax.z - pinMin.z)
            let pivotPosition = rightGaugePin.convertPosition(SCNVector3Make(x, y, z), to: followingNeedle)
            followingNeedle.pivot = SCNMatrix4MakeTranslation(pivotPosition.x, pivotPosition.y, pivotPosition.z)
            
            followingNeedle.position = pivotPosition
            
            let simdRotationAxis = float3(-0.27, -1, 0)
            
            let rotationAxis = SCNVector3Make(simdRotationAxis.x, simdRotationAxis.y, simdRotationAxis.z)
            
            let maxAngle: CGFloat = 270 * .pi / 180
            let anglePerFollowing = maxAngle / 300
            
            // Get the number of following
            if let currentUser = user {
                let followingRelation = currentUser.relation(forKey: "Following")
                let followingQuery = followingRelation.query()
                followingQuery.countObjectsInBackground {
                    (followingCount: Int32?, error: Error?) -> Void in
                    if error == nil {
                        let angle: CGFloat = anglePerFollowing * CGFloat(followingCount!)
                        let rotationAction = SCNAction.rotate(by: -angle, around: rotationAxis, duration: 10).reversed()
                        self.followingNeedle.runAction(rotationAction)
                    }
                }
            }
        }
        
        func pauseActions() {
            let actionsKeys = node.actionKeys
            
            for actionKey in actionsKeys {
                let action = node.action(forKey: actionKey)
                
                if action != nil {
                    
                    pausedActions[actionKey] = action
                    node.removeAction(forKey: actionKey)
                }
            }
        }
        
        func resumeActions() {
            
            for (key, value) in pausedActions {
                node.runAction(value, forKey: key)
            }
        }
    }
}
