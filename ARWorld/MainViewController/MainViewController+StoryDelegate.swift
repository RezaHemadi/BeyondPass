//
//  MainViewController+StoryDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 5/10/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import AVFoundation
import ARKit

extension MainViewController: StoryDelegate {
    func story(_ story: Story, didFinishEpisode episode: Int) {
        switch episode {
        case 1:
            // Save Progress in DB
            let storyObject = PFObject(className: "Story")
            storyObject["User"] = PFUser.current()!
            storyObject["Level"] = 2
            storyObject.saveInBackground()
            trophyController.storyDidFinishEpisode(episode)
            activeStory = false
            self.story = nil
            // Add dock
            addDock()
            
            hintsController.delegate = self
            hintsController.tracker = .mainView
        default:
            break
        }
    }
    
    func story(_ story: Story, summonPhairy: Bool, completion: @escaping (_ succeed: Bool?) -> Void) {
        if !robot.isAdded {
            DispatchQueue.main.async {
                self.sceneView.addInfrontOfCamera(node: self.robot.node, at: SCNVector3Make(0, 0.2, -1))
                self.robot.isAdded = true
                // Create a new anchor with the object's current transform and add it to the session
                let newAnchor = ARAnchor(transform: self.robot.node.simdWorldTransform)
                self.robot.anchor = newAnchor
                self.session.add(anchor: newAnchor)
                
                completion(true)
            }
        }
    }
    
