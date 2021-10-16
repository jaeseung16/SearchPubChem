//
//  SceneKitView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/16/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    var conformer: Conformer
    var size: CGSize

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: self.size))
        setup(scnView)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if let geometryNode =  uiView.scene?.rootNode.childNode(withName: "geometryNode", recursively: false) {
            geometryNode.transform = SCNMatrix4Mult(viewModel.rotation, SCNMatrix4Identity)
        }
    }
    
    private func setup(_ scnView: SCNView) {
        let geometryNode = createSCNNode(for: self.conformer)
        geometryNode.name = "geometryNode"
        
        scnView.backgroundColor = .lightGray
        scnView.scene = sceneSetup()
        scnView.scene?.rootNode.addChildNode(geometryNode)
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
    
    
    private func sceneSetup() -> SCNScene {
        let scene = SCNScene()
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = UIColor(white: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        scene.rootNode.addChildNode(cameraNode)
      
        return scene
    }
    
}
