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
    var currentAngle: Float = 0.0
    
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
        var newAngle = Float(translation.x*(.pi)/180.0)
        newAngle += currentAngle
        
        geometryNode.transform = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
        
        if(sender.state == UIGestureRecognizer.State.ended) {
            currentAngle = newAngle
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
    
//    func setMolecule() -> Molecule {
//        let molecule = Molecule()
//
//        let hydrogen = Atom(number: 1, radius: 1.2 / 2.0, color: .lightGray )
//        let carbon = Atom(number: 6, radius: 1.7 / 2.0, color: .darkGray )
//        let oxygen = Atom(number: 8, radius: 1.52 / 2.0, color: .red )
//
//        molecule.atoms = [oxygen, oxygen, oxygen, oxygen, carbon, carbon, carbon, carbon, carbon, carbon, carbon, carbon, carbon, hydrogen, hydrogen, hydrogen, hydrogen, hydrogen, hydrogen, hydrogen, hydrogen]
//        molecule.x = [1.2333, -0.6952, 0.7958, 1.7813, -0.0857, -0.7927, -0.7288, -2.1426, -2.0787, -2.7855, -0.1409, 2.1094, 3.5305, -0.1851, -2.7247, -2.5797, -3.8374, 3.729, 4.2045, 3.7105, -0.2555]
//        molecule.y = [0.554, -2.7148, -2.1843, 0.8105, 0.6088, -0.5515, 1.8464, -0.4741, 1.9238, 0.7636, -1.8536, 0.6715, 0.5996, 2.7545, -1.3605, 2.8872, 0.8238, 1.4184, 0.6969, -0.3659, -3.5916]
//        molecule.z = [0.7792, -0.7502, 0.8685, -1.4821, 0.4403, 0.1244, 0.4133, -0.2184, 0.0706, -0.2453, 0.1477, -0.3113, 0.1635, 0.6593, -0.4564, 0.0506, -0.509, 0.8593, -0.6924, 0.6426, -0.7337]
//
//        return molecule
//    }
    
    func createSCNNode(for conformer: Conformer) -> SCNNode {
        let atomsNode = SCNNode()
        
        for atom in conformer.atoms {
            let atomNode = SCNNode(geometry: createSCNNode(for: atom))
            atomNode.position = SCNVector3Make(Float(atom.location[0]), Float(atom.location[1]), Float(atom.location[2]))
            atomsNode.addChildNode(atomNode)
        }
  
        return atomsNode
    }
    
//    func createSCNNode(for molecule: Molecule) -> SCNNode {
//        let atomsNode = SCNNode()
//
//        for index in 0..<molecule.atoms.count {
//            let atomNode = SCNNode(geometry: createSCNNode(for: molecule.atoms[index]))
//            atomNode.position = SCNVector3Make(Float(molecule.x[index]), Float(molecule.y[index]), Float(molecule.z[index]))
//            atomsNode.addChildNode(atomNode)
//        }
//
//        return atomsNode
//    }
    
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
    
//    class Molecule {
//        var atoms: [Atom]
//        var x: [Double]
//        var y: [Double]
//        var z: [Double]
//
//
//        init() {
//            self.atoms = [Atom]()
//            self.x = [Double]()
//            self.y = [Double]()
//            self.z = [Double]()
//        }
//
//    }
    
//    class Atom {
//        let number: Int
//        let radius: Double
//        let color: UIColor
//
//        init() {
//            self.number = 0
//            self.radius = 0.0
//            self.color = .black
//        }
//
//        init(number: Int) {
//            self.number = number
//            self.radius = 0.0
//            self.color = .black
//        }
//
//        init(number: Int, radius: Double, color: UIColor) {
//            self.number = number
//            self.radius = radius
//            self.color = color
//        }
//    }
}

