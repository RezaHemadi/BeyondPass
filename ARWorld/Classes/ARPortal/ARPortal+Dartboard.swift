//
//  ARPortal+Dartboard.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/21/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

extension ARPortal {
    class Dartboard: DartGame {
        
        // MARK: - Types
        
        enum GameOptions: String {
            case newGame = "New Game"
        }
        
        enum GameState {
            case inactive
            case pickingDart
            case throwingDart(variant: Dart.Variant)
        }
        
        // MARK: - Properties
        lazy var audioSource = SCNAudioSource(fileNamed: "art.scnassets/Portal/DartHitSound.mp3")!
        let node: SCNNode
        let zUp = true
        var textOptionPosition: float3 {
            let (min, max) = node.boundingBox
            let x = min.x + 0.5 * (max.x - min.x)
            let y = min.y + 0.5 * (max.y - min.y) - 0.3
            let z = max.z + 0.1
            
            return float3(x, y, z)
        }
        var dartIndicatorPosition: [SCNVector3] {
            var positions: [SCNVector3] = []
            
            let (min, max) = rightBlackboard.boundingBox
            let x = min.x + 0.5 * (max.x - min.x)
            let y = min.y - 0.1
            let z = max.z
            
            let center = SCNVector3Make(x, y, z)
            
            positions.append(rightBlackboard.convertPosition(center, to: node))
            
            let (leftMin, leftMax) = leftBlackboard.boundingBox
            let leftX = leftMin.x + 0.5 * (leftMax.x - leftMin.x)
            let leftY = leftMin.y - 0.1
            let leftZ = leftMax.z
            
            let leftCenter = SCNVector3Make(leftX, leftY, leftZ)
            
            positions.append(leftBlackboard.convertPosition(leftCenter, to: node))
            
            return positions
        }
        var displayedOption: GameOptions?
        var optionNode: SCNNode?
        var lightNodes: [SCNNode] = []
        var gameState: GameState {
            didSet {
                switch gameState {
                case .inactive:
                    break
                case .pickingDart:
                    // Darts should be refilled
                    fillDarts()
                    showDartIndicators()
                    
                    // Clear the dart plane from any darts
                    
                case .throwingDart(let variant):
                    removeDarts(type: variant)
                    removeIndicatorArrows()
                    dartsCount = 5
                    gameDelegate?.dartGame(self, didBeginWith: variant)
                }
            }
        }
        var dart1NodesHidden: Bool = false
        var dart2NodesHidden: Bool = false
        var indicatorArrows: [SCNNode] = []
        var gameDelegate: DartGameDelegate?
        var dartsCount: Int = 0
        var equippedDart: Dart?
        var reticle: DartReticleView?
        
        /// Internal nodes
        let rightBlackboard: SCNNode
        let leftBlackboard: SCNNode
        var dart1Nodes: [SCNNode] = []
        var dart2Nodes: [SCNNode] = []
        let dartPlane: SCNNode
        
        // MARK: - Initialization
        
        init(node: SCNNode) {
            self.node = node
            rightBlackboard = node.childNode(withName: "RightBlackboard", recursively: true)!
            leftBlackboard = node.childNode(withName: "LeftBlackboard", recursively: true)!
            self.node.categoryBitMask = NodeCategories.dartboard.rawValue
            
            // set rendering order of the childnodes
            for childNode in node.childNodes {
                childNode.renderingOrder = 200
                if childNode.categoryBitMask == NodeCategories.dart1.rawValue {
                    dart1Nodes.append(childNode)
                    continue
                } else if childNode.categoryBitMask == NodeCategories.dart2.rawValue {
                    dart2Nodes.append(childNode)
                    continue
                }
                childNode.categoryBitMask = NodeCategories.dartboard.rawValue
            }
            gameState = .inactive
            
            dartPlane = node.childNode(withName: "DartPlane", recursively: true)!
            dartPlane.categoryBitMask = NodeCategories.dartPlane.rawValue
            /*
            let (min, max) = dartPlane.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z + 0.5 * (max.z - min.z)
            dartPlane.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            dartPlane.simdPosition += float3(dx, dy, dz) */
        }
        
        // MARK: - Visuals
        
