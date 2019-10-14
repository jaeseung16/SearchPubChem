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

    @IBOutlet weak var confomerSCNView: SCNView!
    
    var conformer: Conformer!
    var geometryNode: SCNNode!
    var rotation: SCNMatrix4 = SCNMatrix4Identity
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        confomerSCNView.backgroundColor = .lightGray
        confomerSCNView.scene = sceneSetup()
        
        geometryNode = createSCNNode(for: conformer)
        print("\(String(describing: geometryNode))")
        confomerSCNView.scene?.rootNode.addChildNode(geometryNode)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        confomerSCNView.addGestureRecognizer(panRecognizer)
        
        view.addSubview(confomerSCNView)
    }
    

    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @objc func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)
        
        var rotationAxis = [CGFloat]()
        rotationAxis.append(translation.y)
        rotationAxis.append(translation.x)
        
        let length = sqrt( translation.x * translation.x + translation.y * translation.y )
        let newAngle = Float(length) * .pi / 180.0
        
        let newRotationMake = SCNMatrix4MakeRotation(newAngle, Float(rotationAxis[0]), Float(rotationAxis[1]), 0)
        
        let newRotation = SCNMatrix4Mult(self.rotation, SCNMatrix4Mult(newRotationMake, SCNMatrix4Invert(self.rotation)))
        
        geometryNode.transform = SCNMatrix4Mult(newRotation, self.rotation)
        
        if(sender.state == UIGestureRecognizer.State.ended) {
            self.rotation = SCNMatrix4Mult(newRotation, self.rotation)
        }
    }
    
}

extension ConformerViewController {
    func sceneSetup() -> SCNScene {
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
    
    func createSCNNode(for conformer: Conformer) -> SCNNode {
        let atomsNode = SCNNode()
        
        for atom in conformer.atoms {
            let atomNode = SCNNode(geometry: createSCNNode(for: atom))
            atomNode.position = SCNVector3Make(Float(atom.location[0]), Float(atom.location[1]), Float(atom.location[2]))
            atomsNode.addChildNode(atomNode)
        }
  
        return atomsNode
    }
    
    func createSCNNode(for atom: Atom) -> SCNGeometry {
        guard let element = Elements(rawValue: atom.number) else {
            print("No such element: atomic number = \(atom.number)")
            return SCNGeometry()
        }
        
        let atomNode = SCNSphere(radius: CGFloat(element.getRadius()) / 200.0)
        atomNode.firstMaterial?.diffuse.contents = element.getColor()
        atomNode.firstMaterial?.specular.contents = UIColor.white
        print("atomNode = \(atomNode), atom.color = \(String(describing: atomNode.firstMaterial?.diffuse.contents))")
        return atomNode
    }
}

