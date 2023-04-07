//
//  AudioBadge.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/22/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class AudioBadge {
    
    var rootNode: SCNReferenceNode
    
    private let url = Bundle.main.url(forResource: "VoiceBadge", withExtension: "scn", subdirectory: "art.scnassets/PinBoardPublic")!
    
    private var playNode: SCNNode?
    
    private var bodyNode: SCNNode?
    
    private var audioPlayer: SCNAudioPlayer?
    
    var data: Data?
    
    var localURL: URL?
    
    var id: String? {
        didSet {
            self.rootNode.name = id
            self.rootNode.childNodes.forEach { $0.name = id }
        }
    }
    
    var author: PFUser?
    
    var isDeletable: Bool = false
    
    init() {
        rootNode = SCNReferenceNode(url: url)!
        rootNode.loadingPolicy = .onDemand
        rootNode.scale = SCNVector3Make(0.4, 0.4, 0.4)
        rootNode.categoryBitMask = NodeCategories.voiceBadge.rawValue
        
        DispatchQueue.global(qos: .background).async {
            self.rootNode.load()
            
            self.playNode = self.rootNode.childNode(withName: "Play", recursively: true)
            self.bodyNode = self.rootNode.childNode(withName: "Body", recursively: true)
            self.rootNode.childNodes.forEach { $0.categoryBitMask = NodeCategories.voiceBadge.rawValue; $0.name = self.id }
        }
    }
    
    func saveFile() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentPath.appendingPathComponent("\(String(describing: id)).m4a")
        print("audio saved to url: \(url)")
        do {
            try data!.write(to: url)
            self.localURL = url
        } catch {
            
        }
    }
    
    func saveInDB(for venue: Venue, _ completion: @escaping (_ id: String?, _ error: Error?) -> Void) {
        if let currentUser = PFUser.current(), let data = self.data {
            DispatchQueue.global(qos: .background).async {
                let voiceBadgeObject = PFObject(className: "VoiceBadge")
                voiceBadgeObject["Author"] = currentUser
                voiceBadgeObject["Data"] = PFFileObject(data: data)
                voiceBadgeObject["Pos"] = NSArray(array: [self.rootNode.position.x, self.rootNode.position.y, self.rootNode.position.z])
                
                do {
                    try voiceBadgeObject.save()
                    let venueQuery = PFQuery(className: "Venue")
                    let venueObject = try venueQuery.getObjectWithId(venue.id)
                    let voiceBadgesRelation = venueObject.relation(forKey: "VoiceBadges")
                    voiceBadgesRelation.add(voiceBadgeObject)
                    try venueObject.save()
                    self.id = voiceBadgeObject.objectId
                    self.rootNode.name = voiceBadgeObject.objectId
                    self.saveFile()
                    completion(voiceBadgeObject.objectId, nil)
                } catch {
                    completion(nil, error)
                }
            }
        } else {
            completion(nil, nil)
        }
    }
    
    func saveInDB(for user: PFUser, _ completion: @escaping (_ success: Bool?, _ error: Error?) -> Void) {
        if let currentUser = PFUser.current(), let data = self.data {
            let personalVoiceBadgeObject = PFObject(className: "PersonalVoiceBadge")
            personalVoiceBadgeObject["User"] = currentUser
            personalVoiceBadgeObject["Data"] = PFFileObject(data: data)
            personalVoiceBadgeObject["Pos"] = NSArray(array: [self.rootNode.position.x, self.rootNode.position.y, self.rootNode.position.z])
            personalVoiceBadgeObject.saveInBackground { (success, error) in
                self.id = personalVoiceBadgeObject.objectId
                self.saveFile()
                completion(success, error)
            }
        }
    }
    
    func loadAudio(_ completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        if data == nil {
            DispatchQueue.global(qos: .userInitiated).async {
                let voiceBadgeQuery = PFQuery(className: "VoiceBadge")
                do {
                    let voiceBadgeObject = try voiceBadgeQuery.getObjectWithId(self.id!)
                    let dataFile = voiceBadgeObject["Data"] as! PFFileObject
                    let data = try dataFile.getData()
                    self.data = data
                    self.saveFile()
                    completion(data, nil)
                } catch {
                    completion(nil, error)
                }
            }
        } else {
            completion(data, nil)
        }
    }
    func discard(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        let fadeAction = SCNAction.fadeOut(duration: 0.3)
        rootNode.runAction(fadeAction, completionHandler: { self.rootNode.removeFromParentNode(); completion(true) } )
    }
    func deleteFromDB(for user: PFUser, id: String) {
        DispatchQueue.global(qos: .background).async {
            let personalVoiceBadgeQuery = PFQuery(className: "PersonalVoiceBadge")
            personalVoiceBadgeQuery.getObjectInBackground(withId: id) { (voiceBadgeObject, error) in
                if error == nil {
                    voiceBadgeObject!.deleteInBackground()
                }
            }
        }
    }
    
    func deleteFromDB(for venue: Venue, id: String) {
        let venueQuery = PFQuery(className: "Venue")
        venueQuery.getObjectInBackground(withId: venue.id) { (venueObject, error) in
            if error == nil {
                let voiceBadgesRelation = venueObject!.relation(forKey: "VoiceBadges")
                let voiceBadgeQuery = voiceBadgesRelation.query()
                voiceBadgeQuery.getObjectInBackground(withId: id) { (voiceBadgeObject, error) in
                    if error == nil {
                        voiceBadgesRelation.remove(voiceBadgeObject!)
                        voiceBadgeObject!.deleteInBackground()
                    }
                }
            }
        }
    }
    
    func play() {
        guard localURL != nil else { return }
        
        DispatchQueue.main.async {
            let audioSource = SCNAudioSource(url: self.localURL!)!
            audioSource.load()
            self.audioPlayer = SCNAudioPlayer(source: audioSource)
            self.rootNode.addAudioPlayer(self.audioPlayer!)
            print("Audio Played")
        }
    }
}