        func displayOption(_ option: GameOptions) {
            guard displayedOption != option else { return }
            
            let textGeometry = SCNText(string: option.rawValue, extrusionDepth: 0.2)
            textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
            textGeometry.font = UIFont(name: "HelveticaNeue-Bold", size: 3)
            textGeometry.firstMaterial?.diffuse.contents = UIColor(red: 178/255.0, green: 57/255.0, blue: 41/255.0, alpha: 1.0)
            textGeometry.firstMaterial?.emission.contents = UIColor(red: 178/255.0, green: 57/255.0, blue: 41/255.0, alpha: 1.0)
            textGeometry.firstMaterial?.lightingModel = .physicallyBased
            textGeometry.chamferRadius = 1.0
           
            let textNode = SCNNode(geometry: textGeometry)
            textNode.adjustPivot(to: .floor)
            textNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
            textNode.eulerAngles = SCNVector3Make( 100 * (.pi / 180), 0, 0)
            
            let lightNode1 = SCNNode()
            let light = SCNLight()
            light.type = .omni
            light.intensity = 20
            light.color = UIColor(red: 178/255.0, green: 57/255.0, blue: 41/255.0, alpha: 1.0)
            lightNode1.light = light
            lightNode1.simdPosition = textOptionPosition
            lightNodes.append(lightNode1)
            node.addChildNode(lightNode1)
            
 
            /// set the position of the text node
            textNode.simdPosition = textOptionPosition
            optionNode = textNode
            optionNode?.categoryBitMask = NodeCategories.dartboardOption.rawValue
            
            node.addChildNode(optionNode!)
            displayedOption = option
        }
        func clearOptions() {
            guard optionNode != nil else { return }
            
            optionNode?.removeFromParentNode()
            optionNode = nil
            displayedOption = nil
            lightNodes.forEach({$0.removeFromParentNode()})
        }
        func dartboardFocused() {
            switch gameState {
            case .inactive:
                displayOption(.newGame)
            default:
                break
            }
        }
        func dartboardUnfocused() {
            switch gameState {
            case .inactive:
                clearOptions()
            default:
                break
            }
        }
        func optionTapped() {
            guard optionNode != nil else { return }
            
            switch displayedOption! {
            case .newGame:
                optionNode?.removeFromParentNode()
                optionNode = nil
                displayedOption = nil
                lightNodes.forEach({ $0.removeFromParentNode() })
                gameState = .pickingDart
            default:
                break
            }
        }
        
        // MARK: - Managing internal nodes
        
        func removeDarts(type: Dart.Variant) {
            switch type {
            case .left:
                guard !dart2NodesHidden else { break }
                let fadeAction = SCNAction.fadeOut(duration: 0.3)
                dart2Nodes.forEach { $0.runAction(fadeAction) }
                dart2NodesHidden = true
            case .right:
                guard !dart1NodesHidden else { break }
                let fadeAction = SCNAction.fadeOut(duration: 0.3)
                dart1Nodes.forEach { $0.runAction(fadeAction) }
                dart1NodesHidden = true
            }
        }
        
        func fillDarts() {
            if dart1NodesHidden {
                let fadeInAction = SCNAction.fadeIn(duration: 0.3)
                dart1Nodes.forEach { $0.runAction(fadeInAction) }
                dart1NodesHidden = false
            } else if dart2NodesHidden {
                let fadeInAction = SCNAction.fadeIn(duration: 0.3)
                dart2Nodes.forEach { $0.runAction(fadeInAction) }
                dart2NodesHidden = false
            }
        }
        
