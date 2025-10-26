//
//  ConformerSceneHelper.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/9/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation
import SceneKit

class ConformerSceneHelper {
    static let nodeName = "geometryNode"
    
    // MARK: - Scene from Conformer
    func makeScene(_ conformer: Conformer) -> SCNScene {
        let geometryNode = createSCNNode(for: conformer)
        geometryNode.name = ConformerSceneHelper.nodeName
        
        let parentScene = sceneSetup()
        parentScene.rootNode.addChildNode(geometryNode)
        
        return parentScene
    }
    
    private func sceneSetup() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.lightGray
        scene.rootNode.addChildNode(ambientLightNode)
        scene.rootNode.addChildNode(omniLightNode)
        scene.rootNode.addChildNode(cameraNode)
        return scene
    }
    
    private func createSCNNode(for conformer: Conformer) -> SCNNode {
        let atomsNode = SCNNode()
        
        for atom in conformer.atoms {
            let atomNode = SCNNode(geometry: createSCNNode(for: atom))
            atomNode.position = SCNVector3Make(Float(atom.location[0]), Float(atom.location[1]), Float(atom.location[2]))
            atomsNode.addChildNode(atomNode)
        }
  
        return atomsNode
    }
    
    private func createSCNNode(for atom: Atom) -> SCNGeometry {
        guard let element = Elements(rawValue: atom.number) else {
            print("No such element: atomic number = \(atom.number)")
            return SCNGeometry()
        }

        let radius = element.getVanDerWaalsRadius() > 0 ? element.getVanDerWaalsRadius() : element.getCovalentRadius()
        
        let atomNode = SCNSphere(radius: CGFloat(radius) / 200.0)
        atomNode.firstMaterial?.diffuse.contents = element.getColor()
        atomNode.firstMaterial?.specular.contents = UIColor.white
        
        return atomNode
    }
    
    private var ambientLightNode: SCNNode {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        return ambientLightNode
    }
    
    private var omniLightNode: SCNNode {
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = UIColor(white: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        return omniLightNode
    }
    
    private var cameraNode: SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        return cameraNode
    }
    
    
    // MARK: - Rotate/Scale Conformer
    
    func coordinateTransform(from translation: CGSize, with reference: SCNMatrix4) -> SCNMatrix4 {
        return coordinateTransform(from: makeRotation(from: translation), with: reference)
    }
    
    private func coordinateTransform(from rotation: SCNMatrix4, with reference: SCNMatrix4) -> SCNMatrix4 {
        let inverseOfReference = SCNMatrix4Invert(reference)
        let transformed = SCNMatrix4Mult(reference, SCNMatrix4Mult(rotation, inverseOfReference))
        return transformed
    }
    
    private func makeRotation(from translation: CGSize) -> SCNMatrix4 {
        let length = sqrt( translation.width * translation.width + translation.height * translation.height )
        let angle = Float(length) * .pi / 180.0
        let rotationAxis = [CGFloat](arrayLiteral: translation.height / length, translation.width / length)
        let rotation = SCNMatrix4MakeRotation(angle, Float(rotationAxis[0]), Float(rotationAxis[1]), 0)
        return rotation
    }
    
    func coordinateTransform(from scale: Float) -> SCNMatrix4 {
        let scale = Float(scale)
        return SCNMatrix4MakeScale(scale, scale, scale)
    }
}
