//
//  PortalPinBoard.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/23/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class PortalPinBoard {
    
    var rootNode: SCNNode
    
    var board: SCNNode
    
    var user: PFUser
    
    var visiting: Bool
    
    var voiceBadges: [String: AudioBadge] = [:]
    
    var stickyNotes: [String: StickyNote] = [:]
    
    var pinPhotos: [String: PinPhoto] = [:]
    
    init(node: SCNNode, user: PFUser) {
        self.rootNode = node
        self.user = user
        if user.objectId! == PFUser.current()!.objectId! {
            visiting = false
        } else {
            visiting = true
        }
        self.board = node.childNode(withName: "Board", recursively: true)!
        self.board.categoryBitMask = NodeCategories.pinBoard.rawValue
        loadNotes()
        loadVoiceBadges()
        loadPinPhotos()
    }
    
    private func loadNotes() {
        DispatchQueue.global(qos: .background).async {
            do {
                let stickyNotesQuery = PFQuery(className: "PersonalStickyNotes")
                stickyNotesQuery.whereKey("User", equalTo: self.user)
                let stickyNotesObjects = try stickyNotesQuery.findObjects()
                for stickyNoteObject in stickyNotesObjects {
                    let stickyNote = StickyNote(object: stickyNoteObject, removeShadow: true)
                    self.board.addChildNode(stickyNote.rootNode)
                    self.stickyNotes[stickyNoteObject.objectId!] = stickyNote
                    stickyNote.id = stickyNoteObject.objectId
                    if self.visiting {
                        stickyNote.isDeletable = false
                    } else {
                        stickyNote.isDeletable = true
                    }
                }
            } catch {
                
            }
        }
    }
    
    func loadVoiceBadges() {
        DispatchQueue.global(qos: .background).async {
            do {
                let personalVoiceBadgeQuery = PFQuery(className: "PersonalVoiceBadge")
                personalVoiceBadgeQuery.whereKey("User", equalTo: self.user)
                let voiceBadgeObjects = try personalVoiceBadgeQuery.findObjects()
                for voiceBadgeObject in voiceBadgeObjects {
                    let positionArray = voiceBadgeObject["Pos"] as! NSArray
                    let position = SCNVector3Make(positionArray[0] as! Float, positionArray[1] as! Float, positionArray[2] as! Float)
                    let voiceBadge = AudioBadge()
                    voiceBadge.author = voiceBadgeObject["Author"] as? PFUser
                    voiceBadge.rootNode.position = position
                    voiceBadge.rootNode.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
                    voiceBadge.rootNode.name = voiceBadgeObject.objectId!
                    voiceBadge.id = voiceBadgeObject.objectId!
                    self.board.addChildNode(voiceBadge.rootNode)
                    self.voiceBadges[voiceBadgeObject.objectId!] = voiceBadge
                    if self.visiting {
                        voiceBadge.isDeletable = false
                    } else {
                        voiceBadge.isDeletable = true
                    }
                }
            } catch {
                
            }
        }
    }
    private func loadPinPhotos() {
        DispatchQueue.global(qos: .background).async {
            do {
                let pinPhotosQuery = PFQuery(className: "PersonalPinPhoto")
                pinPhotosQuery.whereKey("User", equalTo: self.user)
                let pinPhotoObjects = try pinPhotosQuery.findObjects()
                for pinPhotoObject in pinPhotoObjects {
                    let positionArray = pinPhotoObject["Pos"] as! NSArray
                    let position = SCNVector3Make(positionArray[0] as! Float, positionArray[1] as! Float, positionArray[2] as! Float)
                    let imageFile = pinPhotoObject["Image"] as! PFFileObject
                    let author = pinPhotoObject["User"] as! PFUser
                    let imageData = try imageFile.getData()
                    let image = UIImage(data: imageData)!
                    let pinPhoto = PinPhoto(image: image, id: pinPhotoObject.objectId!, author: author, inPortal: true)
                    pinPhoto.rootNode.position = position
                    self.board.addChildNode(pinPhoto.rootNode)
                    self.pinPhotos[pinPhotoObject.objectId!] = pinPhoto
                    if self.visiting {
                        pinPhoto.isDeletable = false
                    } else {
                        pinPhoto.isDeletable = true
                    }
                }
            } catch {
                
            }
        }
    }
    
    func saveToDB(_ note: StickyNote) {
        note.saveToDB(for: user) { (succeed, error) -> (Void) in
            if error == nil {
                self.stickyNotes[note.id!] = note
            }
        }
    }
    
    func stickyMaterial(text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let image = renderer.image { (context) in
            UIColor(red: 231/255, green: 222/255, blue: 161/255, alpha: 1.0).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes = [NSAttributedString.Key.paragraphStyle  :  paragraphStyle,
                              NSAttributedString.Key.font            :   UIFont(name: "SavoyeLetPlain", size: 55),
                              NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 28/255, blue: 44/255, alpha: 1.0),
                              ]
            
            let myText = text
            let attrString = NSAttributedString(string: myText,
                                                attributes: attributes)
            
            let rt = CGRect(x: 5, y: 5, width: 256, height: 256)
            attrString.draw(in: rt)
        }
        return image
    }
}