    func phairyShouldLookAtUser(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            /// Let Phairy look at the user
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 2
            
            /*
            let cameraPosition = self.session.currentFrame!.camera.transform.translation
            let cameraToRobot = self.sceneView.scene.rootNode.simdConvertPosition(cameraPosition, to: self.robot.node)
            let normalizedCameraDirection = simd_normalize(cameraToRobot)
            
            let teta = acos(simd_dot(float3(normalizedCameraDirection.x, 0, normalizedCameraDirection.z), self.robot.node.simdWorldFront * -1))
            if normalizedCameraDirection.x < 0 {
                self.robot.node.simdEulerAngles += float3(0, -teta, 0)
            } else {
                self.robot.node.simdEulerAngles += float3(0, teta, 0)
            }
            
            let projectedToYPlane = float3(normalizedCameraDirection.x, 0,
                                           normalizedCameraDirection.z)
            let normalizedProjectedToYPlane = simd_normalize(projectedToYPlane)
            
            let tilt = acos(simd_dot(normalizedCameraDirection, normalizedProjectedToYPlane))
            
            if normalizedCameraDirection.y < 0 {
                self.robot.node.simdEulerAngles += float3(tilt, 0, 0)
            } else {
                self.robot.node.simdEulerAngles += float3(-tilt, 0, 0)
            } */
            
            let camera = self.sceneView.pointOfView!
            self.robot.node.look(at: camera.position)
            
            SCNTransaction.completionBlock = {
                completion()
            }
            
            SCNTransaction.commit()
        }
    }
    
    func phairyShouldBeep(_ completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.robot.beep {
                completion()
            }
        }
    }
    
    func storyNeedsPlane(_ story: Story, screenCenter: Bool) {
        DispatchQueue.main.async {
            self.statusViewController.showMessage("Find a flat surface", autoHide: false)
        }
        needPlane = true
        /*
        if screenCenter {
            needPlane = true
        } else {
            /// Check if there is a plane detected
            if let plane = SurfacePlane.planes.sorted(by: {$0.area! > $1.area!}).first {
                if plane.area! > 1.5 {
                    if let camera = session.currentFrame?.camera {
                        let yaw = camera.eulerAngles.y
                        story.delegateFoundPlane(plane: plane, yaw: yaw)
                    } else {
                        story.delegateFoundPlane(plane: plane)
                    }
                }
            } else {
                /// Enqueue the request and return when first plane is found
                needPlane = true
            }

        } */
    }
    func story(_ story: Story, placeCharacter: Story.Jackie) {
        
        placeCharacter.model.position = story.activeDirectionalPlanes.first!.plane.position
        placeCharacter.model.eulerAngles.y = story.activeDirectionalPlanes.first!.yaw
        
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(placeCharacter.model)
            placeCharacter.activate()
        }
    }
    
    func phairyShouldLookAtPortal(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            let directionalPlane = self.story!.activeDirectionalPlanes.first!
            let plane = directionalPlane.plane
            let yaw = directionalPlane.yaw
            
            let tempNode = SCNNode()
            tempNode.simdEulerAngles = float3(0, yaw, 0)
            tempNode.simdPosition = plane.simdPosition
            let position = tempNode.convertPosition(SCNVector3Make(0, 2, -4), to: self.sceneView.scene.rootNode)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            SCNTransaction.completionBlock = completion
            
            self.robot.node.simdLook(at: float3(position.x, position.y, position.z))
            
            SCNTransaction.commit()
        }
    }
    
    func openPortal(for story: Story, completion: @escaping () -> Void) {
        let plane = story.activeDirectionalPlanes.first!.plane
        let yaw = story.activeDirectionalPlanes.first!.yaw
        
        let tempNode = SCNNode()
        tempNode.eulerAngles = SCNVector3Make(0, yaw, 0)
        tempNode.position = plane.position
        
        let portalPosition = tempNode.convertPosition(SCNVector3Make(0, 2, -4), to: sceneView.scene.rootNode)
        let portalURL = Bundle.main.url(forResource: "Intro_Portal", withExtension: "scn", subdirectory: "art.scnassets/Story")!
        let portalReference = SCNReferenceNode(url: portalURL)!
        
        DispatchQueue.main.async {
            portalReference.load()
            portalReference.scale = SCNVector3Make(0, 0, 0)
            portalReference.position = portalPosition
            portalReference.eulerAngles = SCNVector3Make(0, yaw, 0)
            story.portal = portalReference
            self.sceneView.scene.rootNode.addChildNode(portalReference)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 10
            SCNTransaction.completionBlock = { completion() }
            
            portalReference.scale = SCNVector3Make(3, 3, 3)
            
            SCNTransaction.commit()
        }
    }
    func phairyShouldGetAlaramed() {
        DispatchQueue.main.async {
            self.robot.alarmed()
        }
    }
    func phairyShouldGetUnAlarmed() {
        DispatchQueue.main.async {
            self.robot.unAlarmed()
        }
    }
    func phairyShouldMoveNextToElettra(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        let position = self.story!.activeDirectionalPlanes.first!.plane.simdConvertPosition(float3(1, 0, 1.7), to: self.sceneView.scene.rootNode)
        
        self.robot.move(to: position) { (succeed) in
            if succeed == true {
                    completion(true)
            }
        }
    }
    func phairyShouldLookAtElettra(_ completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            //let position = self.sceneView.scene.rootNode.convertPosition(self.story!.activeDirectionalPlanes.first!.plane.position, to: self.robot.node)
            let position = self.story!.jackie.model.presentation.worldPosition
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            SCNTransaction.completionBlock = { completion(true) }
            
            self.robot.node.simdLook(at: float3(position.x, position.y + 1.7, position.z))
            
            SCNTransaction.commit()
        }
    }
    func phairyShouldPlayDistressSignal(_ completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            /// Phairy plays distress signal
            let audioURL = Bundle.main.url(forResource: "Distress_Signal", withExtension: "wav", subdirectory: "art.scnassets/Story")!
            let audioSource = SCNAudioSource(url: audioURL)!
            audioSource.load()
            let audioPlayer = SCNAudioPlayer(source: audioSource)
            audioPlayer.didFinishPlayback = { completion(true) }
            self.robot.node.addAudioPlayer(audioPlayer)
        }
    }
}
