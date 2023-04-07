//
//  ARTemple.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/14/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//
//  Renamed to PinBoardPublic.swift

import Foundation

class PinBoardPublic {
    
    // MARK: - Properties
    
    var rootNode: SCNNode?
    
    var board: SCNNode?
    
    var venue: Venue
    
    var voiceBadges: [String: AudioBadge] = [:]
    
    var pinPhotos: [String: PinPhoto] = [:]
    
    var stickyNotes: [String: StickyNote] = [:]
    
    init(_ venue: Venue) {
        self.venue = venue
    }
    
    func initializePinBoardNode(_ completion: @escaping(_ node: SCNNode?) -> Void) {
        DispatchQueue.main.async {
            let templeURL = Bundle.main.url(forResource: "PinBoardPublic", withExtension: "scn", subdirectory: "art.scnassets/PinBoardPublic")
            let templeRefNode = SCNReferenceNode(url: templeURL!)
            templeRefNode?.load()
            
            templeRefNode?.scale = SCNVector3Make(1.0, 1.0, 1.0)
            
            self.rootNode = templeRefNode
            
            /// Adjust Pivot
            let (min, max) = self.rootNode!.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z
            
            self.rootNode!.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            
            self.rootNode?.categoryBitMask = NodeCategories.pinBoard.rawValue
            
            self.board = templeRefNode!.childNode(withName: "Board", recursively: true)!
            
            self.board!.categoryBitMask = NodeCategories.pinBoard.rawValue
            self.loadItems()
            completion(templeRefNode)
        }
    }
    
    private func loadItems() {
        DispatchQueue.global(qos: .background).async {
            let venueQuery = PFQuery(className: "Venue")
            venueQuery.getObjectInBackground(withId: self.venue.id) { (object, error) in
                if error == nil {
                    let notesRelation = object!.relation(forKey: "StickyNotes")
                    let notesQuery = notesRelation.query()
                    notesQuery.findObjectsInBackground { (objects, error) in
                        if error == nil {
                            if let notes = objects {
                                for note in notes {
                                    let stickyNote = StickyNote(object: note)
                                    self.board!.addChildNode(stickyNote.rootNode)
                                    self.stickyNotes[note.objectId!] = stickyNote
                                    if stickyNote.author!.objectId == PFUser.current()?.objectId! {
                                        stickyNote.isDeletable = true
                                    }
                                }
                            }
                        }
                    }
                    let voiceRelation = object!.relation(forKey: "VoiceBadges")
                    let voiceQuery = voiceRelation.query()
                    do {
                        let voiceBadgeObjects = try voiceQuery.findObjects()
                        for voiceBadgeObject in voiceBadgeObjects {
                            let positionArray = voiceBadgeObject["Pos"] as! NSArray
                            let position = SCNVector3Make(positionArray[0] as! Float, positionArray[1] as! Float, positionArray[2] as! Float)
                            let voiceBadge = AudioBadge()
                            voiceBadge.author = voiceBadgeObject["Author"] as? PFUser
                            voiceBadge.loadAudio() { data, error in
                                
                            }
                            voiceBadge.rootNode.position = position
                            voiceBadge.rootNode.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
                            voiceBadge.rootNode.name = voiceBadgeObject.objectId!
                            voiceBadge.id = voiceBadgeObject.objectId!
                            self.board!.addChildNode(voiceBadge.rootNode)
                            self.voiceBadges[voiceBadgeObject.objectId!] = voiceBadge
                            if voiceBadge.author!.objectId == PFUser.current()?.objectId! {
                                voiceBadge.isDeletable = true
                            }
                        }
                    } catch {
                        
                    }
                    
                    let photosRelation = object!.relation(forKey: "Photos")
                    let photosQuery = photosRelation.query()
                    do {
                        let photoObjects = try photosQuery.findObjects()
                        for photoObject in photoObjects {
                            let positionArray = photoObject["Pos"] as! NSArray
                            let position = SCNVector3Make(positionArray[0] as! Float, positionArray[1] as! Float, positionArray[2] as! Float)
                            let imageFile = photoObject["Image"] as! PFFileObject
                            let author = photoObject["Author"] as! PFUser
                            let imageData = try imageFile.getData()
                            let image = UIImage(data: imageData)!
                            let pinPhoto = PinPhoto(image: image, id: photoObject.objectId!, author: author)
                            pinPhoto.rootNode.position = position
                            self.pinPhotos[photoObject.objectId!] = pinPhoto
                            self.board!.addChildNode(pinPhoto.rootNode)
                            if pinPhoto.authorObject!.objectId == PFUser.current()?.objectId! {
                                pinPhoto.isDeletable = true
                            }
                        }
                    } catch {
                        print("\(error)")
                    }
                }
            }
        }
    }
    
    func playVoiceBadge(id: String) {
        let voiceBadge = voiceBadges[id]
        voiceBadge!.play()
    }
    
    func saveToDB(_ note: StickyNote) {
        note.saveToDB(for: venue) { (succeed, error) in
            if error == nil {
                self.stickyNotes[note.id!] = note
            }
        }
    }
    
    // MARK: - Sticky Notes
    
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
