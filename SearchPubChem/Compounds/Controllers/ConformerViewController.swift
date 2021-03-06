//
//  ConformerViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/27/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import UIKit
import SceneKit

class ConformerViewController: UIViewController {

    @IBOutlet weak var conformerSCNView: SCNView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    
    var conformer: Conformer!
    private var geometryNode: SCNNode!
    private var rotation: SCNMatrix4 = SCNMatrix4Identity
    var name: String!
    var formula: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupGeometryNode()
        setupConformerSCNView()
        view.addSubview(conformerSCNView)
        
        nameLabel.text = name
        view.addSubview(nameLabel)
        
        formulaLabel.text = formula
        view.addSubview(formulaLabel)
    }
    
    private func setupGeometryNode() {
        geometryNode = createSCNNode(for: conformer)
    }
    
    private func setupConformerSCNView() {
        conformerSCNView.backgroundColor = .lightGray
        conformerSCNView.scene = sceneSetup()
        conformerSCNView.scene?.rootNode.addChildNode(geometryNode)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        conformerSCNView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(sender:)))
        conformerSCNView.addGestureRecognizer(pinchRecognizer)
    }

    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)
        let newRotation = coordinateTransform(for: makeRotation(from: translation), with: self.rotation)
        geometryNode.transform = SCNMatrix4Mult(newRotation, self.rotation)
        
        if (sender.state == UIGestureRecognizer.State.ended) {
            self.rotation = SCNMatrix4Mult(newRotation, self.rotation)
        }
    }
    
    @objc func pinchGesture(sender: UIPinchGestureRecognizer) {
        let scale = Float(sender.scale)
        let newScale = SCNMatrix4MakeScale(scale, scale, scale)
        geometryNode.transform = SCNMatrix4Mult(newScale, self.rotation)
        
        if (sender.state == UIGestureRecognizer.State.ended) {
            self.rotation = SCNMatrix4Mult(newScale, self.rotation)
        }
    }
    
    private func makeRotation(from translation: CGPoint) -> SCNMatrix4 {
        let length = sqrt( translation.x * translation.x + translation.y * translation.y )
        let angle = Float(length) * .pi / 180.0
        let rotationAxis = [CGFloat](arrayLiteral: translation.y / length, translation.x / length)
        let rotation = SCNMatrix4MakeRotation(angle, Float(rotationAxis[0]), Float(rotationAxis[1]), 0)
        return rotation
    }
    
    private func coordinateTransform(for rotation: SCNMatrix4, with reference: SCNMatrix4) -> SCNMatrix4 {
        let inverseOfReference = SCNMatrix4Invert(reference)
        let transformed = SCNMatrix4Mult(reference, SCNMatrix4Mult(rotation, inverseOfReference))
        return transformed
    }
    
}

extension ConformerViewController {
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
}