        // MARK: - Helper Methods
        private func showDartIndicators() {
            //let rect = CGRect(x: 0, y: 0, width: 10, height: 20)
            let path = UIBezierPath()
            var points: [CGPoint] = []
            
            points.append(CGPoint(x: 3, y: 0))
            points.append(CGPoint(x: 7, y: 0))
            points.append(CGPoint(x: 7, y: 12))
            points.append(CGPoint(x: 10, y: 12))
            points.append(CGPoint(x: 5, y: 20))
            points.append(CGPoint(x: 0, y: 12))
            points.append(CGPoint(x: 3, y: 12))
            points.append(CGPoint(x: 3, y: 0))
            
            path.move(to: points[0])
            
            for point in points[1...7] {
                path.addLine(to: point)
            }
            path.close()
            path.addClip()
            
            let shape = SCNShape(path: path, extrusionDepth: 0.1)
            shape.firstMaterial?.diffuse.contents = UIColor(red: 219/255.0, green: 64/255.0, blue: 43/255.0, alpha: 1)
            shape.firstMaterial?.emission.contents = UIColor(red: 219/255.0, green: 64/255.0, blue: 43/255.0, alpha: 1)
            shape.firstMaterial?.lightingModel = .physicallyBased
            
            // Display right arrow
            let node = SCNNode(geometry: shape)
            
            let (min, max) = node.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y
            let dz = min.z + 0.5 * (max.z - min.z)
            
            node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            
            node.scale = SCNVector3Make(0.016, 0.016, 0.016)
            node.eulerAngles = SCNVector3Make(-(.pi / 2), 0, 0)
            node.position = dartIndicatorPosition[0]
            self.node.addChildNode(node)
            indicatorArrows.append(node)
            
            // Animate arrow
            animateArrow(node)
            
            // Display left arrow
            let leftArrow = SCNNode(geometry: shape)
            
            leftArrow.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
            leftArrow.scale = SCNVector3Make(0.016, 0.016, 0.016)
            leftArrow.eulerAngles = SCNVector3Make(-(.pi / 2), 0, 0)
            leftArrow.position = dartIndicatorPosition[1]
            self.node.addChildNode(leftArrow)
            indicatorArrows.append(leftArrow)
            
            // animate arrow
            animateArrow(leftArrow)
        }
        private func animateArrow(_ arrow: SCNNode) {
            let upAction = SCNAction.move(by: SCNVector3Make(0, 0, 0.07), duration: 0.6)
            let downAction = upAction.reversed()
            let sequence = SCNAction.sequence([upAction, downAction])
            arrow.runAction(SCNAction.repeatForever(sequence))
        }
        private func removeIndicatorArrows() {
            indicatorArrows.forEach {
                $0.removeAllActions()
                $0.removeFromParentNode()
            }
            indicatorArrows = []
        }
        func enableDartPlanePhysics() { /*
            let planeGeometry = SCNPlane(width: 0.604, height: 0.604)
            planeGeometry.cornerRadius = planeGeometry.width / 2
            let planeShape = SCNPhysicsShape(geometry: planeGeometry, options: nil)
            
            let (min, max) = dartPlane.boundingBox
            let x = min.x + 0.5 * (max.x - min.x)
            let y = min.y + 0.5 * (max.y - min.y)
            let z = min.z + 0.5 * (max.z - min.z)
            
            let planeCenter = SCNVector3Make(x, y, z) // Relative to dartPlane pivot
            let tempNode = SCNNode(geometry: planeGeometry)
            tempNode.eulerAngles = SCNVector3Make(.pi / 2, 0, 0)
            tempNode.simdPosition = float3(planeCenter.x, planeCenter.y, planeCenter.z)
            
            let transform = tempNode.transform
            
            let transformValue = NSValue.init(scnMatrix4: transform)
            let finalShape = SCNPhysicsShape(shapes: [planeShape], transforms: [transformValue])
            let physicsBody = SCNPhysicsBody(type: .static, shape: finalShape)
            physicsBody.categoryBitMask = BodyType.portal.rawValue
            physicsBody.contactTestBitMask = BodyType.portal.rawValue
 
            dartPlane.presentation.physicsBody = physicsBody */
            
            let options: [SCNPhysicsShape.Option: Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
            let physicsShape = SCNPhysicsShape(node: dartPlane, options: options)
            dartPlane.presentation.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        }
        
        // MARK: - Dart Game methods
        func equipDart(variant: Dart.Variant) {
            self.equippedDart = Dart(type: variant)!
            self.equippedDart?.renderingOrder = 200
        }
        func setReticle(_ reticle: DartReticleView) {
            self.reticle = reticle
        }
        func equippedDartThrown() {
            dartsCount -= 1
            if dartsCount > 0 {
                gameDelegate?.dartGame(self, equippedNewDart: self.equippedDart!.variant)
            } else {
                gameState = .inactive
                gameDelegate?.dartGameDidEnd(self)
            }
        }
        func playHitSound() {
            audioSource.load()
            let audioPlayer = SCNAudioPlayer.init(source: audioSource)
            dartPlane.addAudioPlayer(audioPlayer)
        }
    }
}
