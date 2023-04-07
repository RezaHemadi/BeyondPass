//
//  Graffiti.swift
//  ARWorld
//
//  Created by Reza Hemadi on 7/28/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation
import SpriteKit

class Graffiti {
    
    // MARK: - Properties
    
    var plane: SurfacePlane
    
    var rect: CGRect!
    
    var path: UIBezierPath!
    
    var initPoint: CGPoint?
    
    var timer: Timer?
    
    var material: SCNMaterial?
    
    var borderPath: UIBezierPath
    
    var layers: [UIImage] = []
    
    var graffitiObject: PFObject?
    
    var currentColor: UIColor
    
    var renderer: UIGraphicsImageRenderer
    
    var pattern: [CGFloat] = [2.5, 5]
    
    // MARK: - Initialization
    
    init(_ plane: SurfacePlane, color: UIColor, at location: CLLocation) {
        self.currentColor = color
        plane.isGraffiti = true
        self.plane = plane
        
        // Normalize rect
        let width = plane.planeGeometry!.width
        let height = plane.planeGeometry!.height
        var rectWidth: CGFloat!
        var rectHeight: CGFloat!
        if width > height {
            rectWidth = (width / width ) * 300
            rectHeight = (height / width) * 300
        } else {
            rectWidth = (width / height ) * 300
            rectHeight = (height / height) * 300
        }
        
        rect = CGRect(x: 0, y: 0, width: rectWidth, height: rectHeight)
        renderer = UIGraphicsImageRenderer(size: rect.size)
        
        borderPath = UIBezierPath(rect: rect)
        
        material = SCNMaterial()
        plane.geometry?.firstMaterial? = material!
        setUpMaterial()
        drawBorderPath()
        
        path = UIBezierPath()
        path.lineWidth = 2
        path.lineCapStyle = .butt
        path.lineJoinStyle = .round
        
        DispatchQueue.global(qos: .background).async {
            self.graffitiObject = PFObject(className: "Graffiti")
            self.graffitiObject?["Author"] = PFUser.current()!
            self.graffitiObject?["Location"] = PFGeoPoint.init(location: location)
        }
    }
    
    init(_ plane: SurfacePlane, object: PFObject) {
        self.plane = plane
        self.currentColor = UIColor.clear
        self.graffitiObject = object
        plane.isGraffiti = true
        
        // Normalize rect
        let width = plane.planeGeometry!.width
        let height = plane.planeGeometry!.height
        var rectWidth: CGFloat!
        var rectHeight: CGFloat!
        if width > height {
            rectWidth = (width / width ) * 300
            rectHeight = (height / width) * 300
        } else {
            rectWidth = (width / height ) * 300
            rectHeight = (height / height) * 300
        }
        
        rect = CGRect(x: 0, y: 0, width: rectWidth, height: rectHeight)
        
        renderer = UIGraphicsImageRenderer(size: rect.size)
        
        borderPath = UIBezierPath(rect: rect)
        
        material = SCNMaterial()
        plane.geometry?.firstMaterial? = material!
        setUpMaterial()
        
        path = UIBezierPath()
        path.lineWidth = 2
        path.lineCapStyle = .butt
        path.lineJoinStyle = .round
        
        let file = object["Image"] as! PFFileObject
        file.getDataInBackground() { data, error in
            if error == nil {
                if let imageData = data {
                    let image = UIImage(data: imageData)!
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.layers.append(image)
                        self.material?.diffuse.contents = self.renderer.image(actions: { (context) in
                            image.draw(in: self.rect)
                        })
                    }
                }
            }
        }
    }
    
    func movePointer(_ hitResult: SCNHitTestResult) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true, block: { (timer) in
            self.updateMaterial()
        })
        let localPos = hitResult.textureCoordinates(withMappingChannel: 0)
        let mappedPoint = CGPoint.init(x: localPos.x * rect.width, y: localPos.y * rect.height)
        self.path.move(to: mappedPoint)
        self.initPoint = mappedPoint
    }
    
    func update(for hitTestResult: SCNHitTestResult) {
        let localPos = hitTestResult.textureCoordinates(withMappingChannel: 0)
        let mappedPoint = CGPoint.init(x: localPos.x * rect.width, y: localPos.y * rect.height)
        if let initPoint = self.initPoint {
            self.path.move(to: initPoint)
            self.initPoint = nil
        } else {
            self.path.addLine(to: mappedPoint)
        }
    }
    
    func drawBorderPath() {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        DispatchQueue.global(qos: .userInteractive).async {
            self.material?.diffuse.contents = renderer.image { context in
                UIColor.red.setStroke()
                UIColor.clear.setFill()
                self.borderPath.setLineDash(self.pattern, count: 2, phase: 0)
                self.borderPath.stroke()
            }
        }
    }
    
    func updateMaterial() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.material?.diffuse.contents = self.renderer.image(actions: { (context) in
                UIColor.red.setStroke()
                self.borderPath.stroke()
                self.layers.last?.draw(in: self.rect)
                self.currentColor.withAlphaComponent(0.8).setStroke()
                self.path.stroke()
            })
        }
    }
    
    func stopSpray() {
        DispatchQueue.global(qos: .userInteractive).async {
            let newLayer = self.renderer.image(actions: { (context) in
                self.layers.last?.draw(in: self.rect)
                self.currentColor.withAlphaComponent(0.8).setStroke()
                self.path.stroke()
            })
            self.material?.diffuse.contents = newLayer
            self.layers.append(newLayer)
            self.path = UIBezierPath()
            self.path.lineWidth = 2
            self.path.lineCapStyle = .butt
            self.path.lineJoinStyle = .round
            self.saveToDB()
        }
/*        DispatchQueue.global(qos: .userInteractive).async {
            self.material?.diffuse.contents = self.renderer.image(actions: { (context) in
                self.borderImage?.draw(in: self.rect)
                for image in self.layers {
                    image.draw(in: self.rect)
                }
                self.currentColor.withAlphaComponent(0.8).setStroke()
                self.path.stroke()
            })
            self.layers.append(self.material?.diffuse.contents as! UIImage)
            self.path = UIBezierPath()
            self.path.lineWidth = 4
            self.path.lineCapStyle = .butt
            self.path.lineJoinStyle = .round
            
            self.saveToDB()
        } */
        timer?.invalidate()
    }
    
    func setUpMaterial() {
        material!.lightingModel = .physicallyBased
        material!.metalness.contents = 0.5 as Float
        material!.roughness.contents = 0.2 as Float
    }
    
    // Saving and Retrieving
    func saveToDB() {
        DispatchQueue.global(qos: .background).async {
            let image = self.renderer.image(actions: { (context) in
                self.layers.last?.draw(in: self.rect)
            })
            let data = image.pngData()!
            self.graffitiObject?["Image"] = PFFileObject(data: data)
            self.graffitiObject?.saveInBackground()
        }
    }
}
