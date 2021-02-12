//
//  ConformerScene.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import SceneKit

class GeometryGenerator: ObservableObject {
    static func generate(from conformer: Conformer) -> SCNNode {
        return createSCNNode(conformer: conformer)
    }
    
    private static func createSCNNode(conformer: Conformer) -> SCNNode {
        let geometryNode = SCNNode()
        
        for atom in conformer.atoms {
            let atomNode = SCNNode(geometry: createSCNNode(for: atom))
            atomNode.position = SCNVector3Make(CGFloat(Float(atom.location[0])), CGFloat(atom.location[1]), CGFloat(atom.location[2]))
            geometryNode.addChildNode(atomNode)
        }
        
        return geometryNode
    }
    
    private static func createSCNNode(for atom: Atom) -> SCNGeometry {
        guard let element = Elements(rawValue: atom.number) else {
            print("No such element: atomic number = \(atom.number)")
            return SCNGeometry()
        }

        let radius = element.getVanDerWaalsRadius() > 0 ? element.getVanDerWaalsRadius() : element.getCovalentRadius()
        
        let atomNode = SCNSphere(radius: CGFloat(radius) / 200.0)
        atomNode.firstMaterial?.diffuse.contents = element.getColor()
        atomNode.firstMaterial?.specular.contents = NSColor.white
        
        return atomNode
    }
}
