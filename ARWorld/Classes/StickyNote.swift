//
//  StickyNote.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class StickyNote {
    
    // MARK: - Properties
    
    var rootNode: SCNReferenceNode
    
    private var stickyNode: SCNNode?
    
    private var url: URL = Bundle.main.url(forResource: "sticky note", withExtension: "scn", subdirectory: "art.scnassets/sticky note")!
    
    var text: String
    
    var id: String? {
        didSet {
            stickyNode?.name = id
        }
    }
    
    var isDeletable: Bool = false
    
    var author: PFUser?
    
    var localPosition: SCNVector3 {
        didSet {
            rootNode.position = localPosition
        }
    }
    
    // MARK: - Initialization
    
    init(text: String, position: SCNVector3, removeShadow: Bool = false) {
        self.text = text
        rootNode = SCNReferenceNode(url: url)!
        self.localPosition = position
        self.rootNode.position = position
        rootNode.loadingPolicy = .onDemand
        
        DispatchQueue.global(qos: .background).async {
            self.rootNode.load()
            self.rootNode.eulerAngles = SCNVector3Make(.pi, 0, 0)
            self.stickyNode = self.rootNode.childNode(withName: "note", recursively: true)!
            self.stickyNode!.geometry!.firstMaterial!.diffuse.contents = self.stickyMaterial(text: text)
            self.stickyNode!.categoryBitMask = NodeCategories.stickyNote.rawValue
            if let id = self.id {
                self.stickyNode?.name = id
            }
            if removeShadow {
                let shadowNode = self.rootNode.childNode(withName: "shadow", recursively: true)!
                shadowNode.removeFromParentNode()
            }
        }
    }
    
    convenience init (object: PFObject, removeShadow: Bool = false) {
        let text = object["Text"] as! String
        var pos: SCNVector3?
        if let localPos = object["LocalPos"] as? NSArray {
            pos = SCNVector3Make(localPos[0] as! Float, localPos[1] as! Float - 0.03, localPos[2] as! Float)
        } else if let localPos = object["Pos"] as? NSArray {
            pos = SCNVector3Make(localPos[0] as! Float, localPos[1] as! Float - 0.03, localPos[2] as! Float)
        }
        self.init(text: text, position: pos!, removeShadow: removeShadow)
        id = object.objectId
        if let author = object["Author"] as? PFUser {
            self.author = author
        } else {
            self.author = object["User"] as? PFUser
        }
    }
    
    // MARK: - Database
    
    func saveToDB(for user: PFUser, _ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> (Void) = { _, _ in } )  {
        let stickyNoteObject = PFObject(className: "PersonalStickyNotes")
        stickyNoteObject["User"] = PFUser.current()!
        stickyNoteObject["Text"] = text
        stickyNoteObject["Pos"] = NSArray(array: [localPosition.x, localPosition.y, localPosition.z])
        stickyNoteObject.saveInBackground() { (succeed, error) in
            if error == nil {
                self.id = stickyNoteObject.objectId
            }
            completion(succeed, error)
        }
    }
    
    func saveToDB(for venue: Venue, _ completion: @escaping (_ succeed: Bool?, _ error: Error?) -> (Void) = { _, _ in } ) {
        let id = venue.id
        let venueQuery = PFQuery(className: "Venue")
        venueQuery.getObjectInBackground(withId: id) { (object, error) in
            if error == nil {
                let stickyNotesRelation = object!.relation(forKey: "StickyNotes")
                
                /// Create a TempleStickyNote Object
                let stickyNoteObject = PFObject(className: "TempleStickyNotes")
                stickyNoteObject["Text"] = self.text
                stickyNoteObject["LocalPos"] = NSArray(array: [self.localPosition.x, self.localPosition.y, self.localPosition.z])
                stickyNoteObject["Author"] = PFUser.current()!
                
                stickyNoteObject.saveInBackground { (succeed, error) in
                    if succeed == true {
                        stickyNotesRelation.add(stickyNoteObject)
                        object?.saveInBackground()
                        self.id = stickyNoteObject.objectId
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    func discard(for venue: Venue, _ completion: @escaping (_ succeed: Bool) -> Void = { _ in}) {
        let fadeAction = SCNAction.fadeOut(duration: 0.3)
        rootNode.runAction(fadeAction) {
            let venueQuery = PFQuery(className: "Venue")
            venueQuery.getObjectInBackground(withId: venue.id) { (object, error) in
                if error == nil {
                    if let venueObject = object {
                        let stickyNotesRelation = venueObject.relation(forKey: "StickyNotes")
                        let stickyNotesQuery = stickyNotesRelation.query()
                        stickyNotesQuery.getObjectInBackground(withId: self.id!) { object, error in
                            if error == nil {
                                if let stickyNoteObject = object {
                                    stickyNoteObject.deleteInBackground()
                                    completion(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func discard(for user: PFUser, _ completion: @escaping (_ succeed: Bool) -> Void = { _ in }) {
        let fadeAction = SCNAction.fadeOut(duration: 0.3)
        rootNode.runAction(fadeAction) {
            self.rootNode.removeFromParentNode()
            
            /// Remove from DB
            let stickyNoteQuery = PFQuery(className: "PersonalStickyNotes")
            stickyNoteQuery.getObjectInBackground(withId: self.id!) { (stickyNoteObject, error) in
                if error == nil {
                    stickyNoteObject?.deleteInBackground()
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func stickyMaterial(text: String) -> UIImage {
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
